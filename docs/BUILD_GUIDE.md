# Build guide

Read [SAFETY.md](SAFETY.md) first. The safest and fastest path is to prove the
optics on a bench, then print the wearable parts. A beautiful glasses clip
cannot rescue an unreadable combiner.

## Tools and skills

- FDM printer with black PETG and optionally TPU
- fine-tip temperature-controlled soldering iron, flux, solder, side cutters
- multimeter with continuity and DC voltage modes
- small screwdrivers, M2 and M2.5 hardware, heat-shrink, tweezers
- digital calipers plus a clean straightedge/depth-gauge fixture for lens sag
- lens cloth, nitrile gloves, black flocking tape or matte paint
- a phone/camera with manual infinity focus for optical setup

This is a moderate soldering and optical-alignment project, not a no-tools kit.
Practice on scrap wire before soldering the XIAO battery pads.

## 1. Buy and inspect the parts

Order the required rows in [the BOM](../hardware/bom.csv). The 25 mm / 45 mm
budget reference has **$46.59 of known line-item cost**. The splitter listing
included delivery when researched, but electronics/lens shipping and tax remain
unresolved. Combine electronics orders, reuse consumable scraps, and check the
actual cart total. Tooling and full packs/spools of generic consumables are not
included; the under-$50 delivered target is not yet demonstrated by a build
report.

The baseline already uses the smallest packaging that preserves the validated
CAD optical path: a local controller pod and an off-body 500 mAh cell. Review
the [costed options](OPTIONS.md) before substituting a cell, connector, retainer,
hood, or pane; most combinations leave little or no margin below $50.

When the parts arrive:

1. Photograph labels and measure the OLED board, emitting-area centre,
   connector, lens diameter, rim/centre thickness, both face crown sags,
   combiner thickness, cell, button body/stem, and glasses temple. Support each
   lens rim plane on a clean depth fixture and measure its crown independently;
   do not infer symmetry from centre thickness. Edge thickness plus both sags
   must close to centre thickness within the CAD's 0.20 mm allowance.
2. Mark the lens face chosen to point toward the image-side stop on removable
   rim tape. Enter that face as `LENS_FRONT_SAG` and the OLED-side face as
   `LENS_REAR_SAG`.
3. Compare the cell charge rating with the XIAO's 380 mA charger. Do not proceed
   if the rating is unknown or lower.
4. Mark the combiner's coated/reflective face using removable tape on its frame,
   never ink or adhesive on the optical area.
5. Edit the parameters at the top of `hardware/cad/openglasshole.scad` before
   exporting final parts.

## 2. Prove the OLED and firmware on USB

Wire only the OLED and button according to the
[schematic](../hardware/electronics/schematic.svg). Leave the battery disconnected.

The OLED cable labels are authoritative:

```text
OLED VCC → XIAO 3V3     OLED SDA → XIAO D4 / GPIO6
OLED GND → XIAO GND     OLED SCL → XIAO D5 / GPIO7
button   → XIAO D2 and GND
```

Install PlatformIO, copy the configuration, and build:

```sh
cp firmware/include/config.example.h firmware/include/config.h
pio run --project-dir firmware
pio run --project-dir firmware --target upload
pio device monitor --baud 115200
```

Because VS Code is running as a Flatpak on the reference workstation, USB serial
may be easier from a normal host terminal. If the extension cannot see the
XIAO, do not change device permissions blindly; use the host PlatformIO CLI or
grant only the relevant USB/serial access through Flatseal.

The text must appear mirrored on a directly viewed OLED when `MIRROR_X=true`;
the combiner reflection makes it readable. If the panel is blank, confirm `0x3c`
with an I²C scanner and use this repository's driver—the module's visible RAM
starts at column `0x20`, unlike many generic SSD1306 examples.

## 3. Run the cue server

On a laptop or Raspberry Pi connected to the same 2.4 GHz LAN:

```sh
export OPENGLASSHOLE_API_KEY='replace-with-a-long-random-key'
python3 server/cue_server.py --host 0.0.0.0 --port 8787
```

