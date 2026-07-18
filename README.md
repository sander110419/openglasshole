# Open OccuCue

An open-source, clip-on, monocular heads-up autocue for ordinary prescription glasses.
It uses a tiny Wi-Fi microcontroller, a 64×32 white OLED, one positive lens, and
a separate 45° combiner pane to put server-fed text at a comfortable
virtual distance. The reference optical path uses the OLED's central 48×32
pixels to trade two characters per line for a larger eye box.

![Open OccuCue optical path](docs/images/optical-path.svg)

![Open OccuCue deployed right-eye CAD assembly](hardware/cad/assembly-preview.png)

![Open OccuCue parked clear-away CAD assembly](hardware/cad/parked-preview.png)

*Reproducible source-CAD renders of the deployed and 100° parked poses, not
photographs or physical fit validation. The eye/lens/temple are scale proxies.*

> **Prototype status:** firmware, server, schematic, and parametric CAD are
> implemented and build-checked, but this v0.2 hardware has not yet been
> physically assembled or optically validated. Dimensions, runtime, eye box,
> hinge retention, walking comfort, and breakaway behavior are engineering
> targets until a real build report lands.

> **AI-generation disclosure:** Every repository artifact in the recorded
> generation run—code, CAD, schematics, documentation, tests, and native
> images—was produced or edited by OpenAI Codex. The requester contributed
> **zero manually authored implementation artifacts**. They did supply the
> natural-language prompts and publication direction, which are human input;
> the exact prompts, elapsed time, and token accounting are published in
> [AI_PROVENANCE.md](docs/AI_PROVENANCE.md).

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
  combiner. A keyed 16×14 mm rectangular stop has a first-order 8.23×8.82 mm
  full-field eye box; the pane—not the prescription lens—reflects the cue. A
  measured all-corner 6×6 mm eye box is still a build requirement, not a
  promise.
- **Expected use:** seated, stationary, indoor autocue. A controlled walking
  configuration adds whole-line stepping, one-tap blackout, a positively kept
  100° parked pose, and a body battery pod, but it remains an experimental
  [empty-level-room protocol](docs/WALKING_EXPERIMENT.md), not a general
  walking safety claim. It will wash out in sunlight.
- **Power target:** roughly 18–29 hours with 15-second radio-off polling and
  sparse low-contrast text; about 4.2 hours is the conservative sustained
  worst-case estimate. Neither is a measured runtime yet.
- **Packaging:** the optical tunnel remains 58.8 mm long and 27.9 mm square at
  the lens, but its main body is now 21.3×25.9 mm (about 29% less cross-section)
  and its keyed OLED sled uses about half the previous printed volume. The
  compact rail/hinge removes the 3 mm cross adapter and three net fasteners.
  Splitting the cell into a body pod shrinks the on-glasses electronics shell
  from 35.9×66.4×13.5 mm to about 22.9×31.4×10.8 mm. CAD volume and sourced
  component weights suggest roughly 35–45 g on the glasses, about 25 g below
  the legacy 55–65 g estimate. Neither estimate is measured.

The focus sled, padded strap saddle, sliding/flip-up carriage, integrated and
split pod variants, left/right assembly previews, bench jig, and combiner cut
template are parametric. The OLED driver pre-mirrors text and handles the
module's nonstandard visible RAM-column offset.

![Open OccuCue split controller and body battery pods](hardware/cad/split-pods-preview.png)

*The XIAO stays local to the OLED; only protected battery power crosses the
two-wire tether. Lids are exploded here to show the packaging proxies.*

## Safety first

This is uncertified DIY eyewear, not PPE or a medical device. Never use it while
driving, cycling, crossing roads, walking in traffic, using stairs, or operating
machinery. Charge the LiPo off-head and attended; never wear exposed prototypes.
The positive lens can concentrate sunlight, and every glass edge must be fully
captured. A tether is not a breakaway until it passes off-head pull tests. Read
[the complete safety rules](docs/SAFETY.md) before ordering parts.

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
radio off between polls, word-wraps it to 8 characters × 4 rows, and plays it
through network outages. Smooth scrolling remains available; optional glance
mode advances one complete row between stable dwell periods. The first and last
views pause before the cue loops. By default a short tap pauses and blacks out
the OLED, the next tap restores the same position, and a hold fetches
immediately.

## Build it

1. Read [SAFETY.md](docs/SAFETY.md), then inspect the
   [BOM](hardware/bom.csv), [costed upgrade options](docs/OPTIONS.md), and
   [power assumptions](docs/POWER.md).
2. Wire the OLED over USB only using the
   [schematic](hardware/electronics/schematic.svg).
3. Copy `firmware/include/config.example.h` to the gitignored `config.h`, set
   Wi-Fi/server values, then build and flash with PlatformIO.
4. Run the dependency-free server:

   ```sh
   export OPEN_OCCUCUE_API_KEY='replace-with-a-long-random-key'
   python3 server/cue_server.py --host 0.0.0.0 --port 8787
   ```

5. Print the fit coupon and focus jig. Prove focus and brightness on the bench
   before printing or wearing the clip.
6. Follow the [full build and alignment guide](docs/BUILD_GUIDE.md). Keep the
   first build stationary; the split-pod walking configuration has a separate
   [staged validation protocol](docs/WALKING_EXPERIMENT.md).

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
| [`docs/OPTIONS.md`](docs/OPTIONS.md) | Costed compactness, runtime, retention, and contrast options |
| [`docs/WALKING_EXPERIMENT.md`](docs/WALKING_EXPERIMENT.md) | Clear-away, tether, dummy-head, and controlled gait protocol |
| [`docs/AI_PROVENANCE.md`](docs/AI_PROVENANCE.md) | Verbatim prompts, generation disclosure, elapsed time, and token accounting |

## Validate the source

```sh
python3 -m unittest discover -s server/tests -v
python3 tools/check_bom.py
bash firmware/tests/run_host_tests.sh
pio run --project-dir firmware
make -C hardware/cad check-release
make -C hardware/cad check-previews
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
