# Power design and battery-life expectations

The reference design removes the radio from the hot path: it associates with
Wi-Fi, makes one conditional GET, turns Wi-Fi off, and scrolls the cached cue.
The server returns `304 Not Modified` when nothing changed. The ESP32 still has
to redraw the word-wrapped vertical scroller one pixel at a time, so this is not
deep-sleep operation.

Seeed publishes the following XIAO ESP32-C3 board figures: 75 mA active Wi-Fi,
25 mA modem sleep, 4 mA light sleep, 44 µA deep sleep, and a 380 mA charge
current. These are useful bounds, not a finished-device measurement. The OLED,
regulator loss, signal quality, association time, brightness, and lit-pixel
count change the result.

Use this deliberately conservative estimate:

```text
usable runtime hours ≈ battery mAh × 0.8 / measured average mA
```

The 0.8 factor allows for cell ageing, regulator dropout, temperature, and
optimistic capacity labels.

| Operating mode | Estimated average | 500 mAh estimate | Optional 1200 mAh estimate |
| --- | ---: | ---: | ---: |
| Worst sustained Wi-Fi + bright/all-pixel OLED | ~95 mA | ~4.2 h | ~10.1 h |
| Always connected, modem power-save | ~36 mA | ~11 h | ~26.7 h |
| Reference 15 s radio-off polling | ~14–22 mA | ~18–29 h | ~44–69 h |
| `FETCH_ON_BOOT_ONLY`, radio off during playback | ~8–16 mA | ~25–50 h | ~60–120 h |

Only the worst-case bound comes directly from adding published component-scale
figures. The other rows are engineering targets. Do not advertise a runtime
until it is measured on the assembled device.

The 1200 mAh column is arithmetic using the same assumptions, not a tested
pack. The costed 1200 mAh option is off-body, exceeds the $50 known-parts target
before tether/enclosure extras, weighs more, and needs a larger pod; see
[OPTIONS.md](OPTIONS.md). Do not put that cell on the glasses.

The compact reference keeps the XIAO and OLED together and carries only
protected 1S battery power over a short, flexible 26–28 AWG tether. Measure
voltage drop during Wi-Fi peaks and during the XIAO's 380 mA charge cycle. A
low-retention connector can reset the device if it bounces and is not a safety
breakaway without surrogate pull tests. Charging through the local XIAO
requires the tether connected and SW1 ON; always charge the entire assembly
off-head and attended.

## Measuring the real build

1. Fully charge the cell off-head.
2. Put a current/power logger in series with the battery; a USB meter mostly
   measures the charger and is misleading when the battery is attached.
3. Measure at least five minutes in each mode: scrolling offline, successful
   poll, failed server, failed Wi-Fi, always-connected, display blank, and max
   brightness.
4. Record Wi-Fi RSSI, poll interval, OLED contrast, cue pixel density, battery
   voltage, and firmware commit.
5. Integrate current over a full hour. Short transmit peaks can exceed 300 mA,
   so an average-only multimeter is not enough to validate wiring stability.
6. Update `hardware/power_budget.csv` with measured values and keep estimates
   clearly labelled.

## Easy ways to extend runtime

- Increase the poll interval from 15 to 30–60 seconds when instant updates are
  unnecessary.
- Keep `RADIO_OFF_BETWEEN_POLLS = true`.
- Reduce `OLED_CONTRAST`; OLED load depends strongly on lit pixels.
- Keep cue glyphs sparse and use a black background.
- Use line-step mode for stable dwell periods when desired; do not assume it
  saves power until current is measured because the same pixels remain lit.
- Short-tap blackout turns the OLED display off while paused, but background
  fetch timing continues; measure it rather than treating it as deep sleep.
- Fetch a complete short script and use the button to reload between sections.
- Use a physical switch for true off. Base-board deep sleep does not help much
  if the OLED remains powered.

The XIAO's 380 mA charger is within the documented protected PKCELL reference
cell's 500 mA maximum charge rate. That cell is also specified for 500 mA
continuous discharge. Do not substitute a smaller or undocumented cell without
checking both ratings.

## Primary references

- [Seeed XIAO ESP32-C3 power and charge specifications](https://wiki.seeedstudio.com/XIAO_ESP32C3_Getting_Started/)
- [Espressif ESP32-C3 datasheet current tables](https://documentation.espressif.com/esp32-c3_datasheet_en.pdf)
- [PKCELL protected 500 mAh LiPo specifications and dimensions](https://www.tinytronics.nl/en/power/batteries/li-po/pkcell-li-po-battery-3-7v-500mah-jst-ph-lp503035)
- [Adafruit LiPo protection and handling guidance](https://learn.adafruit.com/li-ion-and-lipoly-batteries/protection-circuitry)