Find that computer's LAN address, put it in `CUE_URL` inside the private
`firmware/include/config.h`, flash again, then open the displayed editor URL on
a phone. Send a short cue and verify it updates within the configured poll
interval. See [API.md](API.md) for curl and HTTPS options.

## 4. Print the calibration parts

Start with:

- `fit_coupon.stl`
- `focus_bench_jig.stl`
- `oled_cartridge.stl`
- `lens_tunnel.stl`
- `lens_retainer.stl`
- `combiner_frame.stl`
- `combiner_clamp.stl`
- `combiner_shim.stl` (TPU or trace the pattern into soft foam)
- `combiner_edge_liner.stl` (soft TPU or cast/cut silicone; never rigid plastic)

Recommended first print settings are black PETG, 0.2 mm layers, 0.4 mm nozzle,
three perimeters, four top/bottom layers, and 25% gyroid infill. Use no supports
unless the slicer preview shows an unsupported bridge. Keep optical interiors
matte; shiny black plastic still reflects.

Print the lens retainer with its smaller aperture face on the bed. The opening
widens toward the full-diameter counterbore, keeping the taper self-supporting;
confirm the three tiny crescent lands remain distinct in the sliced preview.

Check the coupon. Aim for 0.20–0.30 mm sliding clearance per mating side,
0.20–0.30 mm diametral lens clearance, and combiner thickness plus 0.15–0.25 mm.
Adjust CAD parameters and reprint the coupon before the long parts.

## 5. Bench-focus the optical engine

1. Fit the OLED without glue on the emitting window and provide cable strain
   relief. Black tape around the board may seal stray light, but not cover parts
   that warm up.
2. Install the lens with the measured/entered front face toward the image-side
   stop. Apply nominally 0.7–0.8 mm removable silicone, TPU, or
   closed-cell-foam dots
   to the three front and three rear printed lands. Measure the actual lens rim
   and compressed pads: together they must lightly fill the modeled land
   spacing without preload or rattle. The image-side tapered aperture opens
   into a full-diameter counterbore before the lands and must not touch either
   convex surface; never tighten the retainer enough to flex or point-load it.
3. Dry-fit `combiner_edge_liner` around all four pane edges and corners first.
   Its one-piece soft collar must stay below both coated faces. Lower pane and
   liner into the frame together and confirm no bare edge can touch a rigid
   rail. Then add the separate `combiner_shim` face gasket in soft TPU/foam.
   Never use rigid PETG/PLA for either soft part, never glue the coating, and put
   the coated face toward the incoming OLED beam.
4. Place the OLED emitting plane near the lens BFL and leave the lock screw loose.
5. Put an infinity-focused camera at the eye datum. Aim past the combiner at a
   target at least several metres away.
6. Move the OLED sled until cue and target are simultaneously sharp. Check the
   centre first, then accept that a single cheap lens will have blurry edges.
7. Lock focus and map the usable eye box by moving the camera left/right/up/down.
   Target at least 6×6 mm while the complete central 48×32 cue remains visible.
   Reject or rework the wearable if the bench cannot meet that threshold.
8. Test both OLED rotations while the loose module is safely supported on the
   bench if a polarized lens makes the cue dim. The reference cartridge does
   not accept a 90° board rotation: swap the measured PCB/window Y/Z parameters
   and reprint a matching cartridge before assembly.

If the image never becomes sharp, confirm the emitting plane—not the PCB—is at
the focal distance. If it is sharp but doubled, reverse the plate or use a
thinner/first-surface combiner. If it is readable only in darkness, add the
opaque contrast flag or a higher-reflectance combiner.

## 6. Assemble the wearable

Only after the optical bench succeeds, print `temple_saddle`,
`compact_carriage`, `engine_cradle`, `engine_clamp`, `combiner_bracket`,
`controller_pod`, `controller_pod_lid`, `body_battery_pod`,
`body_battery_pod_lid`, and `rear_button_retainer`. The separately released
`quick_release`, `mount_adapter`, `rear_pod`, and `rear_pod_lid` are legacy
stationary-build parts, not the compact reference. Print the button retainer
flat on a broad face and deburr its open U-slot without thinning the side
bearings. Use a removable opaque card or soft cover as a sunlight/storage flag;
remove an opaque contrast hood before any walking experiment.

