# Wiring and power

The reference build is point-to-point wiring. It deliberately avoids a custom
PCB and a separate charger. See [schematic.svg](schematic.svg) for the full
diagram.

## Pin map

| Function | XIAO label | ESP32-C3 GPIO | Connect to |
| --- | --- | --- | --- |
| OLED data | D4 / SDA | GPIO6 | OLED SDA |
| OLED clock | D5 / SCL | GPIO7 | OLED SCL |
| Pause/fetch button | D2 | GPIO4 | Button, then GND |
| OLED power | 3V3 | — | OLED VCC |
| Common return | GND | — | OLED GND, button, battery negative |
| Battery positive | BAT+ pad | — | Protected LiPo positive through SW1 |
| Battery negative | BAT− pad | — | Protected LiPo negative |

The Waveshare cable pin labels, not cable colours, are authoritative. Cable
colours can change between batches. Verify every connection and LiPo polarity
with a multimeter before plugging in USB or connecting the battery.

## Why this power path

The XIAO contains a single-cell charger specified by Seeed at 380 mA. The
reference 500 mAh protected cell accepts up to 500 mA charging, so the two are
compatible on paper. SW1 sits in series with battery positive; this is the
fewest-part topology, but it means **SW1 must be ON to charge the battery**.
USB-C can still power and flash the board while SW1 is OFF.

Do not add a common 1 A TP4056 module. It duplicates the charger and its default
current can exceed a small cell's safe charge rate.

The XIAO ESP32-C3 uses its included external antenna. Snap it onto the U.FL
connector before fitting the rear cover and keep the antenna clear of the LiPo,
wires, and metal fasteners.

## Assembly checks

1. With battery disconnected, check there is no short between 3V3 and GND.
2. Confirm BAT+ and BAT− at both ends of the pigtail; never trust JST colours or
   connector orientation alone.
3. Power over USB first. Confirm the OLED is detected at I²C address `0x3c`.
4. Disconnect USB. Connect the protected LiPo with SW1 OFF, then switch ON.
5. Charge on a nonflammable surface while the device is off your head. A normal
   full charge should take roughly 1.5–2 hours including the CV taper.

Short Wi-Fi transmit peaks can exceed 300 mA at the chip. Use short power wires
and the documented reference cell, which is rated for 500 mA continuous
discharge. Verify peak stability and actual current on the finished build before
wearing it. Replace, do not reuse, any swollen, creased, punctured, hot, or
damaged cell.

## Optional OLED hard-off

The base design uses the physical switch for true off. For deep standby without
switching the whole unit off, a high-side P-channel MOSFET can disconnect OLED
VCC. That option is intentionally not in the baseline schematic or firmware:
it needs careful gate logic and I²C pins must go high-impedance before power is
cut to avoid phantom powering the OLED.
