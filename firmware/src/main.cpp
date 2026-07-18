#include <Arduino.h>
#include <HTTPClient.h>
#include <Preferences.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <Wire.h>
#include <driver/gpio.h>
#include <esp_sleep.h>
#include <esp_wifi.h>
#include <esp32-hal-cpu.h>
#include <freertos/FreeRTOS.h>
#include <freertos/queue.h>
#include <freertos/task.h>

#if __has_include("config.h")
#include "config.h"
#else
#include "config.example.h"
#define OGH_USING_EXAMPLE_CONFIG 1
#endif

#include "motion_display.h"
#include "oled49.h"

namespace {

constexpr uint8_t BUTTON_PIN = D2;  // XIAO D2 / GPIO4, active low.
constexpr uint8_t OLED_SDA_PIN = D4;  // XIAO D4 / GPIO6.
constexpr uint8_t OLED_SCL_PIN = D5;  // XIAO D5 / GPIO7.
constexpr uint32_t BUTTON_DEBOUNCE_MS = 30;
constexpr uint32_t BUTTON_FORCE_FETCH_MS = 1200;
constexpr uint32_t MAX_FAILURE_BACKOFF_MS = 60000;
constexpr uint32_t TLS_HANDSHAKE_TIMEOUT_SECONDS = 6;
constexpr size_t MAX_CUE_CHARS = 512;
constexpr size_t MAX_RESPONSE_BYTES = MAX_CUE_CHARS * 4U;
constexpr size_t MAX_ETAG_CHARS = 95;
constexpr uint32_t NETWORK_TASK_STACK_BYTES = 8192;
constexpr uint32_t SCROLL_START_HOLD_MS = 1200;
constexpr uint32_t SCROLL_END_HOLD_MS = 1800;
constexpr int16_t CHARACTER_WIDTH_PX = static_cast<int16_t>(6 * ogh_config::TEXT_SIZE);
constexpr int16_t LINE_HEIGHT_PX = static_cast<int16_t>(8 * ogh_config::TEXT_SIZE);
constexpr int16_t VIEWPORT_WIDTH_PX = ogh_config::OLED_VIEWPORT_WIDTH_PX;
constexpr int16_t VIEWPORT_X_PX = static_cast<int16_t>(
    (Oled49::WIDTH_PX - VIEWPORT_WIDTH_PX) / 2
);
constexpr size_t LINE_COLUMNS = static_cast<size_t>(VIEWPORT_WIDTH_PX / CHARACTER_WIDTH_PX);
constexpr size_t VISIBLE_ROWS = static_cast<size_t>(Oled49::HEIGHT_PX / LINE_HEIGHT_PX);
constexpr size_t MAX_WRAPPED_LINES = MAX_CUE_CHARS + 1U;

static_assert(ogh_config::TEXT_SIZE > 0, "TEXT_SIZE must be at least 1");
static_assert(VIEWPORT_WIDTH_PX > 0, "OLED viewport must be at least one pixel wide");
static_assert(VIEWPORT_WIDTH_PX <= Oled49::WIDTH_PX, "OLED viewport exceeds the panel width");
static_assert((Oled49::WIDTH_PX - VIEWPORT_WIDTH_PX) % 2 == 0,
              "OLED viewport must be centered on whole pixels");
static_assert(CHARACTER_WIDTH_PX <= VIEWPORT_WIDTH_PX,
              "TEXT_SIZE is too large for the OLED viewport");
static_assert(LINE_HEIGHT_PX <= Oled49::HEIGHT_PX, "TEXT_SIZE is too large for the OLED height");
static_assert(MAX_CUE_CHARS <= UINT16_MAX, "wrapped line offsets must fit uint16_t");
static_assert(OGH_OLED_I2C_HZ == 100000 || OGH_OLED_I2C_HZ == 400000,
              "OGH_OLED_I2C_HZ must be 100000 or 400000");
static_assert(OGH_SCROLL_MODE == 0 || OGH_SCROLL_MODE == 1,
              "OGH_SCROLL_MODE must be 0 (smooth) or 1 (line-step)");
static_assert(OGH_GLANCE_DWELL_MS > 0, "OGH_GLANCE_DWELL_MS must be positive");
static_assert(OGH_BLACKOUT_ON_PAUSE == 0 || OGH_BLACKOUT_ON_PAUSE == 1,
              "OGH_BLACKOUT_ON_PAUSE must be 0 or 1");

constexpr ogh_motion::ScrollMode SCROLL_MODE = OGH_SCROLL_MODE == 1
    ? ogh_motion::ScrollMode::LINE_STEPS
    : ogh_motion::ScrollMode::SMOOTH_PIXELS;

struct FetchResult {
    bool success;
    bool has_text;
    uint32_t poll_ms;
    uint32_t scroll_ms;
    char text[MAX_CUE_CHARS + 1];
    char etag[MAX_ETAG_CHARS + 1];
};

Oled49 display(
    Wire,
    ogh_config::OLED_I2C_ADDRESS,
    ogh_config::MIRROR_X,
    ogh_config::MIRROR_Y
);
Preferences preferences;

String cue_text = "OpenGlassHole ready";
String cue_etag;
uint16_t wrapped_line_starts[MAX_WRAPPED_LINES]{};
uint16_t wrapped_line_lengths[MAX_WRAPPED_LINES]{};
size_t wrapped_line_count = 0;
int32_t scroll_offset_px = 0;
int32_t max_scroll_offset_px = 0;
uint32_t scroll_ms = ogh_config::DEFAULT_SCROLL_MS;
uint32_t poll_ms = ogh_config::DEFAULT_POLL_SECONDS * 1000UL;
uint32_t next_frame_at = 0;
uint32_t next_poll_at = 0;
uint8_t consecutive_failures = 0;
bool paused = false;
bool display_blacked_out = false;
bool force_redraw = true;
bool force_fetch = true;
bool fetch_in_progress = false;
bool fetch_once_satisfied = false;
QueueHandle_t fetch_results = nullptr;
String fetch_etag;
uint32_t fetch_default_poll_ms = poll_ms;
uint32_t fetch_default_scroll_ms = scroll_ms;

bool last_button_raw = HIGH;
bool button_stable = HIGH;
uint32_t button_changed_at = 0;
uint32_t button_pressed_at = 0;

bool deadlineReached(uint32_t now, uint32_t deadline) {
    return static_cast<int32_t>(now - deadline) >= 0;
}

uint32_t boundedHeader(const String &value, uint32_t minimum, uint32_t maximum, uint32_t fallback) {
    if (value.isEmpty()) {
        return fallback;
    }
    const long parsed = value.toInt();
    if (parsed < static_cast<long>(minimum) || parsed > static_cast<long>(maximum)) {
        return fallback;
    }
    return static_cast<uint32_t>(parsed);
}

String urlEncode(const char *input) {
    const char hex[] = "0123456789ABCDEF";
    String encoded;
    while (*input != '\0') {
        const uint8_t value = static_cast<uint8_t>(*input++);
        if ((value >= 'a' && value <= 'z') || (value >= 'A' && value <= 'Z') ||
            (value >= '0' && value <= '9') || value == '-' || value == '_' || value == '.') {
            encoded += static_cast<char>(value);
        } else {
            encoded += '%';
            encoded += hex[value >> 4];
            encoded += hex[value & 0x0F];
        }
    }
    return encoded;
}

String sanitizeCue(const String &input) {
    String output;
    output.reserve(min(input.length(), MAX_CUE_CHARS));
    bool pending_space = false;
    uint8_t pending_newlines = 0;
    for (size_t index = 0; index < input.length() && output.length() < MAX_CUE_CHARS; ++index) {
        const uint8_t value = static_cast<uint8_t>(input[index]);
        if ((value & 0xC0U) == 0x80U) {
            continue;  // Continuation byte for a non-ASCII glyph already replaced below.
        }
        char character = value >= 0x80U ? '?' : static_cast<char>(value);
        if (character == '\r' || character == '\n') {
            pending_newlines = min<uint8_t>(2, pending_newlines + 1);
            pending_space = false;
            if (character == '\r' && index + 1U < input.length() && input[index + 1U] == '\n') {
                ++index;  // Treat a CRLF pair as one explicit line break.
            }
            continue;
        }
        if (character == '\t' || character == ' ') {
            if (pending_newlines == 0) {
                pending_space = true;
            }
            continue;
        }
        if (character < 0x20 || character > 0x7E) {
            continue;
        }

        if (!output.isEmpty()) {
            while (pending_newlines > 0 && output.length() < MAX_CUE_CHARS) {
                output += '\n';
                --pending_newlines;
            }
            if (pending_newlines == 0 && pending_space && output.length() < MAX_CUE_CHARS) {
                output += ' ';
            }
        }
        if (output.length() >= MAX_CUE_CHARS) {
            break;
        }
        output += character;
        pending_space = false;
        pending_newlines = 0;
    }
    return output;
}

void appendWrappedLine(size_t start, size_t length) {
    if (wrapped_line_count >= MAX_WRAPPED_LINES) {
        return;
    }
    wrapped_line_starts[wrapped_line_count] = static_cast<uint16_t>(start);
    wrapped_line_lengths[wrapped_line_count] = static_cast<uint16_t>(length);
    ++wrapped_line_count;
}

void rebuildWrappedLayout() {
    wrapped_line_count = 0;
    const size_t cue_length = cue_text.length();
    size_t paragraph_start = 0;

    while (paragraph_start <= cue_length && wrapped_line_count < MAX_WRAPPED_LINES) {
        size_t paragraph_end = paragraph_start;
        while (paragraph_end < cue_length && cue_text[paragraph_end] != '\n') {
            ++paragraph_end;
        }

        size_t cursor = paragraph_start;
        if (cursor == paragraph_end) {
            appendWrappedLine(cursor, 0);
        }
        while (cursor < paragraph_end && wrapped_line_count < MAX_WRAPPED_LINES) {
            while (cursor < paragraph_end && cue_text[cursor] == ' ') {
                ++cursor;
            }
            if (cursor >= paragraph_end) {
                break;
            }

            const size_t remaining = paragraph_end - cursor;
            if (remaining <= LINE_COLUMNS) {
                appendWrappedLine(cursor, remaining);
                cursor = paragraph_end;
                continue;
            }

            const size_t hard_end = cursor + LINE_COLUMNS;
            size_t line_end = hard_end;
            size_t next_cursor = hard_end;
            if (cue_text[hard_end] == ' ') {
                next_cursor = hard_end + 1U;
            } else {
                for (size_t probe = hard_end; probe > cursor; --probe) {
                    if (cue_text[probe - 1U] == ' ') {
                        line_end = probe - 1U;
                        next_cursor = probe;
                        break;
                    }
                }
            }
            if (line_end == cursor) {
                line_end = hard_end;
                next_cursor = hard_end;
            }
            appendWrappedLine(cursor, line_end - cursor);
            cursor = next_cursor;
        }

        if (paragraph_end >= cue_length) {
            break;
        }
        paragraph_start = paragraph_end + 1U;
    }

    if (wrapped_line_count == 0) {
        appendWrappedLine(0, 0);
    }
    const int32_t content_height = static_cast<int32_t>(wrapped_line_count * LINE_HEIGHT_PX);
    max_scroll_offset_px = max<int32_t>(0, content_height - Oled49::HEIGHT_PX);
}

void resetCueScroll() {
    rebuildWrappedLayout();
    scroll_offset_px = 0;
    next_frame_at = millis() + SCROLL_START_HOLD_MS;
    force_redraw = true;
}

void setCueText(const String &incoming, bool persist) {
    const String cleaned = sanitizeCue(incoming);
    if (cleaned == cue_text) {
        return;
    }
    cue_text = cleaned;
    if (persist) {
        preferences.putString("cue", cue_text);
    }
    resetCueScroll();
}

void renderCue(bool advance) {
    if (display_blacked_out) {
        return;
    }
    const uint32_t now = millis();
    if (!force_redraw && (paused || max_scroll_offset_px == 0)) {
        return;
    }
    if (!force_redraw && !deadlineReached(now, next_frame_at)) {
        return;
    }
    const bool redraw_only = force_redraw;
    force_redraw = false;

    if (advance && !redraw_only && !paused && max_scroll_offset_px > 0) {
        const ogh_motion::AdvanceResult result = ogh_motion::advanceScroll(
            SCROLL_MODE,
            scroll_offset_px,
            max_scroll_offset_px,
            LINE_HEIGHT_PX,
            scroll_ms,
            OGH_GLANCE_DWELL_MS,
            SCROLL_START_HOLD_MS,
            SCROLL_END_HOLD_MS
        );
        scroll_offset_px = result.offset_px;
        next_frame_at = now + result.wait_ms;
    }

    display.clear();
    display.setTextColor(1);
    display.setTextSize(ogh_config::TEXT_SIZE);
    display.setTextWrap(false);

    size_t first_line = 0;
    int16_t y = 0;
    if (max_scroll_offset_px == 0) {
        const int16_t content_height = static_cast<int16_t>(wrapped_line_count * LINE_HEIGHT_PX);
        y = static_cast<int16_t>((Oled49::HEIGHT_PX - content_height) / 2);
    } else {
        first_line = static_cast<size_t>(scroll_offset_px / LINE_HEIGHT_PX);
        y = static_cast<int16_t>(-(scroll_offset_px % LINE_HEIGHT_PX));
    }

    const size_t last_line = min(wrapped_line_count, first_line + VISIBLE_ROWS + 1U);
    for (size_t line = first_line; line < last_line; ++line) {
        const size_t start = wrapped_line_starts[line];
        const size_t end = start + wrapped_line_lengths[line];
        const int16_t line_width = static_cast<int16_t>(
            wrapped_line_lengths[line] * static_cast<size_t>(CHARACTER_WIDTH_PX)
        );
        const int16_t x = static_cast<int16_t>(
            VIEWPORT_X_PX + (VIEWPORT_WIDTH_PX - line_width) / 2
        );
        display.setCursor(x, y);
        for (size_t index = start; index < end; ++index) {
            display.write(static_cast<uint8_t>(cue_text[index]));
        }
        y = static_cast<int16_t>(y + LINE_HEIGHT_PX);
    }
    display.show();
}

void setRadioOff() {
    WiFi.disconnect(true, false);
    WiFi.mode(WIFI_OFF);
}

bool connectWifi() {
    if (WiFi.status() == WL_CONNECTED) {
        return true;
    }
    WiFi.mode(WIFI_STA);
    WiFi.setSleep(true);
    WiFi.begin(ogh_config::WIFI_SSID, ogh_config::WIFI_PASSWORD);
    const uint32_t started_at = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - started_at < ogh_config::WIFI_CONNECT_TIMEOUT_MS) {
        delay(10);  // The loop task keeps rendering while this network task yields.
    }
    if (WiFi.status() != WL_CONNECTED) {
        if (ogh_config::RADIO_OFF_BETWEEN_POLLS) {
            setRadioOff();
        }
        return false;
    }
    esp_wifi_set_ps(WIFI_PS_MAX_MODEM);
    return true;
}