Do not orient `combiner_bracket` like the bench lens retainer: its pane socket
projects beyond the narrow stop plane. Put its square tunnel-interface,
full-pocket face on the bed with the socket rising. Add removable support from
the build plate inside the narrowing lens aperture and beneath the socket
arm/capture boss, keeping support off the three pad lands where possible. After
cleanup, verify the 16×14 mm aperture, undamaged lands, and at least 0.6 mm hard
clearance to the measured lens surface. Reject or redesign a print whose
support scars intrude into the lens cell.

1. Line the saddle with 1 mm TPU/silicone and strap it to the glasses temple
   using two separate 6–8 mm hook-and-loop bands. Nothing clamps the
   prescription lens; the bands are the intended snag-releasing element, not a
   certified breakaway.
2. Slide `compact_carriage` onto the saddle rail and lock it with the
   side-access M2.5×6 screw. This is a position lock, not a breakaway. The rail
   adjusts fore/aft only; set height/yaw/elevation by repositioning the padded
   saddle or by measured, keyed wedge shims, then re-run the optical test.
3. Put the `engine_clamp` centre barrel between the carriage knuckles. Fit an
   M2.5×22–25 pivot with a washer at both ends and a nyloc, tightening only
   enough to remove axial play. Before fitting it, inspect all four fixed stop
   spines, both moving stop wings, and their narrow roots under magnification;
   reject incomplete layers, support scars on a contact face, cracks, or poor
   fusion. At 0° and 100°, both left/right stop patches must seat together
   without twisting the barrel. Tie a short replaceable silicone/TPU keeper
   through the moving bridge and prove it seats positively on the deployed and
   parked keeper pegs. The hard stops define angle; the keeper retains contact,
   and pivot friction does neither. Cycle the mechanism 200 times off-head and
   reject cracked, whitening, loose, asymmetric, or self-deploying parts.
4. Put the tunnel in the split collar and fasten the lower cradle to the upper
   clamp with two M2×6 screws. Use the M2.5×35 focus bolt with broad washers and
   a nyloc; do not substitute a longer screw near the optical path. Fit the
   bracket to the tunnel with two M2×6 screws, compressing only the compliant
   lens pads.
5. Fit the guarded combiner sandwich into the bracket socket. With both screw
   heads on the clamp/outboard face, use an M2×12 bolt through the 7.25 mm
   bracket-captured lower-ear stack and an M2×10 through the 4.25 mm upper-ear
   stack. Put a ≤5.0 mm OD washer and ordinary approximately 2.8 mm-high M2
   nyloc on each base/bracket side; each bolt must extend at least two complete
   0.4 mm thread pitches past its locknut. Before inserting the pane, verify the
   actual hardware preserves at least the modeled worst-case 1.05 mm gap to
   glass and 0.25 mm to the fitted liner. Keep at least 2.5 mm dynamic clearance
   from prescription lenses through deliberate frame flex. The pane's chief-ray
   point is centred on the chosen pupil and occupies that eye's normal
   sightline; keep the other eye unobstructed.
6. Route the four OLED wires above the temple hinge with a service loop and at
   least a 5 mm bend radius. Confirm the glasses can fold without pinching them.
7. Strap `controller_pod` to the temple with two independent bands. Install the
   XIAO, external antenna, and OLED harness locally so the I²C run remains short;
   keep the antenna clear of wires and metal hardware. Both complete strap
   footprints must wrap the temple.
8. Wire the long-stem button, insert it stem-first from the controller-lid
   underside, and slide `rear_button_retainer` under its body from the cage's
   open `+Y` side
   until it stops on both ledges. Kapton may prevent withdrawal/rattle but must
   not carry button force. Confirm repeated presses react against the printed
   plate, not tape, solder joints, or the controller.
