# OpenGlassHole

An open-source, clip-on, monocular heads-up autocue for ordinary prescription glasses.
It uses a tiny Wi-Fi microcontroller, a 64×32 white OLED, one positive lens, and
a separate 45° combiner pane to put scrolling server text at a comfortable
virtual distance. The reference optical path uses the OLED's central 48×32
pixels to trade two characters per line for a larger eye box.

![OpenGlassHole optical path](docs/images/optical-path.svg)

![OpenGlassHole right-eye CAD assembly preview](hardware/cad/assembly-preview.png)

*CAD packaging preview, not a photograph or physical fit validation.*

> **Prototype status:** firmware, server, schematic, and parametric CAD are
> implemented and build-checked, but this v0.1 hardware has not yet been
> physically assembled or optically validated. Dimensions, runtime, eye box,
> and comfort are engineering targets until a real build report lands.

## The honest version

- **Budget-reference known cost:** **$46.59 USD** (prices checked 2026-07-17),
  using linked major parts and
  consumable allowances in [hardware/bom.csv](hardware/bom.csv). The exact
  splitter listing includes delivery; other shipping, tax, tools, and the cost
  of buying full fastener/strap/filament packs remain unresolved, so this does
  **not** prove a delivered-under-$50 first build.
- **Electronics:** Seeed XIAO ESP32-C3, USB-C, 2.4 GHz Wi-Fi, onboard 1S LiPo
  charger, protected PKCELL 500 mAh cell, and a 0.49-inch Waveshare SSD1315
  OLED.
- **Optics:** a 25 mm / 45 mm FL positive lens and a 30×30 mm 50R/50T plate
  combiner. The pane—not the prescription lens—reflects the cue. A measured
  6×6 mm full-cue eye box is a build acceptance requirement, not a promise.
- **Expected use:** seated, stationary, indoor autocue. It will wash out in
  sunlight and has a much smaller eye box than commercial waveguide glasses.
- **Power target:** roughly 18–29 hours with 15-second radio-off polling and
  sparse low-contrast text; about 4.2 hours is the conservative sustained
  worst-case estimate. Neither is a measured runtime yet.
- **Packaging:** the printed forward assembly's CAD envelope is about
  89.2×61.1×46.4 mm (the tunnel itself is 58.8×27.9×27.9 mm). With the optional
  rear pod on the glasses, the full envelope is about 113.5×120.3×46.4 mm. A
  preliminary all-on-glasses mass estimate is roughly 55–65 g; use the
  documented collar/pocket-pod option if that is uncomfortable. Neither mass
  nor comfort has been measured on a real build.

The focus sled, padded strap saddle, sliding rail, separate rear electronics
pod, left/right assembly previews, bench jig, and combiner cut template are
parametric. The OLED driver pre-mirrors text and handles the module's
nonstandard visible RAM-column offset.

## Safety first

This is uncertified DIY eyewear, not PPE or a medical device. Never use it while
driving, cycling, crossing roads, walking in traffic, using stairs, or operating
machinery. Charge the LiPo off-head and attended; never wear exposed prototypes.
The positive lens can concentrate sunlight, and every glass edge must be fully
captured. Read [the complete safety rules](docs/SAFETY.md) before ordering parts.

## How it works

```text
phone/browser ──PUT──> tiny Python cue server
                             │
                        conditional GET
                             │ Wi-Fi every ~15 s
                             ▼
                   XIAO ESP32-C3 ─I²C─> OLED
                                           │
eye <─ prescription lens <─ combiner <─ collimating lens
```

The server returns raw cue text plus `ETag`, poll, and scroll headers. Unchanged
cues return `304` with no body. The display caches the last valid cue, turns the
radio off between polls, word-wraps it to 8 characters × 4 rows, and
scrolls upward through network outages. The first and last views pause briefly
before the cue loops. Tap the one button to pause/resume; hold it to fetch
immediately.

## Build it

1. Read [SAFETY.md](docs/SAFETY.md), then inspect the
   [BOM](hardware/bom.csv) and [power assumptions](docs/POWER.md).
2. Wire the OLED over USB only using the
   [schematic](hardware/electronics/schematic.svg).
3. Copy `firmware/include/config.example.h` to the gitignored `config.h`, set
   Wi-Fi/server values, then build and flash with PlatformIO.
4. Run the dependency-free server:

   ```sh
   export OPENGLASSHOLE_API_KEY='replace-with-a-long-random-key'
   python3 server/cue_server.py --host 0.0.0.0 --port 8787
   ```

5. Print the fit coupon and focus jig. Prove focus and brightness on the bench
   before printing or wearing the clip.
6. Follow the [full build and alignment guide](docs/BUILD_GUIDE.md).

The browser editor is at `http://<server-lan-ip>:8787/`. The firmware consumes
`/api/v1/cue.txt?device=default`; see [API.md](docs/API.md) for automation.

## Repository map

| Path | Contents |
| --- | --- |
| [`firmware/`](firmware/) | PlatformIO XIAO firmware and custom 0.49-inch SSD1315 driver |
| [`server/`](server/) | Dependency-free Python cue API, editor, persistence, and tests |
| [`hardware/cad/`](hardware/cad/) | Parametric OpenSCAD, export tooling, and printable releases |
| [`hardware/electronics/`](hardware/electronics/) | Wiring schematic and assembly checks |
| [`hardware/bom.csv`](hardware/bom.csv) | Linked major parts, consumable allowances, and the <$50 calculation |
| [`docs/OPTICS.md`](docs/OPTICS.md) | Optical design, calculations, focus, and combiner tradeoffs |
| [`docs/BUILD_GUIDE.md`](docs/BUILD_GUIDE.md) | End-to-end print, wire, focus, mount, and test procedure |

## Validate the source

```sh
python3 -m unittest discover -s server/tests -v
python3 tools/check_bom.py
pio run --project-dir firmware
make -C hardware/cad check-release
python3 tools/check_repo.py
```

The software build does not prove optical focus, OLED brightness, battery
runtime, LiPo safety, fit, or comfort. A first physical build should record each
item in the acceptance checklist and the
[build-report template](docs/BUILD_REPORT_TEMPLATE.md) rather than silently
changing the design.

## Design references

- [Seeed XIAO ESP32-C3 dimensions, charging, pins, and power](https://wiki.seeedstudio.com/XIAO_ESP32C3_Getting_Started/)
- [Waveshare 0.49-inch SSD1315 OLED specifications](https://www.waveshare.com/0.49inch-oled-module.htm)
- [Espressif ESP32-C3 current specifications](https://documentation.espressif.com/esp32-c3_datasheet_en.pdf)
- [CERN Open Hardware Licence v2](https://cern-ohl.web.cern.ch/)

## License

Software is MIT licensed. Hardware, CAD, schematics, and build documentation are
licensed under CERN-OHL-P-2.0. See [LICENSE](LICENSE) for the exact scope and
notices. Third-party components and libraries retain their own licenses.