template <typename Client>
bool performFetch(
    Client &client,
    const String &url,
    const String &request_etag,
    bool allow_bearer,
    FetchResult &result
) {
    HTTPClient request;
    request.setConnectTimeout(5000);
    request.setTimeout(4000);
    if (!request.begin(client, url)) {
        return false;
    }
    const char *response_headers[] = {"ETag", "X-Poll-Seconds", "X-Scroll-Ms"};
    request.collectHeaders(response_headers, 3);
    request.setUserAgent("OpenGlassHole/0.1");
    if (!request_etag.isEmpty()) {
        request.addHeader("If-None-Match", request_etag);
    }
    // Never send a credential over cleartext HTTP, even if a user
    // accidentally leaves BEARER_TOKEN configured while testing on a LAN.
    if (allow_bearer && strlen(ogh_config::BEARER_TOKEN) > 0) {
        request.addHeader("Authorization", String("Bearer ") + ogh_config::BEARER_TOKEN);
    }

    const int status = request.GET();
    if (status != HTTP_CODE_OK && status != HTTP_CODE_NOT_MODIFIED) {
        request.end();
        return false;
    }

    const uint32_t server_poll_seconds = boundedHeader(
        request.header("X-Poll-Seconds"), 2, 3600, result.poll_ms / 1000UL
    );
    result.poll_ms = server_poll_seconds * 1000UL;
    result.scroll_ms = boundedHeader(request.header("X-Scroll-Ms"), 25, 500, result.scroll_ms);

    if (status == HTTP_CODE_OK) {
        const int content_length = request.getSize();
        // The bundled server always supplies Content-Length. Requiring it here
        // rejects indefinite/chunked bodies and gives the response a hard RAM
        // and radio-time bound before getString() allocates anything.
        if (content_length < 0 || content_length > static_cast<int>(MAX_RESPONSE_BYTES)) {
            request.end();
            return false;
        }
        const String body = request.getString();
        if (body.length() != static_cast<size_t>(content_length) ||
            body.length() > MAX_RESPONSE_BYTES) {
            request.end();
            return false;
        }
        const String cleaned = sanitizeCue(body);
        cleaned.toCharArray(result.text, sizeof(result.text));
        result.has_text = true;
        const String next_etag = request.header("ETag");
        if (!next_etag.isEmpty()) {
            next_etag.toCharArray(result.etag, sizeof(result.etag));
        }
    }
    request.end();
    return true;
}

