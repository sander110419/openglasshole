# Cue API

The bundled server has no third-party dependencies. It serves a browser editor,
one tiny text response for the glasses, and a JSON update endpoint.

## Run it

From the repository root:

```sh
export OPEN_OCCUCUE_API_KEY='choose-a-long-random-update-key'
python3 server/cue_server.py --host 0.0.0.0 --port 8787
```

Open `http://<computer-lan-ip>:8787/` on a phone or laptop. Do not expose this
development server directly to the public internet. Binding `0.0.0.0` makes it
reachable on local interfaces; use a trusted LAN and firewall.

## Display read

```http
GET /api/v1/cue.txt?device=default HTTP/1.1
If-None-Match: "1-0d9f..."
```

A changed cue returns raw UTF-8 text, including normalized line breaks. The
server preserves Unicode for future display fonts, but the v0.1 firmware's 5×7
font renders printable ASCII only and replaces each non-ASCII code point with
`?`. The reference firmware word-wraps to 8 columns × 4 visible rows:

```http
HTTP/1.1 200 OK
Content-Type: text/plain; charset=utf-8
ETag: "2-79e4..."
Cache-Control: no-cache
X-Poll-Seconds: 15
X-Scroll-Ms: 65

Welcome to
the next section
```

An unchanged cue returns `304 Not Modified` with no body. This minimizes radio
airtime and allocation on the ESP32. `GET /api/v1/cue?device=default` returns
the same state as JSON for tools.

Unknown device names fall back to the `default` cue. Once a device-specific cue
is written, it has independent state. Names are limited to 1–64 ASCII letters,
digits, dots, dashes, or underscores.

## Update

Raw text:

```sh
curl --request PUT \
  --header 'X-API-Key: choose-a-long-random-update-key' \
  --header 'Content-Type: text/plain; charset=utf-8' \
  --data-binary 'Camera two. Slow down.' \
  'http://127.0.0.1:8787/api/v1/cue?device=default'
```

JSON can also update timing:

```json
{
  "text": "Camera two.\n\nSlow down.",
  "poll_seconds": 15,
  "scroll_ms": 65
}
```

Limits are 512 normalized cue characters, 2–3600 seconds between polls, 25–500
milliseconds per vertical scroll pixel, and 4096 request bytes. Within each
line, whitespace is collapsed and trimmed; explicit line breaks are retained,
while repeated blank lines collapse to one paragraph gap. The firmware wraps at
spaces, splits words longer than 8 columns, holds the first view for 1.2
seconds, holds the last view for 1.8 seconds, and then loops. Four wrapped rows
or fewer are centered without scrolling. Cue state is atomically persisted to
`server/data/cues.json` by default.

## Security model

- `OPEN_OCCUCUE_API_KEY` protects writes, not reads. The legacy
  `OPENGLASSHOLE_API_KEY` spelling remains a deprecated fallback. An autocue is
  normally on a private stage/home LAN and keeping display reads simple saves
  configuration.
- Without the environment variable, writes are unauthenticated and the editor
  shows a warning.
- Do not publish this server directly. If remote control is unavoidable, put it
  behind a maintained HTTPS reverse proxy or private VPN and authenticate reads
  as well as writes. The pinned firmware checks CA chain and hostname but not
  certificate validity dates, so treat its HTTPS support as defense in depth,
  not as a hardened public-internet client.
- Wi-Fi credentials, tokens, and private certificates belong in
  `firmware/include/config.h`, which is gitignored.

## Other endpoints

| Endpoint | Purpose |
| --- | --- |
| `GET /` | Same-origin cue editor |
| `GET /healthz` | `{"status":"ok"}` liveness check |
| `GET /api/v1/cue` | JSON cue state |
| `GET /api/v1/cue.txt` | Minimal firmware response |
| `PUT /api/v1/cue` | Authenticated cue update |
