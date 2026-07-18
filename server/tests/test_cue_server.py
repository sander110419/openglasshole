from __future__ import annotations

import http.client
import json
from pathlib import Path
import tempfile
import threading
import unittest

from server.cue_server import CueStore, create_server, resolve_api_key


class RunningServer:
    def __init__(self, store: CueStore, api_key: str = "") -> None:
        self.server = create_server(("127.0.0.1", 0), store, api_key)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)

    def __enter__(self) -> "RunningServer":
        self.thread.start()
        return self

    def __exit__(self, *_args: object) -> None:
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=2)

    def request(
        self, method: str, path: str, body: bytes | None = None, headers: dict[str, str] | None = None
    ) -> tuple[int, dict[str, str], bytes]:
        connection = http.client.HTTPConnection("127.0.0.1", self.server.server_port, timeout=2)
        connection.request(method, path, body=body, headers=headers or {})
        response = connection.getresponse()
        result = response.status, {key.lower(): value for key, value in response.getheaders()}, response.read()
        connection.close()
        return result


class CueStoreTests(unittest.TestCase):
    def test_update_persists_and_reloads(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "cues.json"
            store = CueStore(path)
            cue = store.update("stage-left", "  Next\nline  ", poll_seconds=20, scroll_ms=80)

            self.assertEqual(cue.text, "Next\nline")
            self.assertEqual(CueStore(path).get("stage-left"), cue)

    def test_text_normalization_preserves_bounded_paragraph_breaks(self) -> None:
        store = CueStore(None)
        cue = store.update("default", "  First   line\r\n\r\n\r\nSecond\tline  \n")

        self.assertEqual(cue.text, "First line\n\nSecond line")

    def test_normalized_multiline_text_limit_is_enforced(self) -> None:
        store = CueStore(None)
        exactly_512 = "a" * 255 + "\n\n" + "b" * 255

        self.assertEqual(len(store.update("default", exactly_512).text), 512)
        with self.assertRaisesRegex(ValueError, "at most 512 characters"):
            store.update("default", exactly_512 + "c")

    def test_unknown_device_falls_back_to_default(self) -> None:
        store = CueStore(None, "fallback")
        self.assertEqual(store.get("unknown").text, "fallback")

    def test_malformed_store_is_rejected_with_a_clear_error(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "cues.json"
            path.write_text("[]\n", encoding="utf-8")
            with self.assertRaisesRegex(RuntimeError, "root must be an object"):
                CueStore(path)

    def test_persisted_store_requires_default_fallback(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "cues.json"
            path.write_text(
                json.dumps(
                    {
                        "devices": {
                            "stage": {
                                "text": "Only cue",
                                "version": 1,
                                "updated_at": "2026-01-01T00:00:00+00:00",
                                "poll_seconds": 15,
                                "scroll_ms": 65,
                            }
                        }
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(RuntimeError, "include a default cue"):
                CueStore(path)

    def test_failed_persistence_does_not_publish_update(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            blocker = Path(folder) / "not-a-directory"
            blocker.write_text("blocked\n", encoding="utf-8")
            store = CueStore(blocker / "cues.json", "original")
            with self.assertRaises(OSError):
                store.update("default", "not persisted")
            self.assertEqual(store.get("default").text, "original")


class ConfigurationTests(unittest.TestCase):
    def test_new_api_key_name_takes_precedence(self) -> None:
        key, legacy = resolve_api_key(
            {
                "OPEN_OCCUCUE_API_KEY": "new-key",
                "OPENGLASSHOLE_API_KEY": "old-key",
            }
        )
        self.assertEqual((key, legacy), ("new-key", False))

    def test_legacy_api_key_name_remains_a_deprecated_fallback(self) -> None:
        key, legacy = resolve_api_key({"OPENGLASSHOLE_API_KEY": "old-key"})
        self.assertEqual((key, legacy), ("old-key", True))

    def test_missing_api_key_remains_unauthenticated(self) -> None:
        self.assertEqual(resolve_api_key({}), ("", False))


class CueServerTests(unittest.TestCase):
    def test_text_endpoint_and_conditional_get(self) -> None:
        with RunningServer(CueStore(None, "First cue\nSecond cue")) as server:
            status, headers, body = server.request("GET", "/api/v1/cue.txt?device=default")
            self.assertEqual((status, body), (200, b"First cue\nSecond cue"))
            self.assertIn("etag", headers)
            status, _, body = server.request(
                "GET", "/api/v1/cue.txt?device=default", headers={"If-None-Match": headers["etag"]}
            )
            self.assertEqual((status, body), (304, b""))

    def test_key_protects_updates(self) -> None:
        store = CueStore(None)
        payload = json.dumps({"text": "New cue", "poll_seconds": 30, "scroll_ms": 90}).encode()
        with RunningServer(store, "correct horse") as server:
            status, _, _ = server.request(
                "PUT", "/api/v1/cue?device=default", payload, {"Content-Type": "application/json"}
            )
            self.assertEqual(status, 401)
            status, _, body = server.request(
                "PUT",
                "/api/v1/cue?device=default",
                payload,
                {"Content-Type": "application/json", "X-API-Key": "correct horse"},
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body)["text"], "New cue")

    def test_invalid_device_and_large_body_are_rejected(self) -> None:
        with RunningServer(CueStore(None)) as server:
            status, _, _ = server.request("GET", "/api/v1/cue.txt?device=../bad")
            self.assertEqual(status, 400)
            status, _, _ = server.request(
                "PUT",
                "/api/v1/cue",
                b"x" * 4097,
                {"Content-Type": "text/plain", "Content-Length": "4097"},
            )
            self.assertEqual(status, 413)

    def test_fractional_timing_is_rejected_instead_of_truncated(self) -> None:
        payload = json.dumps({"text": "cue", "poll_seconds": 2.9}).encode()
        with RunningServer(CueStore(None)) as server:
            status, _, body = server.request(
                "PUT",
                "/api/v1/cue",
                payload,
                {"Content-Type": "application/json"},
            )
            self.assertEqual(status, 400)
            self.assertIn("must be an integer", json.loads(body)["error"])

    def test_editor_escapes_cue_text(self) -> None:
        store = CueStore(None)
        store.update("default", "<script>alert(1)</script>")
        with RunningServer(store) as server:
            status, _, body = server.request("GET", "/")
            self.assertEqual(status, 200)
            self.assertNotIn(b"<script>alert(1)</script>", body)
            self.assertIn(b"&lt;script&gt;", body)

    def test_persistence_failure_returns_server_error(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            blocker = Path(folder) / "not-a-directory"
            blocker.write_text("blocked\n", encoding="utf-8")
            store = CueStore(blocker / "cues.json", "original")
            with RunningServer(store) as server:
                status, _, body = server.request(
                    "PUT",
                    "/api/v1/cue?device=default",
                    b"new cue",
                    {"Content-Type": "text/plain"},
                )
                self.assertEqual(status, 500)
                self.assertEqual(json.loads(body)["error"], "could not persist cue")
                self.assertEqual(store.get("default").text, "original")


if __name__ == "__main__":
    unittest.main()
