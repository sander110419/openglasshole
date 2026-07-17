# OpenGlassHole CAD

This directory contains the parametric OpenSCAD 2021.01 source, reviewed STL
exports, and mechanical validation tools for the v0.1 monocular autocue. It is
a buildable optical/mechanical experiment, not certified eyewear. Prove the
optics on the bench before putting any part near an eye.

![Wearable assembly preview with the optional rear pod hidden](assembly-preview.png)

## Presets and optical limits

`lens_preset="budget_25x45"` is the source and release-STL default:

- sourced 25 mm diameter, +45 mm focal-length biconvex acrylic lens;
- published 1.2 mm **edge** thickness, provisional 5 mm centre thickness and
  provisional, separately entered 1.90 mm crown sag on each face;
- explicit provisional packaging/focus-start datum 0.6 mm behind the front rim
  plane; this is not inferred from lens symmetry or claimed as a principal plane;
- 38–52 mm OLED focus travel, previewed at 45 mm;
- central 48×32 pixels of the 64×32 OLED (7.44×4.96 mm active viewport);
- conservative 15 mm physical aperture stop;
- 30×30×1.1 mm 50R/50T plate at 45 degrees, with 28 mm frame opening;
- 15 mm nominal lens-to-combiner axial gap and 32 mm bench eye datum.

`compact_23x30` remains available in source for experiments, but it is not a
recommended or release preset. At the same 32 mm eye datum its 10 mm stop and
wider field cannot provide a useful common full-viewport eye box. Do not buy the
more expensive compact lens on the assumption that it is a drop-in upgrade.

The SCAD computes the first-order extrema where the aperture/field rays meet an
oblique 45-degree pane. It also shifts the physical pane along its own axis to
centre that asymmetric footprint. For the budget preset the modeled footprint
is about 24.89 mm wide and the signed frame shift is about -1.03 mm, leaving
about 1.55 mm per side in the 28 mm opening. This calculation is deliberately
not presented as a guarantee: the physical stop is on the OLED side of a thick,
cheap singlet, and real principal planes, aberrations, decentre, and surface
tolerances matter. The focus bench and eye-box mapping are authoritative.

The modeled ray plane is the combiner's incoming/coated glass face, not the
printable base. The frame base is shifted 2.7 mm behind that face along the
pane normal, and each bracket/bench socket is centred on the complete 4.25 mm
base–glass–gap–clamp stack. This datum distinction prevents the plastic stack
from silently moving the reflected ray.

The best-case first-order common eye box at 15+32 mm propagation is only about
7.2 mm horizontal by 9.8 mm vertical for the budget preset. Treat that as an
optimistic estimate. Reject or redesign a build if the mapped eye box is not
comfortable; do not compensate by placing glass closer to the eye.

## Safe lens cell

The biconvex lens is not trapped between flat 15 mm rings. The tunnel has:

- full-diameter relief around both curved lens surfaces;
- three rear printed lands near the physical outer rim;
- three matching front lands on `lens_retainer` or `combiner_bracket`;
- a 15 mm tapered stop on the exterior/image-side front plate;
- a final 1.0 mm full-pocket counterbore before the compliant lands.

The SCAD takes `LENS_FRONT_SAG` and `LENS_REAR_SAG` as independent measured
inputs and derives a separate spherical envelope from each. The symmetric
1.90 mm defaults are provisional packaging data only. An asymmetric biconvex
lens may put most of its crown on either face. The stop-facing/image-side
**front** sag alone drives the analytic hard-gap check across the complete
taper; the rear sag alone drives the tunnel relief depth. The minimum need not
occur at the 15 mm aperture edge. With the provisional defaults, the true
minimum is about 1.012 mm at radius 11.036 mm for the budget lens and 0.855 mm
at radius 7.965 mm for the compact lens. Both exceed the asserted 0.6 mm
minimum, but neither is a guarantee for a purchased lens.

Before printing the final cell, measure the real lens in this order:

