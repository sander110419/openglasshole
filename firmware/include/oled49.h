#pragma once

#include <Adafruit_GFX.h>
#include <Arduino.h>
#include <Wire.h>

// Minimal driver for Waveshare's 0.49-inch 64x32 SSD1315 module. Its visible
// columns are 0x20..0x5f inside the controller's 128-column RAM, which generic
// 64x32 SSD1306 libraries commonly miss.
class Oled49 final : public Adafruit_GFX {
public:
    static constexpr int16_t WIDTH_PX = 64;
    static constexpr int16_t HEIGHT_PX = 32;
    static constexpr size_t BUFFER_BYTES = WIDTH_PX * HEIGHT_PX / 8;

    Oled49(TwoWire &wire, uint8_t address, bool mirror_x, bool mirror_y);

    bool begin(int sda_pin, int scl_pin, uint32_t clock_hz = 400000);
    void drawPixel(int16_t x, int16_t y, uint16_t color) override;
    void clear();
    void show();
    void setContrast(uint8_t contrast);
    void setPowered(bool powered);

private:
    TwoWire &_wire;
    uint8_t _address;
    bool _mirror_x;
    bool _mirror_y;
    uint8_t _buffer[BUFFER_BYTES]{};

    void command(uint8_t value);
    void commands(const uint8_t *values, size_t count);
};
