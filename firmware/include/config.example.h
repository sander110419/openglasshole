#pragma once

#include <Arduino.h>

// Copy this file to config.h. That file is gitignored so Wi-Fi credentials do
// not end up in commits. The example remains buildable for CI, but it cannot
// connect until these values are changed.
namespace ogh_config {

constexpr char WIFI_SSID[] = "CHANGE_ME";
constexpr char WIFI_PASSWORD[] = "CHANGE_ME";

// Use the computer's LAN address, not localhost. The bundled server endpoint
// is intentionally plain HTTP for a trusted home/stage LAN.
constexpr char CUE_URL[] = "http://192.168.1.50:8787/api/v1/cue.txt";
constexpr char DEVICE_ID[] = "default";

// Optional bearer value for an HTTPS reverse proxy. The bundled LAN server's
// display GET endpoint does not require one. Never commit a real value here.
constexpr char BEARER_TOKEN[] = "";

// For HTTPS, paste the PEM root CA certificate here. An HTTPS request is
// rejected when this is empty. The pinned core checks chain/hostname but not
// certificate dates; see firmware/README.md before using a remote endpoint.
constexpr char TLS_ROOT_CA[] = R"PEM()PEM";

constexpr uint8_t OLED_I2C_ADDRESS = 0x3C;
constexpr uint8_t OLED_CONTRAST = 0x60;  // Lower is dimmer and usually saves power.
constexpr uint8_t TEXT_SIZE = 1;         // 5x7 glyphs; size 1 gives 8 columns x 4 rows.
// Only the central 48 columns are used. This deliberately sacrifices two
// characters per row for a materially larger first-order eye box.
constexpr uint8_t OLED_VIEWPORT_WIDTH_PX = 48;

// One combiner reflection normally reverses text horizontally. Flip these if
// your physical OLED/combiner orientation differs.
constexpr bool MIRROR_X = true;
constexpr bool MIRROR_Y = false;

constexpr uint32_t DEFAULT_POLL_SECONDS = 15;
constexpr uint32_t DEFAULT_SCROLL_MS = 65;
constexpr uint32_t WIFI_CONNECT_TIMEOUT_MS = 8000;

// Set true to download once at boot, then leave Wi-Fi off until a long button
// press. This gives the lowest-power playback for a complete prepared cue.
constexpr bool FETCH_ON_BOOT_ONLY = false;

// true saves substantial power by associating only for each conditional GET.
// The vertical cue keeps rendering while the radio connects. Set false for the
// lowest update latency; ESP32 maximum modem power-save is then enabled.
constexpr bool RADIO_OFF_BETWEEN_POLLS = true;

}  // namespace ogh_config