1. Measure diameter, centre thickness, and outer-rim edge thickness without
   squeezing the acrylic.
2. Support one rim plane on a depth-gauge fixture, measure its crown height,
   flip the lens, and independently measure the other crown height.
3. Confirm `edge + front sag + rear sag` agrees with centre thickness within
   the named 0.20 mm measurement allowance. Mark the face chosen to point at
   the retainer/combiner as **front/image-side** on removable rim tape.
4. Enter both measured sags and thicknesses, regenerate, and inspect the
   physical cell for at least 0.6 mm hard-surface clearance. The derived
   spherical surfaces are still approximations; the focus bench and a physical
   no-contact inspection are authoritative.

Put a matched nominal 0.7–0.8 mm closed-cell silicone, TPU, or optical-foam dot
on each of the six lands. Each opposing pair must exceed 1.2 mm uncompressed
(normally 1.4–1.6 mm total) and compress lightly into that modeled allowance;
reject a pair that rattles or requires plate bowing. Trim every dot so it
contacts only the outermost lens rim. Tighten the two front screws evenly only
until the dots prevent rattle. Printed plastic must never touch or preload
either convex clear surface.

## Combiner retention

Use the purchased square 30×30×1.1 mm glass plate as supplied. Do **not** score,
grind, chamfer, drill, or round the coated glass. The rounded/chamfered
`cut_template` is only for machinable plastic/film experiments or a professional
vendor-cut alternative. Mark coating orientation on removable frame tape, not
by modifying the pane.

The base's four overlapping full-length rails define a 32.0 mm rigid cavity;
they must never touch bare glass. Fit `combiner_edge_liner` around all four
edges and corners first. It is a one-piece **soft TPU or silicone** radial
collar with 29.8 mm free opening, 31.4 mm free outer size, 0.8 mm nominal wall,
and corner reliefs. Its 0.10 mm-per-side stretch gives a conservative 31.6 mm
fitted envelope, leaving 0.20 mm per side to the rails. Its 0.90 mm height is
recessed 0.10 mm from each glass face so it cannot become an axial clamp land.

Dry-fit the collar on the unmodified pane, covering every edge and corner.
Verify that it sits below both coated faces, then lower the pane and collar into
the frame together. Confirm soft material separates every glass edge from every
rigid rail; never force, abrade, score, or glue the pane. Only then add
`combiner_shim`, the separate 0.30 mm **soft TPU or foam face gasket**, inside
the rails. It compresses into the nominal 0.15 mm axial stack gap. Neither soft
part may be printed in rigid PETG/PLA.

The clamp uses two M2 through-bolts. Their head, nut, and washer envelope must
be no larger than 5.0 mm OD. After the modeled ±0.25 mm pane/liner motion and
±0.25 mm screw motion, the derived geometry preserves 1.05 mm to glass and
0.25 mm to the fitted liner. Put both heads on the clamp/outboard face and the
washer/nut on the base/bracket side. The wearable bracket positively captures
the complete lower ear with a rear boss; its shallow socket is alignment, not
safety retention. Tighten only until the face gasket prevents rattle; stop if
the frame bows or glass sees point pressure.

## Selectors

Set `part` in `openglasshole.scad` or pass `-D 'part="..."'`.