9. Put the protected cell and SW1 in `body_battery_pod`, confirming polarity
   twice. The cell must float in removable padding with strain relief; no screw
   or clip root may touch it. Route only a flexible, twisted 26–28 AWG
   BAT+/BAT− pair to the glasses. Fit a keyed, touch-safe, low-retention
   disconnect within 50 mm of the frame and verify the exact pinout in the
   [wiring guide](../hardware/electronics/wiring.md) before connecting a cell.
   Keep the body pod on a collar or secured upper pocket and route the tether
   against clothing, outside any neck loop.
10. Close both pods with two M2×8 screws each. Record forward-optics, local-pod,
    total on-glasses, and off-body-pod mass plus fore/aft and lateral centre of
    mass. CAD volume and sourced component masses suggest a **35–45 g**
    on-glasses target, roughly 25 g below the legacy 55–65 g estimate, but
    neither is measured. If it slides, changes gait, or creates pressure, stop;
    do not counter it with a tighter non-releasing mount.

## 7. Charge and acceptance test

Remove the glasses, place them on a nonflammable surface, switch SW1 ON, then
connect USB-C. Attend the first full charge and check repeatedly for heat or
swelling. Do not wear while charging.

Before normal use, pass these checks:

- cue and distant target are comfortable at the same eye focus
- central-48×32 full-cue eye box is at least approximately 6×6 mm
- the soft radial collar covers all pane edges/corners, the face gasket prevents
  rattle, and no glass touches a rigid rail or fastener
- measured lens-to-stop hard clearance is at least 0.6 mm, and dynamic
  prescription-lens clearance is at least 2–3 mm
- mount aim drifts less than about 0.5° after repeated nodding
- the clear-away hinge completes 200 off-head cycles, both hard stops remain
  intact, the keeper positively retains both poses, and one hand parks it in
  under one second without the pane entering the normal/lower-forward view
- an off-head pull test on a surrogate/spare frame shows the padded
  hook-and-loop mount peels free before the frame is overstressed; never perform
  a deliberate snag test while wearing it
- in every surrogate pull direction, the battery connector separates before
  the temple mount releases or the frame permanently bends; record the force
- wire is not pinched when glasses fold
- both controller-pod straps fully wrap the temple, and 50 button presses cause
  no switch/retainer movement, lead strain, or tape loading
- the body pod remains secured to clothing through full head turns without a
  felt tether pull, exposed conductor, reset, hot contact, or cable loop at the
  neck
- short and two-hour stationary comfort tests are acceptable
- update, Wi-Fi outage, server outage, pause, and reload all preserve a readable
  cached cue
- actual current and runtime are measured and recorded

Passing these checks establishes only a stationary prototype. Do not begin a
gait test until every Stage 0 and Stage 1 item in the
[controlled walking protocol](WALKING_EXPERIMENT.md) also passes.

## Troubleshooting

| Symptom | Likely cause | Check |
| --- | --- | --- |
| OLED blank | wrong driver RAM columns or I²C wiring | address `0x3c`, D4/D5, repository driver |
| Text reversed | combiner handedness differs | toggle `MIRROR_X` / `MIRROR_Y` |
| Cue sharp, world blurry | eye/camera focused near | move OLED toward the calibrated virtual-distance position |
| No focus anywhere | wrong BFL or emitting-plane datum | extend sled range; measure from active pixels |
| Double image | second pane-surface reflection | coated face toward beam; thinner pane; first-surface splitter |
| Image disappears with sunglasses | crossed polarization | rotate OLED 90° and refocus |
| Tiny eye box | viewport, alignment, eye relief, or small aperture | keep the central-48 crop; improve alignment; reduce eye relief; use a larger matched lens/combiner |
| Cue freezes during fetch | slow/weak Wi-Fi | increase poll interval, improve antenna placement, cache full cue |
| Battery drains quickly | radio remains connected or high contrast | radio-off setting, server reachability, measure current |
| Charge never starts | reference switch topology | set SW1 ON; recheck battery polarity and rating |