bool fetchCue(FetchResult &result) {
    if (!connectWifi()) {
        return false;
    }
    String url = ogh_config::CUE_URL;
    url += url.indexOf('?') >= 0 ? '&' : '?';
    url += "device=";
    url += urlEncode(ogh_config::DEVICE_ID);

    bool success = false;
    if (url.startsWith("https://")) {
        if (strlen(ogh_config::TLS_ROOT_CA) == 0) {
            Serial.println("HTTPS refused: TLS_ROOT_CA is empty");
        } else {
            WiFiClientSecure secure_client;
            secure_client.setCACert(ogh_config::TLS_ROOT_CA);
            secure_client.setHandshakeTimeout(TLS_HANDSHAKE_TIMEOUT_SECONDS);
            success = performFetch(secure_client, url, fetch_etag, true, result);
        }
    } else if (url.startsWith("http://")) {
        WiFiClient client;
        success = performFetch(client, url, fetch_etag, false, result);
    } else {
        Serial.println("CUE_URL must start with http:// or https://");
    }

    if (ogh_config::RADIO_OFF_BETWEEN_POLLS) {
        setRadioOff();
    }
    return success;
}

void networkTask(void *) {
    FetchResult result{};
    result.poll_ms = fetch_default_poll_ms;
    result.scroll_ms = fetch_default_scroll_ms;
    result.success = fetchCue(result);
    xQueueOverwrite(fetch_results, &result);
    vTaskDelete(nullptr);
}

