#include "oled49.h"

#include <cstring>

namespace {
constexpr uint8_t CONTROL_COMMAND = 0x00;
constexpr uint8_t CONTROL_DATA = 0x40;
constexpr uint16_t COLOR_INVERSE = 2;
constexpr uint8_t FIRST_VISIBLE_COLUMN = 0x20;
constexpr uint8_t LAST_VISIBLE_COLUMN = 0x5F;
constexpr uint8_t LAST_VISIBLE_PAGE = 0x03;
constexpr size_t I2C_DATA_CHUNK = 24;  // control byte + data stays below Wire's buffer limit.
}  // namespace

Oled49::Oled49(TwoWire &wire, uint8_t address, bool mirror_x, bool mirror_y)
    : Adafruit_GFX(WIDTH_PX, HEIGHT_PX),
      _wire(wire),
      _address(address),
      _mirror_x(mirror_x),
      _mirror_y(mirror_y) {}

bool Oled49::begin(int sda_pin, int scl_pin, uint32_t clock_hz) {
    _wire.begin(sda_pin, scl_pin, clock_hz);
    _wire.beginTransmission(_address);
    if (_wire.endTransmission() != 0) {
        return false;
    }

    // Based on Waveshare's published OLED_0in49 initialization sequence. Use
    // horizontal addressing because our framebuffer is page-major.
    const uint8_t init[] = {
        0xAE,                    // display off
        0x00, 0x12,             // legacy column nibble defaults
        0x40,                    // display start line 0
        0xB0,                    // page 0
        0x81, 0x60,             // contrast (overridden by caller)
        static_cast<uint8_t>(_mirror_x ? 0xA1 : 0xA0),
        0xA6,                    // normal pixels
        0xA8, 0x1F,             // 1/32 multiplex
        static_cast<uint8_t>(_mirror_y ? 0xC0 : 0xC8),
        0xD3, 0x00,             // no display offset
        0x20, 0x00,             // horizontal addressing
        0xD5, 0x80,             // oscillator / divide ratio
        0xD9, 0xF1,             // pre-charge
        0xDA, 0x12,             // COM pin configuration used by this module
        0xDB, 0x40,             // VCOMH
        0x8D, 0x14,             // charge pump on
        0xAF,                    // display on
    };
    commands(init, sizeof(init));
    clear();
    show();
    return true;
}

void Oled49::drawPixel(int16_t x, int16_t y, uint16_t color) {
    if (x < 0 || x >= WIDTH_PX || y < 0 || y >= HEIGHT_PX) {
        return;
    }
    const size_t index = static_cast<size_t>(x) + static_cast<size_t>(y / 8) * WIDTH_PX;
    const uint8_t mask = static_cast<uint8_t>(1U << (y & 7));
    if (color == COLOR_INVERSE) {
        _buffer[index] ^= mask;
    } else if (color != 0) {
        _buffer[index] |= mask;
    } else {
        _buffer[index] &= static_cast<uint8_t>(~mask);
    }
}

void Oled49::clear() {
    std::memset(_buffer, 0, sizeof(_buffer));
}

void Oled49::show() {
    const uint8_t window[] = {
        0x21, FIRST_VISIBLE_COLUMN, LAST_VISIBLE_COLUMN,
        0x22, 0x00, LAST_VISIBLE_PAGE,
    };
    commands(window, sizeof(window));

    size_t offset = 0;
    while (offset < sizeof(_buffer)) {
        const size_t count = min(I2C_DATA_CHUNK, sizeof(_buffer) - offset);
        _wire.beginTransmission(_address);
        _wire.write(CONTROL_DATA);
        _wire.write(_buffer + offset, count);
        _wire.endTransmission();
        offset += count;
    }
}

void Oled49::setContrast(uint8_t contrast) {
    const uint8_t values[] = {0x81, contrast};
    commands(values, sizeof(values));
}

void Oled49::setPowered(bool powered) {
    command(powered ? 0xAF : 0xAE);
}

void Oled49::command(uint8_t value) {
    _wire.beginTransmission(_address);
    _wire.write(CONTROL_COMMAND);
    _wire.write(value);
    _wire.endTransmission();
}

void Oled49::commands(const uint8_t *values, size_t count) {
    // Command streaming is supported, but individual transactions also work
    // with conservative SSD1315 breakout implementations.
    for (size_t index = 0; index < count; ++index) {
        command(values[index]);
    }
}
