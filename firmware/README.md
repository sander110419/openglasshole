# Firmware

This PlatformIO project targets the Seeed Studio XIAO ESP32-C3 and the exact
Waveshare 0.49-inch 64×32 SSD1315 I²C module used by the reference CAD.

## Flash it

1. Install [PlatformIO](https://platformio.org/install).
2. Copy `include/config.example.h` to `include/config.h`.
3. Set the Wi-Fi SSID/password and the cue server's LAN URL in `config.h`.
4. Connect the XIAO over USB-C and run:

   ```sh
   pio run --target upload
   pio device monitor
   ```

The display downloads `cue.txt` with a conditional HTTP GET, caches the last
valid cue in flash only when it changes, then word-wraps and scrolls it with the
radio off. The reference optical build uses the central 48 columns at the
reference 5×7 font size, so text wraps to 8 columns × 4 rows. Words wrap at
spaces, words longer than 8 characters split safely, and
explicit line/paragraph breaks are retained. Cues of four wrapped rows or less
remain centered and static. Longer cues hold the first view for 1.2 seconds,
move upward one pixel per `scroll_ms`, hold the final four rows for 1.8 seconds,
then loop back to the beginning.

For a steadier glance while moving, set `OGH_SCROLL_MODE` to `1`. The display
then jumps by one complete text row and holds a fully aligned view for
`OGH_GLANCE_DWELL_MS` (1.2 seconds by default) before the next jump. The server's
`X-Scroll-Ms` value still controls smooth mode but is deliberately ignored for
line-step dwell. Set the mode back to `0` for the original smooth pixel scroll.
This reduces moving imagery; it does not make a centrally mounted combiner safe
for traffic, stairs, or unvalidated walking use.

Long-press the optional D2 button to fetch immediately. A short tap still
pauses/resumes without stopping background fetches, and by default it also
clears the pixels and puts the OLED in display-off mode. The next short tap
restores the same cue position and resumes: a one-action blackout/peek toggle
that removes stray light without adding another control. Set
`OGH_BLACKOUT_ON_PAUSE` to `0` for the original visible-pause behavior. A
changed cue restarts at its first view.
Set `FETCH_ON_BOOT_ONLY=true` to fetch a prepared script once and reconnect only
on a long press.

The custom display driver matters: the Waveshare module exposes controller
columns `0x20..0x5f`. A generic 64×32 SSD1306 library that writes columns
`0..63` can compile successfully yet show a blank panel.

Keep `OGH_OLED_I2C_HZ=400000UL` for the compact reference: the XIAO stays in
the local controller pod and only raw protected-battery power crosses the body
tether. Moving the controller off-head is a separate bench experiment. For its
body-length I²C harness, begin at no more than 250 mm and 100 kHz, then prove
signal integrity while flexing and disconnecting the real cable; a successful
firmware build is not that proof.

Plain HTTP is for a trusted LAN only. HTTPS requires a root CA, checks the
certificate chain/hostname, bounds the handshake, and sends a bearer value only
over TLS. The pinned Arduino-ESP32 build does **not** validate certificate dates,
however, so this is not a hardened public-internet client. Prefer a private LAN
or VPN and do not expose the bundled server directly.