void scheduleNextPoll(bool success) {
    const uint32_t now = millis();
    if (success) {
        consecutive_failures = 0;
        next_poll_at = now + poll_ms;
        return;
    }
    consecutive_failures = min<uint8_t>(consecutive_failures + 1, 6);
    const uint32_t backoff = min<uint32_t>(
        MAX_FAILURE_BACKOFF_MS,
        2000UL << (consecutive_failures - 1)
    );
    next_poll_at = now + max(poll_ms, backoff);
}

void startFetch() {
    fetch_etag = cue_etag;
    fetch_default_poll_ms = poll_ms;
    fetch_default_scroll_ms = scroll_ms;
    fetch_in_progress = true;
    const BaseType_t created = xTaskCreate(
        networkTask,
        "cue-fetch",
        NETWORK_TASK_STACK_BYTES,
        nullptr,
        1,
        nullptr
    );
    if (created != pdPASS) {
        fetch_in_progress = false;
        scheduleNextPoll(false);
        Serial.println("Could not create cue network task");
    }
}

void processFetchResult() {
    FetchResult result{};
    if (fetch_results == nullptr || xQueueReceive(fetch_results, &result, 0) != pdTRUE) {
        return;
    }
    fetch_in_progress = false;
    if (result.success) {
        fetch_once_satisfied = true;
        poll_ms = result.poll_ms;
        scroll_ms = result.scroll_ms;
        if (result.has_text) {
            setCueText(String(result.text), true);
        }
        if (result.etag[0] != '\0' && cue_etag != result.etag) {
            cue_etag = result.etag;
            preferences.putString("etag", cue_etag);
        }
    } else if (ogh_config::FETCH_ON_BOOT_ONLY) {
        // A boot/manual fetch that fails keeps retrying with backoff; once one
        // succeeds, automatic polling stops until the next long press.
        fetch_once_satisfied = false;
    }
    scheduleNextPoll(result.success);
}

