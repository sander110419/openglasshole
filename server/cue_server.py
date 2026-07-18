#!/usr/bin/env python3
"""Dependency-free HTTP cue server for Open OccuCue.

The display consumes the small ``/api/v1/cue.txt`` response. A deliberately
simple browser form and JSON API are included so a laptop or Raspberry Pi can
act as the autocue controller without a separate application.
"""

from __future__ import annotations

import argparse
from collections.abc import Mapping
import dataclasses
import datetime as dt
import hashlib
import hmac
import html
import json
import os
from pathlib import Path
import re
import tempfile
import threading
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any
from urllib.parse import parse_qs, quote, urlsplit


MAX_BODY_BYTES = 4096
MAX_CUE_CHARS = 512
DEVICE_RE = re.compile(r"^[A-Za-z0-9_.-]{1,64}$")


def resolve_api_key(environ: Mapping[str, str]) -> tuple[str, bool]:
    """Return the configured update key and whether its legacy name was used."""
    api_key = environ.get("OPEN_OCCUCUE_API_KEY", "")
    if api_key:
        return api_key, False
    legacy_api_key = environ.get("OPENGLASSHOLE_API_KEY", "")
    return legacy_api_key, bool(legacy_api_key)


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")


def normalize_text(value: Any) -> str:
    if not isinstance(value, str):
        raise ValueError("text must be a string")
    # Preserve explicit line/paragraph breaks for the vertical autocue while
    # keeping every line deterministic and free of leading/trailing whitespace.
    normalized_lines: list[str] = []
    previous_was_blank = False
    for source_line in value.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        line = " ".join(source_line.split())
        if not line:
            if normalized_lines and not previous_was_blank:
                normalized_lines.append("")
            previous_was_blank = True
            continue
        normalized_lines.append(line)
        previous_was_blank = False
    while normalized_lines and not normalized_lines[-1]:
        normalized_lines.pop()
    normalized = "\n".join(normalized_lines)
    if len(normalized) > MAX_CUE_CHARS:
        raise ValueError(f"text must be at most {MAX_CUE_CHARS} characters")
    return normalized


def parse_bounded_int(value: Any, name: str, minimum: int, maximum: int) -> int:
    if isinstance(value, (bool, float)):
        raise ValueError(f"{name} must be an integer")
    try:
        parsed = int(value)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"{name} must be an integer") from exc
    if not minimum <= parsed <= maximum:
        raise ValueError(f"{name} must be between {minimum} and {maximum}")
    return parsed


def validate_device(value: str) -> str:
    if not DEVICE_RE.fullmatch(value):
        raise ValueError("device must be 1-64 letters, digits, dots, dashes, or underscores")
    return value


@dataclasses.dataclass(frozen=True, slots=True)
class Cue:
    text: str
    version: int
    updated_at: str
    poll_seconds: int = 15
    scroll_ms: int = 65

    @classmethod
    def from_dict(cls, value: Any) -> "Cue":
        if not isinstance(value, dict):
            raise ValueError("cue must be an object")
        return cls(
            text=normalize_text(value.get("text", "")),
            version=max(1, parse_bounded_int(value.get("version", 1), "version", 1, 2**31 - 1)),
            updated_at=str(value.get("updated_at", utc_now())),
            poll_seconds=parse_bounded_int(value.get("poll_seconds", 15), "poll_seconds", 2, 3600),
            scroll_ms=parse_bounded_int(value.get("scroll_ms", 65), "scroll_ms", 25, 500),
        )

    def as_dict(self) -> dict[str, Any]:
        return dataclasses.asdict(self)