| Selector | Output | Purpose |
| --- | --- | --- |
| `assembly` | preview | Pupil-centred right/left wearable, real mount chain, pod, and chief ray. |
| `bench_assembly` | preview | Focus bench with the shifted combiner and nominal optics. |
| `focus_bench_jig` | printable | Canonical focus jig filename/selector. |
| `focus_bench` | printable | Backward-compatible alias for `focus_bench_jig`. |
| `oled_cartridge` | printable | Guided OLED bezel, cable relief, and focus-bolt hole. |
| `lens_tunnel` | printable | Support-free light tunnel, compliant rear lands, and focus slots. |
| `lens_retainer` | printable | Bench retainer with tapered surface relief and front pad lands. |
| `combiner_frame` | printable | Four-edge pane base with two M2 clearance ears. |
| `combiner_clamp` | printable | Matching two-screw clamp ring. |
| `combiner_shim` | soft printable/template | Compressible perimeter gasket; never rigid filament. |
| `combiner_edge_liner` | soft printable/template | Recessed, four-edge radial glass guard with corner reliefs. |
| `temple_saddle` | printable | Padded V saddle, two hook-and-loop strap stations, and rail. |
| `quick_release` | printable | Sliding carriage with side-access M2.5 rail lock. |
| `mount_adapter` | printable | Recessed/piloted cross adapter for staged assembly. |
| `engine_cradle` | printable | Lower split collar with clamp pilots. |
| `engine_clamp` | printable | Upper collar plus rearward/raised temple-offset arm. |
| `combiner_bracket` | printable | Lens-safe front plate, shifted pane socket, and bolted capture boss. |
| `rear_pod` | printable | Protected-cell/XIAO pod, external strap ears, USB/switch/cable openings. |
| `rear_pod_lid` | printable | Screwed lid with BTN1 reaction cage and FPC-antenna guides. |
| `rear_button_retainer` | printable | Slide-in wired-button backstop with open U-slot and pull tab. |
| `fit_coupon` | printable | Lens diameter, three pane slots, and rail fits. |
| `cut_template` | 2D DXF/SVG | Plastic/film/vendor-cut alternative only. |
| `cut_template_print` | printable | Physical plastic/film template; not a glass-working guide. |

`side` accepts `"right"` or `"left"` for the preview. Manufacturing parts are
not handed.

## Export and validation

Reviewed budget-preset meshes are tracked in [`stl/`](stl/). Local exports go
to ignored `build/` and are never silently overwritten:

```bash
cd hardware/cad
./export.sh fit_coupon stl
./export.sh lens_tunnel stl compact_23x30
./export.sh cut_template dxf
FORCE=1 ./export.sh fit_coupon stl
```

`OPENSCAD_BIN=/path/to/openscad` selects a custom executable; otherwise the
scripts try native OpenSCAD and then the Flatpak. The release-parity check is:

```bash
OPENSCAD_BIN=/path/to/openscad make validate
```

This renders every selector under both presets using OpenSCAD 2021 syntax,
rejects warnings/errors/empty output, then checks every STL for one connected
component, exactly two triangles per edge, and nonzero enclosed volume using the
dependency-free `validate_mesh.py`. It also proves that a rear-heavy asymmetric
lens still renders while the same large sag on the stop-facing front trips the
hard-gap assertion. To regenerate the tracked default meshes:

```bash
OPENSCAD_BIN=/path/to/openscad make release-stls
```

To prove tracked meshes have exactly the regenerated triangles (independent of
OpenSCAD facet ordering and winding) without changing them:

```bash
OPENSCAD_BIN=/path/to/openscad make check-release
```

## Printing and staged fasteners

Start with the fit coupon and focus bench. Suggested first settings are a
0.4 mm nozzle, 0.2 mm layers, three walls, and matte black PETG. Print the soft
combiner face gasket and edge liner separately in TPU, or cut/cast them from
suitable soft foam/silicone. Keep all optical interiors matte.

Orient the tunnel on its square lens end; OLED cartridge on its bezel; pod on
its closed floor; bench on its base. Put the `lens_retainer`'s **narrow 15 mm
stop face down**, so its aperture widens upward and its small front-pad
cantilevers remain self-supporting. Put the combiner rings on a flat face. The
offset `engine_clamp` normally prints with its top pad on the bed and the split
collar rising from it; inspect bridges and use localized support if your slicer
cannot bridge the arm.

Print `rear_button_retainer` flat on either broad face. Deburr its U-slot and
pull-tab edges without thinning the two side bearings.

