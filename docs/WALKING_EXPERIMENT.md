# Controlled walking experiment

Open OccuCue is still an unvalidated DIY optical prototype. The reference
build is for seated, stationary use. This document describes the extra design
features and staged evidence required before trying it at walking pace in a
private, empty, level indoor room. It is **not** permission to use the display
in traffic, near stairs, while crossing a road, or anywhere a missed obstacle
could cause harm.

## Why the stationary build is not enough

The combiner occupies part of one eye's normal view, the eye box is small, and
head motion can turn a tolerable static alignment error into intermittent text,
double vision, or a prescription-lens strike. A body tether can also pull the
glasses toward the eye. Smoothly moving text adds another source of visual
motion while the vestibular system already senses walking.

No firmware option can remove those mechanical and human-factors risks. The
walking experiment therefore needs all of the following before a person moves:

- the complete 48×32 cue must pass the corner-aware eye-box check on the bench;
- the combiner must have a tool-free clear-away position with hard stops and a
  detent that does not rely on hinge friction alone;
- every glass edge and corner must remain inside the soft liner in both poses;
- the battery must be in the body pod, with only the local controller pod on
  the glasses and a tested low-retention disconnect close to the frame;
- the other eye and the lower field used to see the floor must stay clear;
- line-step display mode and one-tap blackout must work reliably;
- the complete dynamic test sequence below must pass without drift, contact,
  discomfort, visual symptoms, or a failed disconnect.

If any item is missing, keep the test seated.

## Low-mass experimental configuration

Keep the same XIAO, 64×32 OLED, 25 mm lens, central 48×32 viewport, focus
travel, combiner, button, protected 500 mAh cell, and server API. Put the XIAO,
button, antenna, and short OLED harness in `controller_pod` on the glasses. Put
only the protected cell and SW1 in `body_battery_pod` on a collar or secured
upper pocket. This preserves 400 kHz local I²C and the same nominal runtime
while removing the cell and most of the old rear-pod plastic from the temple.
The current CAD-volume/source-mass estimate is roughly 35–45 g on the glasses,
down from the legacy 55–65 g all-on-glasses estimate; neither range is measured.

Use a flexible, strain-relieved 26–28 AWG twisted BAT+/BAT− tether and put its
disconnect within 50 mm of the glasses. A two-contact pair maps the rails
directly. A four-contact pair may parallel the two outer contacts for switched
BAT+ and the two inner contacts for BAT−/GND; never put 3V3, USB 5 V, or I²C on
that parallel power pinout. Keep the tether against clothing, leave enough
slack for a full head turn, and keep it out of the neck loop.

The exact connector must be keyed, touch-safe, and unable to reverse BAT+/BAT−.
Do not call a magnetic connector a safety breakaway until the assembled cable
passes the surrogate pull tests below in every direction. A firm magnetic pair
may hold too strongly.

Use `compact_carriage`, not the legacy `quick_release` plus `mount_adapter`.
Fit an M2.5×22–25 pivot with washers and a nyloc, loose enough to move without
splitting the printed knuckles. Tie a short silicone/TPU keeper loop through
the moving bridge hole. Hook it onto the marked rear peg in the deployed pose
and the marked front peg after rotating the engine to its 100° parked hard
stop. The loop, not pivot friction, must retain both poses. Verify the pane is
fully above/temporal to normal and lower-forward view on the actual frame; the
CAD proxy cannot prove that for a face or prescription.

For steadier text, set:

```cpp
#define OGH_SCROLL_MODE 1
#define OGH_GLANCE_DWELL_MS 1200UL
#define OGH_BLACKOUT_ON_PAUSE 1
#define OGH_OLED_I2C_HZ 400000UL
```

Line-step mode moves one complete text row between stable views. A short tap
blacks out the pixels and selects the OLED controller's display-off mode; the
next tap restores the same cue position. This does not disconnect OLED VCC.
Long-press fetch and background polling remain available. Start with
a 1.2–1.8 second dwell and lower OLED contrast. If the cue cannot be read with
a brief glance, stop rather than staring through intermittent alignment.

## Stage 0: bench and dummy-head tests

Do these off-head, using a spare or representative glasses frame fixed to a
head form.

1. Map the complete-cue eye box at the real eye relief, including all four
   viewport corners. It must be at least 6×6 mm without clipping.
2. Flex the frame and mount through the measured range seen during a brisk head
   turn. Preserve at least 3 mm from every prescription-lens surface and keep
   all hard hardware away from the eye volume.
3. Cycle the clear-away mechanism 200 times. In every cycle it must reach both
   hard stops, engage its detent, retain the guarded pane, and clear normal and
   lower-forward sightlines when parked.
4. Shake and nod the head form for two minutes in each pose. Deployed aim must
   drift less than 0.5°; parked optics must not fall into view.
5. Pull the tether slowly and then with a brief snag surrogate in forward,
   rearward, upward, downward, and sideways directions. Record peak release
   force. The inline connector must release before the temple mount peels,
   the frame bends permanently, or any hard part approaches the eye. Never do
   an intentional snag test on a person.
6. Drop the unoccupied mounted glasses from 1 m onto a wooden surface in the
   most likely orientations. Reject cracked, chipped, loosened, or exposed
   glass and any latch that can self-deploy.
7. Run the cue for two hours while flexing the cable and exercising the
   disconnect. There must be no OLED corruption, reset, hot joint, exposed
   conductor, or loss of the cached cue.

Record on-glasses mass, fore/aft and lateral centre of mass, static temple
moment, deployed/parked envelope, disconnect force, drift, clearance, and every
failure in the build report. A CAD render or successful mesh check is not a
substitute for these measurements.

## Stage 1: stationary human checks

Only after Stage 0 passes:

1. Sit down with a second person present and a hand ready to remove the clip.
2. Confirm the parked state gives an immediately ordinary view and can be
   reached with one hand in under one second.
3. Check the cue for 30 seconds, then five minutes, then 30 minutes with breaks.
4. Stop for headache, eye strain, nausea, double vision, loss of balance,
   unusual refocusing delay, skin pressure, heat, or prescription-lens contact.
5. Repeat after deliberate head turns and nods, then remeasure aim and
   clearance off-head.

## Stage 2: controlled indoor walking

Use a private, evenly lit, empty, dry, level room with a spotter and a clear
perimeter. Remove rugs, cables, pets, furniture, thresholds, and other trip
hazards. Do not use stairs, doors, treadmills, public corridors, roads, or
traffic simulations.

Begin with the combiner parked and OLED blacked out. Walk the route normally,
then repeat with the combiner deployed but the OLED still black. Only then show
a short familiar cue in line-step mode. Use brief glances rather than continuous
reading and keep the lower field on the floor. Run 30 seconds, two minutes, and
five minutes, stopping between stages to inspect drift, cable routing, skin
pressure, and symptoms.

The experiment fails if the cue flickers in and out during normal gait, the
wearer changes gait to preserve the eye box, either eye loses the route, the
optics move toward the prescription lens, the tether can be felt pulling, the
clear-away action takes more than one second, or any symptom appears. A pass in
one room does not establish safety elsewhere.

## Outdoor and contrast limits

The budget OLED/50R-50T optics are not sunlight-readable. A removable opaque
contrast hood can help in a shaded stationary setup and can reduce the OLED
contrast needed indoors, but it blocks the world view. Never use the hood while
walking. Never face the positive lens toward the sun; park and cover the optics
before going outside. Full-sun or public-outdoor walking is outside the scope
of this design.