void handleButton() {
    const uint32_t now = millis();
    const bool raw = digitalRead(BUTTON_PIN);
    if (raw != last_button_raw) {
        last_button_raw = raw;
        button_changed_at = now;
    }
    if (raw == button_stable || now - button_changed_at < BUTTON_DEBOUNCE_MS) {
        return;
    }
    button_stable = raw;
    if (button_stable == LOW) {
        button_pressed_at = now;
        return;
    }

    const uint32_t held_ms = now - button_pressed_at;
    if (held_ms >= BUTTON_FORCE_FETCH_MS) {
        force_fetch = true;
    } else {
        const ogh_motion::TapResult result = ogh_motion::shortTap(
            paused,
            OGH_BLACKOUT_ON_PAUSE != 0
        );
        paused = result.paused;
        if (result.blackout) {
            // Enter display-off first for an immediate blackout, then clear
            // controller RAM to avoid stale text when the user peeks again.
            display.setPowered(false);
            display_blacked_out = true;
            display.clear();
            display.show();
        } else if (display_blacked_out) {
            display.setPowered(true);
            display_blacked_out = false;
        }
        if (!paused) {
            // A restored peek gets a complete readable dwell instead of
            // immediately consuming an overdue frame from before the pause.
            next_frame_at = now + (
                SCROLL_MODE == ogh_motion::ScrollMode::LINE_STEPS
                    ? OGH_GLANCE_DWELL_MS
                    : scroll_ms
            );
        }
        force_redraw = true;
    }
}