`combiner_bracket` is a different one-piece shape: its socket/arm extends about
28 mm past the narrow stop plane, so that plane **cannot** sit on the bed. Put
the square tunnel-interface/full-pocket face (source `x=0`) on the bed with the
socket rising. Use removable, localized support from the build plate inside the
narrowing lens aperture and beneath the socket arm/capture boss. Keep support
off the three compliant-pad lands where possible. After removal, deburr without
enlarging the stop, confirm the 15 mm aperture and pad lands, and re-check at
least 0.6 mm hard clearance to the measured lens surface. If support cannot be
removed without scars or distortion in the cell, reject the print and split or
redesign the bracket; this part is not claimed to be support-free.

The modeled fastening order avoids inaccessible nuts:

| Qty | Fastener | Use |
| ---: | --- | --- |
| 2 | M2×5 socket head, head ≤4.4 mm OD ×2.0 mm high | adapter to carriage |
| 6 | M2×6 socket head | split collar (2), engine pad (2), lens plate (2) |
| 2 | M2×8 socket head | pod lid |
| 1 | M2×10 socket head | upper combiner ear |
| 1 | M2×12 socket head | bracket-captured lower combiner ear |
| 2 each | M2 washer ≤5.0 mm OD and M2 nyloc nut | both combiner ears |
| 1 | M2.5×6 socket head | carriage rail position lock |
| 1 | M2.5×35 bolt, two 8 mm OD washers, one M2.5 nyloc nut | focus lock |

1. Install two M2×5 socket-head screws (head OD ≤4.4 mm, height ≤2.0 mm)
   through the adapter's recessed X pair into the carriage's 3.5 mm blind
   pilots. The engine-pad relief accepts the remaining head projection.
2. Slide the carriage onto the saddle rail. Lock it from the exposed side with
   an M2.5×6 set screw; the carriage is a position lock, **not** a breakaway.
3. Fit the split collar around the tunnel using two M2×6 screws through the
   upper clearance flanges into the lower printed pilots.
4. Put the adapter under the raised offset pad. Insert two M2×6 screws from the
   pad's top Y pair into the adapter's printed pilots.
5. Use an M2.5×35 bolt, broad washers, and nyloc nut for the focus cartridge.
6. Use two short M2×6 screws for the lens-safe retainer/bracket, tightening the
   compliant dots evenly.
7. With heads on the clamp/outboard face, use one M2×12 bolt through the
   7.25 mm bracket-captured lower-ear stack and one M2×10 bolt through the
   4.25 mm upper-ear stack. Put a ≤5.0 mm OD, nominal 0.30 mm washer and an
   ordinary nominal 2.80 mm-high M2 nyloc on each base/bracket side. The source
   reserves another 0.80 mm for two full thread pitches beyond each locknut.
   Verify the actual stack and the worst-case glass/liner gaps before inserting
   the pane.
8. Use two M2×8 screws for the pod lid's external bosses.

Printed pilots are consumable. If repeated service loosens them, reprint or use
a deliberately resized heat-set insert design; do not improvise longer screws
where a battery or optical surface lies behind them.

## Bench and wearable reality

The v0.1 wearable uses a pupil-centred, same-height chief ray and a vertical
45-degree pane. It does not fake an unsupported raised reflection. The 50/50
pane therefore occupies the monocular sightline and is for seated, stationary,
indoor autocue testing only. The fixed bracket has no yaw/elevation gimbal.
Fore/aft travel comes from the rail; coarse placement comes from repositioning
the padded saddle straps. If on-frame alignment needs angular correction,
measure it and redesign/print a keyed wedge or gimbal before use.

The preview models a 2.5 mm minimum prescription-lens clearance and a rearward
top offset so the temple saddle remains near pupil height. Verify at least
2–3 mm under deliberate glasses-frame flex on the actual frame. Two separate
padded hook-and-loop bands are the intended snag release; the screwed carriage
and glass-frame bolt are not breakaways.