class CueStore:
    """Thread-safe, atomically persisted per-device cue state."""

    def __init__(self, path: Path | None, initial_text: str = "Open OccuCue ready") -> None:
        self.path = path
        self._lock = threading.RLock()
        self._devices: dict[str, Cue] = {
            "default": Cue(normalize_text(initial_text), 1, utc_now())
        }
        self._load()

    def _load(self) -> None:
        if self.path is None or not self.path.exists():
            return
        try:
            payload = json.loads(self.path.read_text(encoding="utf-8"))
            if not isinstance(payload, dict):
                raise ValueError("root must be an object")
            devices = payload.get("devices", {})
            if not isinstance(devices, dict):
                raise ValueError("devices must be an object")
            loaded = {
                validate_device(str(device)): Cue.from_dict(cue)
                for device, cue in devices.items()
            }
            if loaded:
                if "default" not in loaded:
                    raise ValueError("devices must include a default cue")
                self._devices = loaded
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            raise RuntimeError(f"could not load cue data from {self.path}: {exc}") from exc

    def _save(self, devices: dict[str, Cue]) -> None:
        if self.path is None:
            return
        self.path.parent.mkdir(parents=True, exist_ok=True)
        payload = {
            "schema": 1,
            "devices": {name: cue.as_dict() for name, cue in sorted(devices.items())},
        }
        serialized = json.dumps(payload, ensure_ascii=False, indent=2) + "\n"
        fd, temporary = tempfile.mkstemp(prefix=f".{self.path.name}.", dir=self.path.parent)
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as output:
                output.write(serialized)
                output.flush()
                os.fsync(output.fileno())
            os.replace(temporary, self.path)
        finally:
            try:
                os.unlink(temporary)
            except FileNotFoundError:
                pass

    def get(self, device: str) -> Cue:
        validate_device(device)
        with self._lock:
            return self._devices.get(device, self._devices["default"])

    def update(
        self,
        device: str,
        text: str,
        poll_seconds: int | None = None,
        scroll_ms: int | None = None,
    ) -> Cue:
        validate_device(device)
        normalized = normalize_text(text)
        with self._lock:
            previous = self._devices.get(device, self._devices["default"])
            next_poll = previous.poll_seconds if poll_seconds is None else parse_bounded_int(
                poll_seconds, "poll_seconds", 2, 3600
            )
            next_scroll = previous.scroll_ms if scroll_ms is None else parse_bounded_int(
                scroll_ms, "scroll_ms", 25, 500
            )
            if (
                normalized == previous.text
                and next_poll == previous.poll_seconds
                and next_scroll == previous.scroll_ms
                and device in self._devices
            ):
                return previous
            cue = Cue(normalized, previous.version + 1, utc_now(), next_poll, next_scroll)
            updated_devices = dict(self._devices)
            updated_devices[device] = cue
            # Persist before publishing the new in-memory state. A disk error
            # therefore cannot make clients observe an update that disappears
            # after restart.
            self._save(updated_devices)
            self._devices = updated_devices
            return cue


def make_etag(device: str, cue: Cue) -> str:
    digest = hashlib.sha256(f"{device}\0{cue.version}\0{cue.text}".encode()).hexdigest()[:12]
    return f'"{cue.version}-{digest}"'


