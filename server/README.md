# Cue server

`cue_server.py` is a dependency-free Python 3.11+ threaded HTTP server with:

- a responsive browser cue editor at `/`
- minimal `GET /api/v1/cue.txt?device=...` responses with ETag/304 support
- JSON `GET` and authenticated text/JSON `PUT` endpoints
- per-device cues with fallback to `default`
- bounded inputs and atomic JSON persistence
- no API-key logging and no third-party package installation

Run on localhost for development:

```sh
OPEN_OCCUCUE_API_KEY='development-only' python3 server/cue_server.py
```

Run on a trusted LAN for the glasses:

```sh
OPEN_OCCUCUE_API_KEY='replace-with-a-long-random-key' \
  python3 server/cue_server.py --host 0.0.0.0 --port 8787
```

Test from the repository root:

```sh
python3 -m unittest discover -s server/tests -v
```

Read [the API and security model](../docs/API.md) before putting it on any
network other than a trusted LAN.