The optional rear pod is intentionally side-mounted: its inner body face is
tangent to the saddle's outboard face, while the nearest strap slot sits farther
outboard and each band bridges back to the temple. It is not centred on top of
the glasses arm. The preview derives its 100 mm temple proxy from both rear-pod
strap stations and asserts that each complete 6.5 mm band footprint lands on
the proxy. On real glasses, confirm both independent bands fully wrap the
temple and release under a snag before adding electronics.

The fixed OLED cartridge fits only the documented PCB orientation. If a loose
90-degree polarization test is better, swap the measured PCB/window Y/Z values
and reprint; the rectangular board cannot simply be forced into this cartridge.

The pod cavity models the protected 31×38×5.3 mm cell and a maximum
17.8×21×4.2 mm assembled XIAO/controller-and-connector envelope with a 3 mm end
gap. Battery guides leave 0.6 mm per side for removable soft padding. The lid
locates a provisional 18×8 mm supplied FPC antenna against plastic and keeps
the 6 mm BTN1 cage at least 5 mm from it. The cage bottom preserves a modeled
0.5 mm above that controller envelope; measure the tallest real board,
connector, solder, and wire feature and enlarge the pod if it exceeds 4.2 mm.

BTN1 must have an actuator at least 2.5 mm above its case so it projects at
least 0.9 mm above the 1.6 mm lid; a common short-stem switch is not operable
here. Install the wired switch from the lid underside, stem first, with its body
top against the lid and leads routed toward the cage's open `+Y` side. Slide
`rear_button_retainer` under the body from that side until its rear land stops;
the open U-slot lets the leads remain attached. The 0.8 mm plate bears on two
integral 0.85 mm ledges, providing the axial press reaction. Kapton may cross
the forked pull tab only as an anti-withdrawal/anti-rattle aid; it must not carry
button force, and glue is not a structural backstop. Remove that tape and pull
the plate out for switch service.

A local lip notch clears the nominal button body. Measure its body, stem, pin
exits, and lead bend before printing. Use the antenna adhesive plus Kapton, do
not cover its radiator with metal, and remove the lid for XIAO boot/reset
access. The USB-C, slide-switch, OLED-cable, and button openings still require
measurement against purchased parts.

Key release-mesh envelopes are 58.8×27.9×27.9 mm for `lens_tunnel`,
34.2×44.1×4.25 mm for the assembled printed combiner base/clamp stack before
hardware, 101.8×75×37.5 mm for the focus jig, and 46.3×66.4×13.5 mm for the
assembled rear pod and lid including external ears. At the nominal right-eye
placement, the forward printed assembly's axis-aligned envelope is
89.18×61.10×46.35 mm; mounting the optional rear pod as previewed expands that
to 113.48×120.30×46.35 mm. The rear pod can instead move to a pocket or collar
without changing the optical engine.

## Mass and placement

For the budget preset, modeled worn printed volume, including both soft
combiner parts and the button retainer, is 32.58 cm³:

| Group | Volume | Solid PETG equivalent (1.27 g/cm³) |
| --- | ---: | ---: |
| Forward optics + saddle/mount | 21.65 cm³ | 27.5 g |
| Rear pod + lid + button retainer | 10.93 cm³ | 13.9 g |
| Total worn printed geometry | 32.58 cm³ | 41.4 g |

A three-wall/25%-infill slice is still dominated by thin shells; record the
slicer's actual estimate instead of multiplying the solid equivalent by 25%.
With glass, lens, cell, boards, wire, straps, and fasteners, a complete
glasses-mounted prototype is more realistically around 55–65 g, not 30–35 g.
Move the rear pod and battery to a pocket/collar pack if comfort or frame load
is unacceptable; that removes about 13.9 g of printed pod parts plus the rear
electronics/cell from the glasses. The focus jig and fit coupon add 50.95 cm³
(64.7 g solid-PETG equivalent) but are calibration tools, not worn mass.

Never wear while charging. Never drive, cycle, walk in traffic, or perform a
safety-critical task with the pane in view. Keep the assembly away from direct
sunlight: a positive lens can concentrate solar energy onto the OLED or nearby
material.