def create_server(
    address: tuple[str, int], store: CueStore, api_key: str = ""
) -> ThreadingHTTPServer:
    class CueRequestHandler(BaseHTTPRequestHandler):
        server_version = "OpenOccuCue/1"

        def log_message(self, fmt: str, *args: Any) -> None:
            # BaseHTTPRequestHandler logs the path but never request bodies/API keys.
            super().log_message(fmt, *args)

        def _send_bytes(
            self,
            status: HTTPStatus,
            body: bytes = b"",
            content_type: str = "text/plain; charset=utf-8",
            headers: dict[str, str] | None = None,
        ) -> None:
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("X-Content-Type-Options", "nosniff")
            self.send_header("Referrer-Policy", "no-referrer")
            if headers:
                for name, value in headers.items():
                    self.send_header(name, value)
            self.end_headers()
            if self.command != "HEAD" and body:
                self.wfile.write(body)

        def _send_json(self, status: HTTPStatus, value: Any) -> None:
            body = (json.dumps(value, ensure_ascii=False, separators=(",", ":")) + "\n").encode()
            self._send_bytes(status, body, "application/json; charset=utf-8")

        def _route(self) -> tuple[str, dict[str, list[str]]]:
            parsed = urlsplit(self.path)
            return parsed.path, parse_qs(parsed.query, keep_blank_values=True)

        def _device(self, query: dict[str, list[str]]) -> str:
            return validate_device(query.get("device", ["default"])[0])

        def _authorized(self, supplied: str = "") -> bool:
            if not api_key:
                return True
            candidate = supplied or self.headers.get("X-API-Key", "")
            return hmac.compare_digest(candidate.encode(), api_key.encode())

        def _read_body(self) -> bytes:
            raw_length = self.headers.get("Content-Length", "0")
            try:
                length = int(raw_length)
            except ValueError as exc:
                raise ValueError("invalid Content-Length") from exc
            if length < 0 or length > MAX_BODY_BYTES:
                raise OverflowError(f"request body exceeds {MAX_BODY_BYTES} bytes")
            return self.rfile.read(length)

        def _cue_headers(self, device: str, cue: Cue) -> dict[str, str]:
            return {
                "Cache-Control": "no-cache",
                "ETag": make_etag(device, cue),
                "X-Cue-Version": str(cue.version),
                "X-Poll-Seconds": str(cue.poll_seconds),
                "X-Scroll-Ms": str(cue.scroll_ms),
            }

        def do_HEAD(self) -> None:  # noqa: N802 - stdlib callback name
            self.do_GET()

        def do_GET(self) -> None:  # noqa: N802 - stdlib callback name
            try:
                path, query = self._route()
                if path == "/healthz":
                    self._send_json(HTTPStatus.OK, {"status": "ok"})
                    return
                if path in {"/api/v1/cue", "/api/v1/cue.txt"}:
                    device = self._device(query)
                    cue = store.get(device)
                    headers = self._cue_headers(device, cue)
                    if self.headers.get("If-None-Match") == headers["ETag"]:
                        self._send_bytes(HTTPStatus.NOT_MODIFIED, headers=headers)
                        return
                    if path.endswith(".txt"):
                        self._send_bytes(HTTPStatus.OK, cue.text.encode("utf-8"), headers=headers)
                    else:
                        body = (json.dumps(cue.as_dict(), ensure_ascii=False, separators=(",", ":")) + "\n").encode()
                        self._send_bytes(
                            HTTPStatus.OK,
                            body,
                            "application/json; charset=utf-8",
                            headers,
                        )
                    return
                if path == "/":
                    device = self._device(query)
                    cue = store.get(device)
                    page = self._editor_page(device, cue).encode("utf-8")
                    self._send_bytes(
                        HTTPStatus.OK,
                        page,
                        "text/html; charset=utf-8",
                        {"Content-Security-Policy": "default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; base-uri 'none'"},
                    )
                    return
                self._send_json(HTTPStatus.NOT_FOUND, {"error": "not found"})
            except ValueError as exc:
                self._send_json(HTTPStatus.BAD_REQUEST, {"error": str(exc)})

        def do_PUT(self) -> None:  # noqa: N802 - stdlib callback name
            try:
                path, query = self._route()
                if path != "/api/v1/cue":
                    self._send_json(HTTPStatus.NOT_FOUND, {"error": "not found"})
                    return
                if not self._authorized():
                    self._send_json(HTTPStatus.UNAUTHORIZED, {"error": "invalid API key"})
                    return
                device = self._device(query)
                raw = self._read_body()
                if "application/json" in self.headers.get("Content-Type", ""):
                    value = json.loads(raw.decode("utf-8"))
                    if not isinstance(value, dict):
                        raise ValueError("JSON body must be an object")
                    text = value.get("text")
                    poll_seconds = value.get("poll_seconds")
                    scroll_ms = value.get("scroll_ms")
                else:
                    text = raw.decode("utf-8")
                    poll_seconds = None
                    scroll_ms = None
                cue = store.update(device, text, poll_seconds, scroll_ms)
                self._send_json(HTTPStatus.OK, cue.as_dict())
            except OverflowError as exc:
                self._send_json(HTTPStatus.REQUEST_ENTITY_TOO_LARGE, {"error": str(exc)})
            except OSError:
                self._send_json(
                    HTTPStatus.INTERNAL_SERVER_ERROR,
                    {"error": "could not persist cue"},
                )
            except (UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
                self._send_json(HTTPStatus.BAD_REQUEST, {"error": str(exc)})

        def do_POST(self) -> None:  # noqa: N802 - stdlib callback name
            try:
                path, _query = self._route()
                if path != "/":
                    self._send_json(HTTPStatus.NOT_FOUND, {"error": "not found"})
                    return
                form = parse_qs(self._read_body().decode("utf-8"), keep_blank_values=True)
                if not self._authorized(form.get("api_key", [""])[0]):
                    self._send_json(HTTPStatus.UNAUTHORIZED, {"error": "invalid API key"})
                    return
                device = validate_device(form.get("device", ["default"])[0])
                store.update(
                    device,
                    form.get("text", [""])[0],
                    parse_bounded_int(form.get("poll_seconds", ["15"])[0], "poll_seconds", 2, 3600),
                    parse_bounded_int(form.get("scroll_ms", ["65"])[0], "scroll_ms", 25, 500),
                )
                self.send_response(HTTPStatus.SEE_OTHER)
                self.send_header("Location", f"/?device={quote(device)}&saved=1")
                self.send_header("Content-Length", "0")
                self.end_headers()
            except OverflowError as exc:
                self._send_json(HTTPStatus.REQUEST_ENTITY_TOO_LARGE, {"error": str(exc)})
            except OSError:
                self._send_json(
                    HTTPStatus.INTERNAL_SERVER_ERROR,
                    {"error": "could not persist cue"},
                )
            except (UnicodeDecodeError, ValueError) as exc:
                self._send_json(HTTPStatus.BAD_REQUEST, {"error": str(exc)})

        def _editor_page(self, device: str, cue: Cue) -> str:
            key_field = (
                '<label>API key <input type="password" name="api_key" autocomplete="current-password" required></label>'
                if api_key
                else '<p class="warning">No update key is configured. Anyone who can reach this server can change the cue.</p>'
            )
            return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Open OccuCue cue</title><style>
:root{{color-scheme:dark;background:#101418;color:#edf7f6;font:18px system-ui,sans-serif}}body{{max-width:48rem;margin:3rem auto;padding:0 1rem}}form{{display:grid;gap:1rem}}label{{display:grid;gap:.35rem}}textarea,input{{box-sizing:border-box;width:100%;padding:.7rem;border:1px solid #557;border-radius:.4rem;background:#171d24;color:inherit;font:inherit}}textarea{{min-height:9rem}}.row{{display:grid;grid-template-columns:1fr 1fr;gap:1rem}}button{{padding:.8rem;border:0;border-radius:.4rem;background:#43d7b0;color:#06120f;font-weight:700;font-size:1rem}}small{{color:#a9bac5}}.warning{{color:#ffd479}}code{{color:#8debd2}}@media(max-width:36rem){{.row{{grid-template-columns:1fr}}}}</style></head>
<body><h1>Open OccuCue cue</h1><form method="post" action="/">
<label>Device <input name="device" value="{html.escape(device)}" pattern="[A-Za-z0-9_.-]{{1,64}}" required></label>
<label>Cue text <textarea name="text" maxlength="{MAX_CUE_CHARS}" autofocus>{html.escape(cue.text)}</textarea></label>
<div class="row"><label>Poll every (seconds)<input type="number" name="poll_seconds" min="2" max="3600" value="{cue.poll_seconds}"></label>
<label>Vertical pixel (ms)<input type="number" name="scroll_ms" min="25" max="500" value="{cue.scroll_ms}"></label></div>
{key_field}<button type="submit">Send cue</button></form>
<p><small>Version {cue.version}, updated {html.escape(cue.updated_at)}. Display endpoint: <code>/api/v1/cue.txt?device={html.escape(device)}</code></small></p></body></html>"""

    return ThreadingHTTPServer(address, CueRequestHandler)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1", help="listen address (use 0.0.0.0 on a trusted LAN)")
    parser.add_argument("--port", type=int, default=8787)
    parser.add_argument("--data-file", type=Path, default=Path("server/data/cues.json"))
    parser.add_argument("--initial-text", default="Open OccuCue ready")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    api_key, using_legacy_key = resolve_api_key(os.environ)
    store = CueStore(args.data_file, args.initial_text)
    server = create_server((args.host, args.port), store, api_key)
    host, port = server.server_address[:2]
    print(f"Open OccuCue cue server: http://{host}:{port}/", flush=True)
    if not api_key:
        print("WARNING: OPEN_OCCUCUE_API_KEY is unset; cue updates are unauthenticated.", flush=True)
    elif using_legacy_key:
        print(
            "WARNING: OPENGLASSHOLE_API_KEY is deprecated; use OPEN_OCCUCUE_API_KEY.",
            flush=True,
        )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
