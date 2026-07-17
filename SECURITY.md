# Security policy

The bundled server is a small development/LAN service, not a hardened public
hosting stack. Its API key protects updates only; cue reads are intentionally
unauthenticated. Do not expose it directly to the internet.

Report a vulnerability privately through this repository's GitHub security
advisory feature. Do not include real Wi-Fi credentials, API keys, private
certificates, or personal cue content in an issue, test, screenshot, or log.

For remote deployment, prefer a private VPN; otherwise use a maintained HTTPS
reverse proxy, authenticate reads and writes, and firewall the origin. The
firmware refuses HTTPS without a root CA and checks chain/hostname, but its
pinned Arduino-ESP32 build does not validate certificate dates. Do not treat it
as a hardened public-internet client.