uint32_t timeUntil(uint32_t now, uint32_t deadline) {
    const int32_t remaining = static_cast<int32_t>(deadline - now);
    return remaining > 0 ? static_cast<uint32_t>(remaining) : 0;
}

void idleUntilNextWork() {
    if (fetch_in_progress || !ogh_config::RADIO_OFF_BETWEEN_POLLS ||
        WiFi.status() == WL_CONNECTED || digitalRead(BUTTON_PIN) == LOW) {
        delay(2);
        return;
    }

    const uint32_t now = millis();
    const bool automatic_polling_enabled = !ogh_config::FETCH_ON_BOOT_ONLY ||
        !fetch_once_satisfied;
    uint32_t wait_ms = automatic_polling_enabled
        ? timeUntil(now, next_poll_at)
        : 60000UL;
    if (!paused && max_scroll_offset_px > 0) {
        wait_ms = min(wait_ms, timeUntil(now, next_frame_at));
    }
    if (wait_ms <= 2) {
        delay(1);
        return;
    }

    // OLED RAM remains powered while the ESP32-C3 light-sleeps. GPIO4 wakes on
    // a button press; the timer wakes just before the next frame or poll.
    esp_sleep_enable_timer_wakeup(static_cast<uint64_t>(wait_ms - 1) * 1000ULL);
    esp_light_sleep_start();
}

}  // namespace

void setup() {
    Serial.begin(115200);
#if OGH_USING_EXAMPLE_CONFIG
    Serial.println("Using config.example.h; copy it to config.h and set Wi-Fi/server values");
#endif
    pinMode(BUTTON_PIN, INPUT_PULLUP);
    setCpuFrequencyMhz(80);
    gpio_wakeup_enable(static_cast<gpio_num_t>(BUTTON_PIN), GPIO_INTR_LOW_LEVEL);
    esp_sleep_enable_gpio_wakeup();
    WiFi.persistent(false);
    WiFi.mode(WIFI_OFF);
    WiFi.setHostname("openglasshole");

    preferences.begin("ogh", false);
    fetch_results = xQueueCreate(1, sizeof(FetchResult));
    if (fetch_results == nullptr) {
        Serial.println("Could not allocate cue result queue");
    }
    const String stored_cue = preferences.getString("cue", cue_text);
    cue_etag = preferences.getString("etag", "");
    setCueText(stored_cue, false);
    resetCueScroll();

    if (!display.begin(OLED_SDA_PIN, OLED_SCL_PIN, OGH_OLED_I2C_HZ)) {
        Serial.println("OLED not found at configured I2C address");
    }
    display.setContrast(ogh_config::OLED_CONTRAST);
    renderCue(false);
    next_poll_at = millis();
}

void loop() {
    processFetchResult();
    handleButton();
    renderCue(true);
    const uint32_t now = millis();
    const bool automatic_polling_enabled = !ogh_config::FETCH_ON_BOOT_ONLY ||
        !fetch_once_satisfied;
    const bool automatic_poll_due = automatic_polling_enabled &&
        deadlineReached(now, next_poll_at);
    if (!fetch_in_progress && fetch_results != nullptr && (force_fetch || automatic_poll_due)) {
        force_fetch = false;
        startFetch();
    }
    idleUntilNextWork();
}
