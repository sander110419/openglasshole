/*
 * Open OccuCue v0.2 mechanical reference
 *
 * Units: millimetres.
 * Axes in the assembly preview:
 *   +X = wearer's right, +Y = forward, +Z = up.
 * The optical engine itself is modelled along +X: light leaves the OLED,
 * travels toward -X through the lens, then turns toward the eye at the
 * 45-degree combiner.
 *
 * This is packaging CAD, not an optical ray tracer. Print the fit coupon and
 * focus bench before committing to the wearable parts. Measure every sourced
 * component and override the top-level parameters as needed.
 */

$fn = 56;
part = "assembly";
side = "right";              // "right" or "left"; used by assembly preview
exploded = 0;                 // preview separation, 0 for nominal assembly
lens_preset = "budget_25x45"; // "budget_25x45" or "compact_23x30"
wear_pose = "deployed";       // "deployed" or "parked"; assembly preview only
show_rear_pod = false;        // legacy all-on-glasses pod; assembly preview only
show_controller_pod = true;   // local XIAO + remote body battery experiment
show_wearer_proxy = true;     // eye, prescription lens, temple, and ray
hinge_probe_angle = 50;       // developer-only interference selector

// ---------- Printer and fastener allowances ----------
WALL = 1.2;                   // three 0.4 mm perimeters
FIT = 0.25;                   // general FDM sliding clearance, per side
EPS = 0.02;
M2_CLEAR_D = 2.5;
M2_PILOT_D = 1.8;
M25_CLEAR_D = 2.9;
M25_PILOT_D = 2.1;
M2_WASHER_T = 0.30;
M2_NYLOC_H = 2.80;
M2_THREAD_PROTRUSION = 0.80; // two full 0.4 mm pitches beyond the locknut

// ---------- Concrete v0.2 budget optics ----------
// The required/BOM-default lens is the EUR 1.50, 25 mm / +45 mm biconvex
// acrylic lens. The optional compact lens shortens the engine but costs more.
// The budget preset uses the central 48 x 32 viewport on the 28 mm-clear,
// 45-degree combiner. The compact preset is retained for experiments only.
LENS_D = lens_preset == "budget_25x45" ? 25.0 : 23.0;
// The budget stop is rectangular because the 48 x 32 field is rectangular.
// Unlike a circular stop, it does not throw away the common pupil-box corners.
// The compact experiment retains its original circular 10 mm stop.
LENS_STOP_RECTANGULAR = lens_preset == "budget_25x45";
LENS_STOP_SIZE = lens_preset == "budget_25x45" ? [16.0, 14.0] : [10.0, 10.0];
LENS_STOP_MAX_R = LENS_STOP_RECTANGULAR
                  ? sqrt(pow(LENS_STOP_SIZE[0] / 2, 2)
                         + pow(LENS_STOP_SIZE[1] / 2, 2))
                  : LENS_STOP_SIZE[0] / 2;
LENS_STOP_ANGLE_SAMPLES = 144;
LENS_RELIEF_MESH_ALLOWANCE = 0.02;
LENS_FL = lens_preset == "budget_25x45" ? 45.0 : 30.0;
LENS_TO_COMBINER = 15.0;
EYE_DATUM_DISTANCE = 32.0;
LENS_EDGE_T = lens_preset == "budget_25x45" ? 1.2 : 1.5;
LENS_CENTER_T = 5.0;          // provisional; measure the actual lens
// Measure each crown height independently from its own rim plane. Never infer
// these from centre thickness alone: an asymmetric biconvex lens can put most
// of its sag on the stop-facing/front surface.
LENS_FRONT_SAG = lens_preset == "budget_25x45" ? 1.90 : 1.75;
LENS_REAR_SAG = lens_preset == "budget_25x45" ? 1.90 : 1.75;
LENS_MEASUREMENT_CLOSURE_TOL = 0.20; // cheap depth-gauge/caliper stack-up
LENS_POCKET_DIAMETRAL_CLEAR = 0.30;
LENS_RETAINER_T = 2.4;
LENS_PAD_D = 1.6;
LENS_PAD_R = LENS_D / 2 + 0.1;
LENS_PAD_GAP = 0.6;           // fill with 0.7--0.8 mm silicone/TPU/foam dots
LENS_FRONT_PAD_LENGTH = 0.4;
LENS_REAR_PAD_X = LENS_EDGE_T + LENS_PAD_GAP;
LENS_SURFACE_CLEAR = 0.6;     // rear full-diameter relief beyond centre apex
LENS_RELIEF_END_X = LENS_EDGE_T + LENS_REAR_SAG + LENS_SURFACE_CLEAR;
// Explicit provisional packaging/focus-start datum. It is not derived from
// the sag values and is not a claim about the thick lens's principal planes.
// Establish the real OLED position on the focus bench.
LENS_PRINCIPAL_FROM_FRONT_RIM = lens_preset == "budget_25x45" ? 0.60 : 0.75;
LENS_FRONT_RADIUS = ((LENS_D / 2) * (LENS_D / 2)
                     + LENS_FRONT_SAG * LENS_FRONT_SAG)
                    / (2 * max(LENS_FRONT_SAG, EPS));
LENS_REAR_RADIUS = ((LENS_D / 2) * (LENS_D / 2)
                    + LENS_REAR_SAG * LENS_REAR_SAG)
                   / (2 * max(LENS_REAR_SAG, EPS));

// A hull from the stop profile to the circular pocket contains the same-angle
// linear radial interpolation used here. Sampling that conservative interior,
// including the spherical stationary point, lower-bounds the real hard gap.
function lens_stop_radius(angle) =
    LENS_STOP_RECTANGULAR
    ? min((LENS_STOP_SIZE[0] / 2) / max(abs(cos(angle)), EPS),
          (LENS_STOP_SIZE[1] / 2) / max(abs(sin(angle)), EPS))
    : LENS_STOP_SIZE[0] / 2;
function lens_front_surface_x(radius) =
    sqrt(max(0, LENS_FRONT_RADIUS * LENS_FRONT_RADIUS
                - (LENS_D / 2) * (LENS_D / 2)))
    - sqrt(max(0, LENS_FRONT_RADIUS * LENS_FRONT_RADIUS
                  - radius * radius));
function lens_taper_slope(plate_t, angle) =
    (plate_t - LENS_PAD_GAP - LENS_FRONT_PAD_LENGTH)
    / ((LENS_D + LENS_POCKET_DIAMETRAL_CLEAR) / 2
       - lens_stop_radius(angle));
function lens_taper_wall_x(radius, plate_t, angle) =
    -plate_t + lens_taper_slope(plate_t, angle)
    * (radius - lens_stop_radius(angle));
function lens_gap_at_radius(radius, plate_t, angle) =
    lens_front_surface_x(radius)
    - lens_taper_wall_x(radius, plate_t, angle);
function lens_gap_critical_radius(plate_t, angle) =
    let(slope = lens_taper_slope(plate_t, angle),
        stationary = slope * LENS_FRONT_RADIUS / sqrt(1 + slope * slope))
    min(LENS_D / 2, max(lens_stop_radius(angle), stationary));
function lens_min_hard_gap_at_angle(plate_t, angle) =
    min(lens_gap_at_radius(lens_stop_radius(angle), plate_t, angle),
        lens_gap_at_radius(LENS_D / 2, plate_t, angle),
        lens_gap_at_radius(lens_gap_critical_radius(plate_t, angle),
                           plate_t, angle));
function lens_min_hard_gap(plate_t) =
    min([for (i = [0 : LENS_STOP_ANGLE_SAMPLES - 1])
         lens_min_hard_gap_at_angle(
             plate_t, i * 360 / LENS_STOP_ANGLE_SAMPLES)])
    - LENS_RELIEF_MESH_ALLOWANCE;

FOCUS_MIN = lens_preset == "budget_25x45" ? 38.0 : 24.0;
FOCUS_MAX = lens_preset == "budget_25x45" ? 52.0 : 34.0;
FOCUS_NOMINAL = lens_preset == "budget_25x45" ? 45.0 : 29.0;

COMBINER_PANE = [30.0, 30.0, 1.1];
COMBINER_CLEAR = [28.0, 28.0];
COMBINER_ANGLE = 45.0;
COMBINER_FRAME_RIM = 2.0;
COMBINER_BASE_T = 1.6;
COMBINER_CLAMP_T = 1.4;
COMBINER_PANE_GAP = 0.15;
PANE_SLOT_CLEAR = 0.20;
COMBINER_SHIM_T = 0.30;
COMBINER_CORNER_R = 2.0;
COMBINER_EDGE_LINER_T = 0.80; // nominal fitted radial thickness, soft material
COMBINER_EDGE_LINER_INTERFERENCE = 0.10; // per side before TPU stretch
COMBINER_EDGE_LINER_CLEAR = 0.20; // per side to the rigid locator rails
COMBINER_EDGE_LINER_FACE_RECESS = 0.10;
COMBINER_EDGE_LINER_CORNER_RELIEF_R = 0.35;
COMBINER_LOCATOR_W = 1.10;
COMBINER_EDGE_LINER_FREE_INNER = COMBINER_PANE[0]
                                 - 2 * COMBINER_EDGE_LINER_INTERFERENCE;
COMBINER_EDGE_LINER_FREE_OUTER = COMBINER_EDGE_LINER_FREE_INNER
                                 + 2 * COMBINER_EDGE_LINER_T;
COMBINER_EDGE_LINER_FITTED_OUTER = COMBINER_PANE[0]
                                   + 2 * COMBINER_EDGE_LINER_T;
PANE_LOCATOR_GAP = COMBINER_PANE[0]
                   + 2 * (COMBINER_EDGE_LINER_T
                          + COMBINER_EDGE_LINER_CLEAR);
PANE_WORST_LATERAL_PLAY = 0.25; // liner clearance plus plausible compression

// ---------- OLED cartridge ----------
// Waveshare 0.49 inch module reference. Measure thickness, active-area offset,
// and cable exit on the actual module before printing the final cartridge.
OLED_PCB = [3.0, 15.5, 13.0]; // [thickness along X, long Y, high Z]
OLED_ACTIVE = [9.92, 4.96];    // verify on the sourced display
OLED_RESOLUTION = [64, 32];
OLED_VIEWPORT = [48, 32];       // central columns; firmware viewport must match
OLED_WINDOW = [11.5, 6.5];    // [Y, Z], deliberately generous
OLED_WINDOW_OFFSET = [0.0, 0.0];
OLED_CART_DEPTH = OLED_PCB[0] + 2 * WALL;
// The old 25 mm square sled wasted volume around a 15.5 x 13 mm PCB. This
// keyed rectangle preserves the same board pocket and focus lock while making
// yaw impossible through unlike Y/Z dimensions.
OLED_CART_Y = OLED_PCB[1] + 2 * WALL + 2 * FIT;
OLED_CART_Z = 23.0; // leaves 0.8 mm below and 1.05 mm above the focus bolt
OLED_FACE_X = WALL;
OLED_LOCK_X = OLED_CART_DEPTH - 1.5;
OLED_LOCK_Z = OLED_CART_Z / 2 - 2.5;

// ---------- Tunnel ----------
TUNNEL_INNER = LENS_D + 0.5; // square lens-cell throat (legacy alias)
TUNNEL_OUTER = TUNNEL_INNER + 2 * WALL;
TUNNEL_BODY_INNER = [OLED_CART_Y + 2 * FIT,
                     OLED_CART_Z + 2 * FIT];
TUNNEL_BODY_OUTER = [TUNNEL_BODY_INNER[0] + 2 * WALL,
                     TUNNEL_BODY_INNER[1] + 2 * WALL];
// Keep the front pilots and full lens relief in a square cell, then taper only
// the exterior/cavity needed by the smaller keyed OLED sled.
TUNNEL_SHOULDER_X = max(8.0, LENS_RELIEF_END_X + 2.0);
TUNNEL_NECK_X = TUNNEL_SHOULDER_X + 5.0;
TUNNEL_LENGTH = LENS_PRINCIPAL_FROM_FRONT_RIM + FOCUS_MAX
                - OLED_FACE_X + OLED_CART_DEPTH + 2.0;
FOCUS_SLOT_X0 = LENS_PRINCIPAL_FROM_FRONT_RIM + FOCUS_MIN
                - OLED_FACE_X + OLED_LOCK_X;
FOCUS_SLOT_X1 = LENS_PRINCIPAL_FROM_FRONT_RIM + FOCUS_MAX
                - OLED_FACE_X + OLED_LOCK_X;

// ---------- Combiner frame ----------
FRAME_OUTER = [COMBINER_PANE[0] + 2 * COMBINER_FRAME_RIM,
               COMBINER_PANE[1] + 2 * COMBINER_FRAME_RIM];
COMBINER_RAIL_BASE_BEARING = FRAME_OUTER[0] / 2
                             - PANE_LOCATOR_GAP / 2;
FRAME_EAR_D = 6.0;
FRAME_FASTENER_OD = 5.0;
FRAME_SCREW_RADIAL_PLAY = (M2_CLEAR_D - 2.0) / 2;
FRAME_REQUIRED_GLASS_GAP = 0.50;
FRAME_REQUIRED_LINER_GAP = 0.25;
// Include pane/liner play and screw-in-clearance-hole play before applying the
// residual glass/soft-liner safety gaps.
FRAME_EAR_X = COMBINER_PANE[1] / 2
              + PANE_WORST_LATERAL_PLAY
              + FRAME_SCREW_RADIAL_PLAY
              + FRAME_FASTENER_OD / 2
              + max(FRAME_REQUIRED_GLASS_GAP,
                    COMBINER_EDGE_LINER_T + FRAME_REQUIRED_LINER_GAP);
FRAME_WORST_GLASS_GAP = FRAME_EAR_X - FRAME_SCREW_RADIAL_PLAY
                        - FRAME_FASTENER_OD / 2
                        - COMBINER_PANE[1] / 2
                        - PANE_WORST_LATERAL_PLAY;
FRAME_WORST_LINER_GAP = FRAME_WORST_GLASS_GAP
                        - COMBINER_EDGE_LINER_T;
FRAME_MIN_U = min(-FRAME_OUTER[0] / 2,
                  -FRAME_EAR_D / 2);
FRAME_LOWEST_V = max(FRAME_OUTER[1] / 2,
                     FRAME_EAR_X + FRAME_EAR_D / 2);
FRAME_STACK_T = COMBINER_BASE_T + COMBINER_PANE[2]
                + COMBINER_PANE_GAP + COMBINER_CLAMP_T;
COMBINER_REFLECT_W = COMBINER_BASE_T + COMBINER_PANE[2];
DISPLAY_HALF_FIELD_H = atan((OLED_ACTIVE[0]
                             * OLED_VIEWPORT[0] / OLED_RESOLUTION[0])
                            / (2 * LENS_FL));
DISPLAY_FIELD_SLOPE = tan(DISPLAY_HALF_FIELD_H);
DISPLAY_HALF_FIELD_V = atan((OLED_ACTIVE[1]
                             * OLED_VIEWPORT[1] / OLED_RESOLUTION[1])
                            / (2 * LENS_FL));
DISPLAY_FIELD_SLOPE_V = tan(DISPLAY_HALF_FIELD_V);
// Sample every rectangular stop corner and field corner. Those samples are
// the exact extrema for the budget rectangle; the compact circle uses a dense
// boundary sample. Each ray meets the modeled 45-degree plane x-y+L=0 at the
// path length below. A D/cos(45)+2Ltan(theta) sum is not valid here.
LENS_STOP_BOUNDARY = LENS_STOP_RECTANGULAR
                     ? [[-LENS_STOP_SIZE[0] / 2, -LENS_STOP_SIZE[1] / 2],
                        [-LENS_STOP_SIZE[0] / 2, LENS_STOP_SIZE[1] / 2],
                        [LENS_STOP_SIZE[0] / 2, -LENS_STOP_SIZE[1] / 2],
                        [LENS_STOP_SIZE[0] / 2, LENS_STOP_SIZE[1] / 2]]
                     : [for (i = [0 : LENS_STOP_ANGLE_SAMPLES - 1])
                        [LENS_STOP_SIZE[0] / 2
                         * cos(i * 360 / LENS_STOP_ANGLE_SAMPLES),
                         LENS_STOP_SIZE[1] / 2
                         * sin(i * 360 / LENS_STOP_ANGLE_SAMPLES)]];
COMBINER_FIELD_SAMPLES =
    [for (stop_point = LENS_STOP_BOUNDARY)
     for (field_h = [-DISPLAY_FIELD_SLOPE, DISPLAY_FIELD_SLOPE])
     for (field_v = [-DISPLAY_FIELD_SLOPE_V, DISPLAY_FIELD_SLOPE_V])
     let(path = (LENS_TO_COMBINER - stop_point[0]) / (1 + field_h),
         hit_y = stop_point[0] + field_h * path,
         hit_z = stop_point[1] + field_v * path)
     [sqrt(2) * hit_y, hit_z]];
COMBINER_U_MAX = max([for (hit = COMBINER_FIELD_SAMPLES) hit[0]]);
COMBINER_U_MIN = min([for (hit = COMBINER_FIELD_SAMPLES) hit[0]]);
COMBINER_V_MAX = max([for (hit = COMBINER_FIELD_SAMPLES) hit[1]]);
COMBINER_V_MIN = min([for (hit = COMBINER_FIELD_SAMPLES) hit[1]]);
COMBINER_REQUIRED_U = COMBINER_U_MAX - COMBINER_U_MIN;
COMBINER_REQUIRED_V = COMBINER_V_MAX - COMBINER_V_MIN;
STOP_TO_PUPIL_PATH = LENS_TO_COMBINER + EYE_DATUM_DISTANCE;
COMMON_EYEBOX = [LENS_STOP_SIZE[0]
                 - 2 * STOP_TO_PUPIL_PATH * DISPLAY_FIELD_SLOPE,
                 LENS_STOP_SIZE[1]
                 - 2 * STOP_TO_PUPIL_PATH * DISPLAY_FIELD_SLOPE_V];
// Signed shift along the frame's local +X basis. It centres the asymmetric
// ray bundle in the physical 28 mm clear opening (negative for these presets).
COMBINER_AXIS_SHIFT = (COMBINER_U_MAX + COMBINER_U_MIN) / 2;
COMBINER_CENTER_X = -LENS_TO_COMBINER
                    + COMBINER_AXIS_SHIFT * cos(COMBINER_ANGLE);
COMBINER_CENTER_Y = COMBINER_AXIS_SHIFT * sin(COMBINER_ANGLE);
COMBINER_NORMAL_X = sin(COMBINER_ANGLE);
COMBINER_NORMAL_Y = -cos(COMBINER_ANGLE);
// COMBINER_CENTER is the incoming/coated pane face and modeled ray plane.
// The printable frame's local w=0 base must be shifted behind that face.
COMBINER_BASE_CENTER_X = COMBINER_CENTER_X
                         - COMBINER_REFLECT_W * COMBINER_NORMAL_X;
COMBINER_BASE_CENTER_Y = COMBINER_CENTER_Y
                         - COMBINER_REFLECT_W * COMBINER_NORMAL_Y;
COMBINER_SOCKET_CENTER_X = COMBINER_BASE_CENTER_X
                           + FRAME_STACK_T / 2 * COMBINER_NORMAL_X;
COMBINER_SOCKET_CENTER_Y = COMBINER_BASE_CENTER_Y
                           + FRAME_STACK_T / 2 * COMBINER_NORMAL_Y;

// ---------- Temple saddle / rail ----------
SADDLE = [18.0, 26.0, 5.0];  // [X width, Y length, Z height]
SADDLE_V_WIDTH = 13.0;
SADDLE_V_DEPTH = 2.4;
STRAP_WIDTH = 6.5;
STRAP_SLOT = [2.0, STRAP_WIDTH];
STRAP_STATIONS = [-7.5, 7.5];
RAIL_LENGTH = 22.0;
RAIL_BOTTOM_W = 7.5;
RAIL_TOP_W = 10.5;
RAIL_H = 3.0;
QUICK = [17.0, 24.0, 7.0];
COMPACT_CARRIAGE = [18.0, 24.0, 5.0];
HINGE_BARREL_D = 8.0;
HINGE_MOVING_W = 7.6;
HINGE_SIDE_GAP = 0.30;
HINGE_AXIS_ABOVE_CARRIAGE = 8.7;
HINGE_PARK_ANGLE = 100.0;
HINGE_KNUCKLE_W = (COMPACT_CARRIAGE[0] - HINGE_MOVING_W
                    - 2 * HINGE_SIDE_GAP) / 2;
HINGE_FIXED_INNER_X = (HINGE_MOVING_W + 2 * HINGE_SIDE_GAP) / 2;
ENGINE_CLAMP_X = 8.0;

// Paired radial stops at both travel limits. Angles are measured around the +X
// pivot from +Y toward +Z. The moving tabs begin at 100 degrees when deployed
// and rotate over the hinge onto the fixed tabs' 200-degree parked contact
// planes. Their trailing faces also meet separate fixed 100-degree faces at
// zero rotation. The path stays above the carriage body. Tabs share load on
// both hinge ends; the elastomer keeper retains each pose but defines neither
// limit.
PARK_STOP_FIXED_ANGLE = 200.0;
PARK_STOP_MOVING_ANGLE = PARK_STOP_FIXED_ANGLE - HINGE_PARK_ANGLE;
PARK_STOP_TANGENTIAL_T = 1.2;
PARK_STOP_ATTACH_R = 3.6;
PARK_STOP_CONTACT_R = 4.3;
PARK_STOP_OUTER_R = 5.6;
PARK_STOP_MOVING_ROOT_X = [2.4, 3.8];
PARK_STOP_MOVING_WING_X = [3.1, 5.6];
PARK_STOP_FIXED_SPINE_X = [4.3, 6.5];
PARK_STOP_BARREL_RADIAL_CLEAR = PARK_STOP_CONTACT_R
                                - HINGE_BARREL_D / 2;
PARK_STOP_FIXED_AXIAL_CLEAR = HINGE_FIXED_INNER_X
                              - PARK_STOP_MOVING_ROOT_X[1];
PARK_STOP_SPINE_AXIAL_CLEAR = PARK_STOP_FIXED_SPINE_X[0]
                              - HINGE_MOVING_W / 2;
PARK_STOP_BRIDGE_AXIAL_CLEAR = PARK_STOP_FIXED_SPINE_X[0]
                              - ENGINE_CLAMP_X / 2;
PARK_STOP_MOVING_ROOT_OVERLAP = PARK_STOP_MOVING_ROOT_X[1]
                                - PARK_STOP_MOVING_WING_X[0];
PARK_STOP_CONTACT_X_OVERLAP = min(PARK_STOP_MOVING_WING_X[1],
                                  PARK_STOP_FIXED_SPINE_X[1])
                              - max(PARK_STOP_MOVING_WING_X[0],
                                    PARK_STOP_FIXED_SPINE_X[0]);
PARK_STOP_CONTACT_AREA = 2 * PARK_STOP_CONTACT_X_OVERLAP
                         * (PARK_STOP_OUTER_R - PARK_STOP_CONTACT_R);
PARK_STOP_SWEEP_SAMPLES = 200;
PARK_STOP_SWEEP_ALLOWANCE = 0.02;
HINGE_BRIDGE_POCKET_X = ENGINE_CLAMP_X + 2 * FIT;
HINGE_BRIDGE_POCKET_Y0 = 6.5;
HINGE_BRIDGE_POCKET_Z0 = RAIL_H + FIT;
function park_stop_moving_body_clear(rotation) =
    let(angle = PARK_STOP_MOVING_ANGLE + rotation,
        radial_z = min(PARK_STOP_ATTACH_R * sin(angle),
                       PARK_STOP_OUTER_R * sin(angle)),
        tangent_z = min(-PARK_STOP_TANGENTIAL_T * cos(angle), 0))
    HINGE_AXIS_ABOVE_CARRIAGE + radial_z + tangent_z
    - COMPACT_CARRIAGE[2];
PARK_STOP_MIN_SWEEP_BODY_CLEAR =
    min([for (i = [0 : PARK_STOP_SWEEP_SAMPLES])
         park_stop_moving_body_clear(
             HINGE_PARK_ANGLE * i / PARK_STOP_SWEEP_SAMPLES)])
    - PARK_STOP_SWEEP_ALLOWANCE;
PARK_STOP_FIXED_BODY_CLEAR = HINGE_AXIS_ABOVE_CARRIAGE
                             + min(PARK_STOP_ATTACH_R
                                   * sin(PARK_STOP_FIXED_ANGLE),
                                   PARK_STOP_OUTER_R
                                   * sin(PARK_STOP_FIXED_ANGLE))
                             + min(0, PARK_STOP_TANGENTIAL_T
                                      * cos(PARK_STOP_FIXED_ANGLE))
                             - COMPACT_CARRIAGE[2];
DEPLOYED_STOP_FIXED_ANGLE = PARK_STOP_MOVING_ANGLE;
DEPLOYED_STOP_FIXED_TANGENT = [-2 * PARK_STOP_TANGENTIAL_T,
                               -PARK_STOP_TANGENTIAL_T];
DEPLOYED_STOP_MOVING_TANGENT = [-PARK_STOP_TANGENTIAL_T, 0];
DEPLOYED_STOP_PLANE_GAP = DEPLOYED_STOP_MOVING_TANGENT[0]
                          - DEPLOYED_STOP_FIXED_TANGENT[1];
DEPLOYED_STOP_CONTACT_AREA = PARK_STOP_CONTACT_AREA;
DEPLOYED_STOP_FIXED_BODY_CLEAR = HINGE_AXIS_ABOVE_CARRIAGE
    + min(PARK_STOP_ATTACH_R * sin(DEPLOYED_STOP_FIXED_ANGLE),
          PARK_STOP_OUTER_R * sin(DEPLOYED_STOP_FIXED_ANGLE))
    + min(DEPLOYED_STOP_FIXED_TANGENT[0]
          * cos(DEPLOYED_STOP_FIXED_ANGLE),
          DEPLOYED_STOP_FIXED_TANGENT[1]
          * cos(DEPLOYED_STOP_FIXED_ANGLE))
    - COMPACT_CARRIAGE[2];

// ---------- Rear pod ----------
// Reference protected cell: PKCELL LP503035 maximum 31 x 38 x 5.3 mm.
// Reference controller: XIAO ESP32-C3 approximately 17.8 x 21 mm. The cavity
// leaves a 3 mm wiring/antenna gap between their end-to-end envelopes.
REAR_CELL = [31.0, 38.0, 5.3];
REAR_MCU = [17.8, 21.0, 4.2]; // maximum assembled board/connector envelope
REAR_INNER = [33.5, 64.0, 9.5];
REAR_FLOOR = 1.4;
REAR_OUTER = [REAR_INNER[0] + 2 * WALL,
              REAR_INNER[1] + 2 * WALL,
              REAR_INNER[2] + REAR_FLOOR + 1.0];
REAR_RADIUS = 3.0;
REAR_LID_T = 1.6;
REAR_LIP_H = 1.2;
REAR_STRAP_Y = 16.0;
REAR_TAB_OVERLAP = 0.8;
REAR_LID_EAR_D = 6.0;
REAR_LID_BOSS_X = REAR_OUTER[0] / 2
                  + REAR_LID_EAR_D / 2 - REAR_TAB_OVERLAP;
REAR_USB_CUTOUT = [11.0, 5.5];
REAR_SWITCH_CUTOUT = [8.0, 3.5];
REAR_CABLE_CUTOUT = [4.5, 3.5];
REAR_CELL_CENTER_Y = -12.0;
REAR_MCU_CENTER_Y = 20.5;
REAR_CELL_PAD_CLEAR = 0.6;     // per side, filled with soft closed-cell foam
REAR_MCU_CLEAR = 0.35;
REAR_USER_BUTTON = [6.2, 6.2, 4.0];
REAR_USER_BUTTON_CENTER = [12.3, 12.0];
REAR_USER_BUTTON_HOLE_D = 3.5;
REAR_USER_BUTTON_STEM_H = 2.5; // actuator above case; long-stem switch required
REAR_BUTTON_AXIAL_CLEAR = 0.15;
REAR_BUTTON_RETAINER_T = 0.80;
REAR_BUTTON_LEDGE_T = 0.85;
REAR_BUTTON_LEDGE_W = 1.20;
REAR_BUTTON_RETAINER_CLEAR = 0.10;
REAR_BUTTON_RETAINER_TAB = 3.0;
REAR_BUTTON_RETAINER_SLOT = [3.0, 3.6];
REAR_BUTTON_RETAINER_BODY = [REAR_USER_BUTTON[0] + 2 * FIT
                             - REAR_BUTTON_RETAINER_CLEAR,
                             REAR_USER_BUTTON[1] + 2 * FIT
                             - REAR_BUTTON_RETAINER_CLEAR];
REAR_BUTTON_SIDE_BEARING = (REAR_BUTTON_RETAINER_BODY[0]
                            - REAR_BUTTON_RETAINER_SLOT[0]) / 2;
REAR_BUTTON_REAR_BEARING = (REAR_BUTTON_RETAINER_BODY[1]
                            - REAR_BUTTON_RETAINER_SLOT[1]) / 2;
REAR_BUTTON_CAGE_H = REAR_USER_BUTTON[2] + REAR_BUTTON_AXIAL_CLEAR
                     + REAR_BUTTON_RETAINER_T + REAR_BUTTON_LEDGE_T;
REAR_ANTENNA = [18.0, 8.0, 1.0]; // provisional XIAO-supplied FPC; measure it
REAR_ANTENNA_CENTER = [0.0, 25.0];

// ---------- Split-pod walking experiment ----------
// Keep the XIAO/button/antenna beside the OLED so I2C remains short; carry only
// protected 1S battery power through the tested breakaway to the body pod.
CTRL_INNER = [20.5, 29.0, 7.4];
CTRL_FLOOR = 1.2;
CTRL_OUTER = [CTRL_INNER[0] + 2 * WALL,
              CTRL_INNER[1] + 2 * WALL,
              CTRL_INNER[2] + CTRL_FLOOR + 0.8];
CTRL_RADIUS = 2.5;
CTRL_LID_T = 1.4;
CTRL_LIP_H = 1.0;
CTRL_LID_EAR_D = 5.5;
CTRL_LID_BOSS_X = CTRL_OUTER[0] / 2 + CTRL_LID_EAR_D / 2 - 0.8;
CTRL_STRAP_Y = 8.0;
CTRL_MCU_CENTER_Y = -2.5;
CTRL_BUTTON_CENTER = [6.4, 9.5];
CTRL_ANTENNA_CENTER = [0.0, -7.5];
CTRL_CABLE_CUTOUT = [6.0, 4.0];

BODY_CELL_INNER = [33.5, 40.5, 8.0];
BODY_CELL_FLOOR = 1.4;
BODY_CELL_OUTER = [BODY_CELL_INNER[0] + 2 * WALL,
                   BODY_CELL_INNER[1] + 2 * WALL,
                   BODY_CELL_INNER[2] + BODY_CELL_FLOOR + 0.8];
BODY_CELL_RADIUS = 3.0;
BODY_CELL_LID_T = 1.6;
BODY_CELL_LIP_H = 1.2;
BODY_CELL_LID_EAR_D = 6.0;
BODY_CELL_LID_BOSS_X = BODY_CELL_OUTER[0] / 2
                       + BODY_CELL_LID_EAR_D / 2 - 0.8;
BODY_CELL_SWITCH_CUTOUT = [8.0, 3.5];
BODY_CELL_CABLE_CUTOUT = [5.0, 4.0];
BODY_CLIP = [18.0, 30.0, 2.2];

// ---------- Wearable optical-engine brackets ----------
ENGINE_CLAMP_INNER = [TUNNEL_BODY_OUTER[0] + 2 * FIT,
                      TUNNEL_BODY_OUTER[1] + 2 * FIT];
ENGINE_CLAMP_OUTER = [ENGINE_CLAMP_INNER[0] + 2 * WALL,
                      ENGINE_CLAMP_INNER[1] + 2 * WALL];
ENGINE_FLANGE_W = 5.5;
ENGINE_FLANGE_Y = ENGINE_CLAMP_OUTER[0] / 2
                  + ENGINE_FLANGE_W / 2 - 0.8;
ENGINE_PAD = [20.0, 20.0, 3.0];
ENGINE_OFFSET_Y = -28.0;       // moves the saddle behind the forward projector
ENGINE_PAD_Z0 = ENGINE_CLAMP_OUTER[1] / 2 - 1.5;
ENGINE_HINGE_Z = ENGINE_CLAMP_OUTER[1] / 2 + HINGE_BARREL_D / 2 - 0.30;
ENGINE_SEAM_GAP = 0.15;
BRACKET_PLATE_T = 2.4;
COMBINER_SOCKET_DEPTH = 1.5;
COMBINER_SOCKET_BASE_T = 3.0;
BRACKET_SOCKET_LENGTH = FRAME_OUTER[0];
BRACKET_SOCKET_WIDTH = 6.3;
COMBINER_CAPTURE_BOSS_D = 8.0;
COMBINER_CAPTURE_BOSS_T = 3.0;
FRAME_UPPER_BOLT_L = 10.0;
FRAME_LOWER_BOLT_L = 12.0;
FRAME_UPPER_REQUIRED_L = FRAME_STACK_T + M2_WASHER_T + M2_NYLOC_H
                         + M2_THREAD_PROTRUSION;
FRAME_LOWER_REQUIRED_L = FRAME_STACK_T + COMBINER_CAPTURE_BOSS_T
                         + M2_WASHER_T + M2_NYLOC_H
                         + M2_THREAD_PROTRUSION;

// ---------- Bench jig ----------
FOLD_GAP = LENS_TO_COMBINER;
BENCH_BASE_T = 3.0;
BENCH_SLOT_DEPTH = 1.5;
BENCH_AXIS_Z = BENCH_BASE_T - BENCH_SLOT_DEPTH + FRAME_LOWEST_V;
BENCH_FRAME_SUPPORT_H = BENCH_AXIS_Z - FRAME_OUTER[1] / 2 - BENCH_BASE_T;
WEARABLE_ENGINE_Y = 32.0;
PRESCRIPTION_LENS_Y = 14.0;
PRESCRIPTION_LENS_T = 1.5;
BRACKET_SOCKET_MIN_Y = COMBINER_SOCKET_CENTER_Y
                       - BRACKET_SOCKET_LENGTH / 2
                         * abs(sin(COMBINER_ANGLE))
                       - BRACKET_SOCKET_WIDTH / 2
                         * abs(cos(COMBINER_ANGLE));
BRACKET_SUPPORT_MIN_Y = min(-4.0, COMBINER_SOCKET_CENTER_Y - 4.0);
BRACKET_CAPTURE_MIN_Y = COMBINER_BASE_CENTER_Y
                        - COMBINER_CAPTURE_BOSS_D / 2
                        - COMBINER_CAPTURE_BOSS_T;
BRACKET_LOCAL_MIN_Y = min([-TUNNEL_OUTER / 2,
                           BRACKET_SOCKET_MIN_Y,
                           BRACKET_SUPPORT_MIN_Y,
                           BRACKET_CAPTURE_MIN_Y]);

assert(LENS_STOP_MAX_R <= LENS_D / 2,
       "Aperture-stop boundary cannot exceed the physical lens radius");
assert(LENS_FRONT_SAG > 0 && LENS_REAR_SAG > 0
       && LENS_FRONT_SAG < LENS_D / 2 && LENS_REAR_SAG < LENS_D / 2,
       "Enter positive, separately measured front/rear lens crown heights");
assert(abs(LENS_EDGE_T + LENS_FRONT_SAG + LENS_REAR_SAG
           - LENS_CENTER_T) <= LENS_MEASUREMENT_CLOSURE_TOL,
       str("Measured edge + front sag + rear sag does not close to measured ",
           "centre thickness within ", LENS_MEASUREMENT_CLOSURE_TOL, " mm"));
assert(LENS_PRINCIPAL_FROM_FRONT_RIM >= 0
       && LENS_PRINCIPAL_FROM_FRONT_RIM <= LENS_EDGE_T,
       "Provisional packaging datum must lie within the measured rim thickness");
assert(min(lens_min_hard_gap(LENS_RETAINER_T),
           lens_min_hard_gap(BRACKET_PLATE_T)) >= 0.6,
       str("Hard aperture-stop gap below 0.6 mm; retainer=",
           lens_min_hard_gap(LENS_RETAINER_T), " mm, bracket=",
           lens_min_hard_gap(BRACKET_PLATE_T), " mm"));
assert(LENS_RETAINER_T >= LENS_PAD_GAP + 0.5
       && BRACKET_PLATE_T >= LENS_PAD_GAP + 0.5,
       "Front plates need taper length plus exposed compliant-pad relief");
assert(lens_preset == "budget_25x45" || lens_preset == "compact_23x30",
       str("Unknown lens_preset: ", lens_preset));
assert(wear_pose == "deployed" || wear_pose == "parked",
       str("Unknown wear_pose: ", wear_pose));
assert(FOCUS_MIN < FOCUS_NOMINAL && FOCUS_NOMINAL < FOCUS_MAX,
       "FOCUS_NOMINAL must lie inside the focus travel");
assert(COMBINER_CLEAR[0] <= COMBINER_PANE[0]
       && COMBINER_CLEAR[1] <= COMBINER_PANE[1],
       "Combiner clear aperture must fit the physical pane");
assert(!LENS_STOP_RECTANGULAR || min(COMMON_EYEBOX) >= 6.0,
       str("Budget full-field common eye box is below 6 x 6 mm: ",
           COMMON_EYEBOX));
assert(COMBINER_REQUIRED_U <= COMBINER_CLEAR[0] - 1.0
       && COMBINER_REQUIRED_V <= COMBINER_CLEAR[1] - 1.0,
       str("Sampled field corners clip the combiner: required ",
           COMBINER_REQUIRED_U, " x ", COMBINER_REQUIRED_V,
           " mm, clear ", COMBINER_CLEAR,
           " with 0.5 mm minimum edge margin"));
assert(abs(COMBINER_PANE[0] - COMBINER_PANE[1]) < EPS,
       "The one-piece edge liner currently requires a square combiner pane");
assert(PANE_LOCATOR_GAP >= COMBINER_PANE[0]
                          + 2 * (COMBINER_EDGE_LINER_T
                                 + COMBINER_EDGE_LINER_CLEAR),
       "Rigid locator cavity cannot fit the defined soft perimeter liner");
assert(abs(COMBINER_EDGE_LINER_FITTED_OUTER
           + 2 * COMBINER_EDGE_LINER_CLEAR - PANE_LOCATOR_GAP) < EPS,
       "Fitted liner envelope and rigid locator clearance are inconsistent");
assert(COMBINER_PANE[2] - 2 * COMBINER_EDGE_LINER_FACE_RECESS > 0.4,
       "Edge liner face recess leaves no printable soft collar height");
assert(COMBINER_RAIL_BASE_BEARING >= 0.8,
       "Rigid locator rails have too little bearing on the frame base");
assert(PANE_WORST_LATERAL_PLAY >= COMBINER_EDGE_LINER_CLEAR,
       "Worst-case pane play must include nominal liner-to-rail clearance");
assert(FRAME_WORST_GLASS_GAP >= FRAME_REQUIRED_GLASS_GAP,
       "Worst-case fastener envelope is too close to the glass edge");
assert(FRAME_WORST_LINER_GAP >= FRAME_REQUIRED_LINER_GAP,
       "Worst-case fastener envelope can pinch the soft edge liner");
assert(COMBINER_U_MIN >= COMBINER_AXIS_SHIFT
                         - COMBINER_CLEAR[0] / 2 + 0.5,
       str("Modeled negative field edge clips: ", COMBINER_U_MIN));
assert(COMBINER_U_MAX <= COMBINER_AXIS_SHIFT
                         + COMBINER_CLEAR[0] / 2 - 0.5,
       str("Modeled positive field edge clips: ", COMBINER_U_MAX));
assert(abs((COMBINER_BASE_CENTER_X - COMBINER_CENTER_X)
           * COMBINER_NORMAL_X
           + (COMBINER_BASE_CENTER_Y - COMBINER_CENTER_Y)
           * COMBINER_NORMAL_Y + COMBINER_REFLECT_W) < 0.001,
       "Coated pane face must coincide with the modeled chief-ray plane");
assert(abs((COMBINER_SOCKET_CENTER_X - COMBINER_BASE_CENTER_X)
           * COMBINER_NORMAL_X
           + (COMBINER_SOCKET_CENTER_Y - COMBINER_BASE_CENTER_Y)
           * COMBINER_NORMAL_Y - FRAME_STACK_T / 2) < 0.001,
       "Bracket socket must be centred on the physical frame stack");
assert(TUNNEL_BODY_INNER[0] > OLED_CART_Y
       && TUNNEL_BODY_INNER[1] > OLED_CART_Z,
       "Keyed OLED cartridge does not fit inside the tunnel body");
assert(OLED_LOCK_Z - M25_CLEAR_D / 2
       >= OLED_PCB[2] / 2 + FIT + 0.75,
       "Focus bolt has too little solid guide below it");
assert(OLED_CART_Z / 2 - (OLED_LOCK_Z + M25_CLEAR_D / 2) >= 1.0,
       "Focus bolt has too little cartridge wall above it");
assert(TUNNEL_NECK_X < FOCUS_SLOT_X0,
       "Tunnel transition must finish before the focus-lock slot");
assert(HINGE_KNUCKLE_W >= 4.5,
       "Compact carriage hinge knuckles are too narrow");
assert(abs(PARK_STOP_MOVING_ANGLE + HINGE_PARK_ANGLE
           - PARK_STOP_FIXED_ANGLE) < EPS,
       "Moving and fixed parked-stop planes do not meet at the parked angle");
assert(PARK_STOP_BARREL_RADIAL_CLEAR >= FIT,
       "Parked-stop tongue has too little radial clearance to moving barrel");
assert(PARK_STOP_FIXED_AXIAL_CLEAR >= FIT,
       "Moving parked-stop tab has too little clearance to fixed knuckle");
assert(PARK_STOP_SPINE_AXIAL_CLEAR >= FIT,
       "Fixed parked-stop spine has too little clearance to moving barrel");
assert(PARK_STOP_BRIDGE_AXIAL_CLEAR >= FIT,
       "Fixed stop spine has too little clearance to moving bridge");
assert(PARK_STOP_MOVING_ROOT_OVERLAP >= 0.6,
       "Moving stop wing-to-root neck is too thin to print reliably");
assert(PARK_STOP_CONTACT_X_OVERLAP >= 1.0
       && PARK_STOP_CONTACT_AREA >= 3.0,
       "Paired parked-stop contact faces are too small");
assert(abs(DEPLOYED_STOP_FIXED_ANGLE - PARK_STOP_MOVING_ANGLE) < EPS
       && abs(DEPLOYED_STOP_PLANE_GAP) < EPS,
       "Moving and fixed deployed-stop planes do not meet at zero degrees");
assert(DEPLOYED_STOP_CONTACT_AREA >= 3.0,
       "Paired deployed-stop contact faces are too small");
assert(PARK_STOP_MIN_SWEEP_BODY_CLEAR >= 1.0,
       "Moving parked-stop tabs collide with carriage body during hinge sweep");
assert(PARK_STOP_FIXED_BODY_CLEAR >= 0.5,
       "Fixed parked-stop tabs collide with carriage body");
assert(DEPLOYED_STOP_FIXED_BODY_CLEAR >= 0.5,
       "Fixed deployed-stop tabs collide with carriage body");
assert((COMPACT_CARRIAGE[0] - HINGE_BRIDGE_POCKET_X) / 2 >= 4.5
       && HINGE_BRIDGE_POCKET_Y0 < COMPACT_CARRIAGE[1] / 2,
       "Deployed bridge pocket leaves too little carriage side wall");
assert(REAR_INNER[0] > 0 && REAR_INNER[1] > 0 && REAR_INNER[2] > 0,
       "Rear pod cavity dimensions must be positive");
assert(REAR_INNER[0] >= REAR_CELL[0] + 2 * FIT
       && REAR_INNER[1] >= REAR_CELL[1] + REAR_MCU[1] + 3.0
       && REAR_INNER[2] >= max(REAR_CELL[2], REAR_MCU[2]) + 1.0,
       "Rear cavity cannot fit the reference cell, controller, and wiring gap");
assert(REAR_MCU_CENTER_Y - REAR_MCU[1] / 2
       - (REAR_CELL_CENTER_Y + REAR_CELL[1] / 2) >= 3.0,
       "Rear pod needs at least 3 mm between cell and controller envelopes");
assert(REAR_INNER[0] >= REAR_CELL[0] + 2 * REAR_CELL_PAD_CLEAR,
       "Rear pod battery pocket has no allowance for soft padding");
assert(REAR_USER_BUTTON_CENTER[0] - REAR_USER_BUTTON[0] / 2
       >= REAR_MCU[0] / 2 + 0.2,
       "Lid-mounted user button overlaps the XIAO board envelope");
assert(REAR_USER_BUTTON_CENTER[0] + REAR_USER_BUTTON[0] / 2 + FIT
       <= REAR_INNER[0] / 2,
       "Lid-mounted user button does not fit the pod cavity");
assert(REAR_USER_BUTTON_STEM_H >= REAR_LID_T + 0.6,
       "BTN1 needs a long stem that remains finger-accessible above the lid");
assert(REAR_OUTER[2] - REAR_BUTTON_CAGE_H
       - (REAR_FLOOR + REAR_MCU[2]) >= 0.5,
       "Button reaction cage needs 0.5 mm above the controller envelope");
assert(REAR_BUTTON_RETAINER_SLOT[0] < REAR_USER_BUTTON[0]
       && REAR_BUTTON_RETAINER_SLOT[1] < REAR_USER_BUTTON[1],
       "Button retainer wire slot leaves no reaction perimeter");
assert(REAR_BUTTON_SIDE_BEARING >= 1.0
       && REAR_BUTTON_REAR_BEARING >= 1.0,
       "Button retainer needs at least 1 mm bearing around its open wire slot");
assert(REAR_BUTTON_LEDGE_T >= 0.8 && REAR_BUTTON_LEDGE_W >= 1.0,
       "Button reaction ledges are too small for repeated actuation");
assert(REAR_ANTENNA_CENTER[1] - REAR_ANTENNA[1] / 2
       - (REAR_USER_BUTTON_CENTER[1] + REAR_USER_BUTTON[1] / 2) >= 5.0,
       "Keep at least 5 mm between the metal user button and FPC antenna");
assert(CTRL_INNER[0] >= REAR_MCU[0] + 2 * REAR_MCU_CLEAR
       && CTRL_INNER[1] >= REAR_MCU[1] + REAR_USER_BUTTON[1] + 1.0
       && CTRL_INNER[2] >= REAR_MCU[2] + 1.0,
       "Controller pod cannot fit XIAO, button, and wiring clearance");
assert(BODY_CELL_INNER[0] >= REAR_CELL[0] + 2 * REAR_CELL_PAD_CLEAR
       && BODY_CELL_INNER[1] >= REAR_CELL[1] + 2 * REAR_CELL_PAD_CLEAR
       && BODY_CELL_INNER[2] >= REAR_CELL[2] + 1.0,
       "Body battery pod cannot fit the protected cell and padding");
assert(WEARABLE_ENGINE_Y - TUNNEL_OUTER / 2
       - (PRESCRIPTION_LENS_Y + PRESCRIPTION_LENS_T / 2) >= 2.5,
       "Wearable preview needs 2.5 mm prescription-lens clearance");
assert(WEARABLE_ENGINE_Y + COMBINER_BASE_CENTER_Y
       + FRAME_MIN_U * sin(COMBINER_ANGLE)
       - FRAME_STACK_T * cos(COMBINER_ANGLE)
       - (PRESCRIPTION_LENS_Y + PRESCRIPTION_LENS_T / 2) >= 2.5,
       "Complete combiner ring/stack needs 2.5 mm prescription clearance");
assert(BRACKET_SOCKET_WIDTH >= FRAME_STACK_T + PANE_SLOT_CLEAR + 1.6,
       "Bracket socket needs at least two 0.4 mm walls beside its slot");
assert(FRAME_UPPER_BOLT_L >= FRAME_UPPER_REQUIRED_L,
       "Upper combiner bolt cannot engage an ordinary M2 nyloc plus two threads");
assert(FRAME_LOWER_BOLT_L >= FRAME_LOWER_REQUIRED_L,
       "Lower combiner bolt cannot engage an ordinary M2 nyloc plus two threads");
assert(BENCH_FRAME_SUPPORT_H > 0,
       "Bench ring supports must rise above the base");
assert(WEARABLE_ENGINE_Y + BRACKET_LOCAL_MIN_Y
       - (PRESCRIPTION_LENS_Y + PRESCRIPTION_LENS_T / 2) >= 2.5,
       "Complete combiner bracket envelope needs 2.5 mm prescription clearance");

// ---------- General helpers ----------

module rounded_rect_2d(size, radius) {
    offset(r = radius)
        square([size[0] - 2 * radius, size[1] - 2 * radius], center = true);
}

module rounded_box_xy(size, radius) {
    linear_extrude(height = size[2])
        rounded_rect_2d([size[0], size[1]], radius);
}

module x_cylinder(d, h, center = false) {
    rotate([0, 90, 0]) cylinder(d = d, h = h, center = center);
}

module y_cylinder(d, h, center = false) {
    rotate([90, 0, 0]) cylinder(d = d, h = h, center = center);
}

module hinge_radial_tab(angle, x_range, radial_range, tangent_range) {
    rotate([angle, 0, 0])
        translate([x_range[0], radial_range[0], tangent_range[0]])
            cube([x_range[1] - x_range[0],
                  radial_range[1] - radial_range[0],
                  tangent_range[1] - tangent_range[0]]);
}

module segment(a, b, d = 0.35) {
    hull() {
        translate(a) sphere(d = d, $fn = 16);
        translate(b) sphere(d = d, $fn = 16);
    }
}

module prism_along_y(points, length) {
    rotate([90, 0, 0])
        linear_extrude(height = length, center = true)
            polygon(points = points);
}

module dovetail_male(length = RAIL_LENGTH) {
    prism_along_y([
        [-RAIL_BOTTOM_W / 2, 0],
        [ RAIL_BOTTOM_W / 2, 0],
        [ RAIL_TOP_W / 2, RAIL_H],
        [-RAIL_TOP_W / 2, RAIL_H]
    ], length);
}

module dovetail_void(length = QUICK[1] + 2 * EPS) {
    prism_along_y([
        [-(RAIL_BOTTOM_W / 2 + FIT), -EPS],
        [ (RAIL_BOTTOM_W / 2 + FIT), -EPS],
        [ (RAIL_TOP_W / 2 + FIT), RAIL_H + FIT],
        [-(RAIL_TOP_W / 2 + FIT), RAIL_H + FIT]
    ], length);
}

module frame_ring_2d() {
    difference() {
        square(FRAME_OUTER, center = true);
        square(COMBINER_CLEAR, center = true);
    }
}

module frame_ears_2d() {
    // Symmetric top/bottom fasteners distribute gasket pressure. Their local
    // V direction maps vertically, avoiding the prescription-lens envelope.
    for (sy = [-1, 1])
        translate([0, sy * FRAME_EAR_X]) circle(d = FRAME_EAR_D);
}

// ---------- Optical parts ----------

module oled_focus_cartridge() {
    difference() {
        translate([0, -OLED_CART_Y / 2, -OLED_CART_Z / 2])
            cube([OLED_CART_DEPTH, OLED_CART_Y, OLED_CART_Z]);

        // Open-backed PCB pocket; use thin foam or Kapton for retention.
        translate([WALL, -(OLED_PCB[1] / 2 + FIT),
                   -(OLED_PCB[2] / 2 + FIT)])
            cube([OLED_CART_DEPTH + EPS,
                  OLED_PCB[1] + 2 * FIT,
                  OLED_PCB[2] + 2 * FIT]);

        // Optical window in the front bezel.
        translate([-EPS,
                   OLED_WINDOW_OFFSET[0] - OLED_WINDOW[0] / 2,
                   OLED_WINDOW_OFFSET[1] - OLED_WINDOW[1] / 2])
            cube([WALL + 2 * EPS, OLED_WINDOW[0], OLED_WINDOW[1]]);

        // Cable relief at the upper rear edge.
        translate([OLED_CART_DEPTH - 2.2,
                   OLED_CART_Y / 2 - 5.6,
                   -OLED_CART_Z / 2 - EPS])
            cube([2.2 + EPS, 5.6, 4.8]);

        // Through-bolt crosses the solid guide above the OLED glass.
        translate([OLED_LOCK_X, 0, OLED_LOCK_Z])
            y_cylinder(M25_CLEAR_D, OLED_CART_Y + 4, center = true);
    }
}

module focus_slot() {
    hull() {
        translate([FOCUS_SLOT_X0, 0, OLED_LOCK_Z])
            y_cylinder(M25_CLEAR_D, TUNNEL_BODY_OUTER[0] + 2,
                       center = true);
        translate([FOCUS_SLOT_X1, 0, OLED_LOCK_Z])
            y_cylinder(M25_CLEAR_D, TUNNEL_BODY_OUTER[0] + 2,
                       center = true);
    }
}

module lens_front_relief(x0, thickness) {
    transition_h = thickness - LENS_PAD_GAP - LENS_FRONT_PAD_LENGTH;
    // The budget void lofts from the 16 x 14 rectangular field stop to the
    // round lens pocket. Keeping the rectangular stop preserves the common
    // pupil-box corners that a circular stop discards. The compact experiment
    // retains its original circular cone. The final cylindrical counterbore
    // prevents hard contact with the biconvex surface.
    if (LENS_STOP_RECTANGULAR) {
        hull() {
            // After this rotation, 2-D [x,y] maps to global [-Z,+Y], so pass
            // [stop height, stop width] to obtain global [Y,Z] = [16,14].
            translate([x0 - EPS, 0, 0])
                rotate([0, 90, 0])
                    linear_extrude(height = 2 * EPS)
                        square([LENS_STOP_SIZE[1], LENS_STOP_SIZE[0]],
                               center = true);
            translate([x0 + transition_h - EPS, 0, 0])
                x_cylinder(LENS_D + LENS_POCKET_DIAMETRAL_CLEAR,
                           2 * EPS);
        }
    } else {
        translate([x0 - EPS, 0, 0])
            rotate([0, 90, 0])
                cylinder(d1 = LENS_STOP_SIZE[0],
                         d2 = LENS_D + LENS_POCKET_DIAMETRAL_CLEAR,
                         h = transition_h + EPS);
    }
    translate([x0 + transition_h - EPS, 0, 0])
        x_cylinder(LENS_D + LENS_POCKET_DIAMETRAL_CLEAR,
                   LENS_PAD_GAP + LENS_FRONT_PAD_LENGTH + 2 * EPS);
}

module lens_front_pads(x0, thickness) {
    // Three printed lands stop short of the lens. Builder-applied compliant
    // dots bridge LENS_PAD_GAP and touch only the outermost rim.
    pad_x0 = x0 + thickness - LENS_PAD_GAP - LENS_FRONT_PAD_LENGTH;
    for (angle = [0, 120, 240])
        translate([pad_x0,
                   LENS_PAD_R * cos(angle),
                   LENS_PAD_R * sin(angle)])
            x_cylinder(LENS_PAD_D, LENS_FRONT_PAD_LENGTH);
}

module lens_rear_pads() {
    for (angle = [0, 120, 240])
        translate([LENS_REAR_PAD_X,
                   LENS_PAD_R * cos(angle),
                   LENS_PAD_R * sin(angle)])
            x_cylinder(LENS_PAD_D, 0.5);
}

module lens_tunnel() {
    pocket_d = LENS_D + LENS_POCKET_DIAMETRAL_CLEAR;
    screw_c = TUNNEL_OUTER / 2 - 2.25;

    union() {
        difference() {
            union() {
                // Full square lens cell and front fastener pilots.
                translate([0, -TUNNEL_OUTER / 2, -TUNNEL_OUTER / 2])
                    cube([TUNNEL_SHOULDER_X,
                          TUNNEL_OUTER, TUNNEL_OUTER]);
                // Five-millimetre keyed transition into the close-fitting
                // rectangular OLED guide. The taper keeps the lens end flat
                // on the print bed and removes the old full-length box bulk.
                hull() {
                    translate([TUNNEL_SHOULDER_X - EPS,
                               -TUNNEL_OUTER / 2, -TUNNEL_OUTER / 2])
                        cube([2 * EPS, TUNNEL_OUTER, TUNNEL_OUTER]);
                    translate([TUNNEL_NECK_X - EPS,
                               -TUNNEL_BODY_OUTER[0] / 2,
                               -TUNNEL_BODY_OUTER[1] / 2])
                        cube([2 * EPS,
                              TUNNEL_BODY_OUTER[0],
                              TUNNEL_BODY_OUTER[1]]);
                }
                translate([TUNNEL_NECK_X,
                           -TUNNEL_BODY_OUTER[0] / 2,
                           -TUNNEL_BODY_OUTER[1] / 2])
                    cube([TUNNEL_LENGTH - TUNNEL_NECK_X,
                          TUNNEL_BODY_OUTER[0],
                          TUNNEL_BODY_OUTER[1]]);
            }

            // Full-diameter relief clears the biconvex lens and centre sag.
            // It expands into the square throat before that throat tapers to
            // the keyed body. The physical field stop remains in the separate
            // retainer/bracket, not this tunnel shell.
            translate([-EPS, 0, 0])
                x_cylinder(pocket_d, LENS_RELIEF_END_X + EPS);

            // Open square throat, matched internal transition, and keyed body.
            translate([LENS_RELIEF_END_X,
                       -TUNNEL_INNER / 2, -TUNNEL_INNER / 2])
                cube([TUNNEL_SHOULDER_X - LENS_RELIEF_END_X + EPS,
                      TUNNEL_INNER, TUNNEL_INNER]);
            hull() {
                translate([TUNNEL_SHOULDER_X - EPS,
                           -TUNNEL_INNER / 2, -TUNNEL_INNER / 2])
                    cube([2 * EPS, TUNNEL_INNER, TUNNEL_INNER]);
                translate([TUNNEL_NECK_X - EPS,
                           -TUNNEL_BODY_INNER[0] / 2,
                           -TUNNEL_BODY_INNER[1] / 2])
                    cube([2 * EPS,
                          TUNNEL_BODY_INNER[0],
                          TUNNEL_BODY_INNER[1]]);
            }
            translate([TUNNEL_NECK_X - EPS,
                       -TUNNEL_BODY_INNER[0] / 2,
                       -TUNNEL_BODY_INNER[1] / 2])
                cube([TUNNEL_LENGTH - TUNNEL_NECK_X + 2 * EPS,
                      TUNNEL_BODY_INNER[0],
                      TUNNEL_BODY_INNER[1]]);

            // A long through-bolt and washers clamp the cartridge after focus.
            focus_slot();

            // Two diagonal M2 pilots for the removable front retainer/bracket.
            for (s = [-1, 1])
                translate([-EPS, s * screw_c, s * screw_c])
                    x_cylinder(M2_PILOT_D, 8.0);
        }

        lens_rear_pads();
    }
}

module lens_retainer() {
    screw_c = TUNNEL_OUTER / 2 - 2.25;
    union() {
        difference() {
            translate([0, -TUNNEL_OUTER / 2, -TUNNEL_OUTER / 2])
                cube([LENS_RETAINER_T, TUNNEL_OUTER, TUNNEL_OUTER]);
            lens_front_relief(0, LENS_RETAINER_T);
            for (s = [-1, 1])
                translate([-EPS, s * screw_c, s * screw_c])
                    x_cylinder(M2_CLEAR_D, LENS_RETAINER_T + 2 * EPS);
        }
        lens_front_pads(0, LENS_RETAINER_T);
    }
}

module combiner_frame() {
    locator_h = COMBINER_PANE[2] + COMBINER_PANE_GAP;
    locator_w = COMBINER_LOCATOR_W;
    locator_gap = PANE_LOCATOR_GAP;
    locator_length = locator_gap + 0.2;

    difference() {
        union() {
            linear_extrude(height = COMBINER_BASE_T) {
                frame_ring_2d();
                frame_ears_2d();
            }

            // Four overlapping rails guard every sharp pane edge/corner and
            // define the clamp-stack height without touching either coating.
            for (sx = [-1, 1])
                translate([sx * (locator_gap / 2 + locator_w / 2), 0,
                           COMBINER_BASE_T + locator_h / 2])
                    cube([locator_w,
                          locator_length, locator_h],
                         center = true);
            for (sy = [-1, 1])
                translate([0, sy * (locator_gap / 2 + locator_w / 2),
                           COMBINER_BASE_T + locator_h / 2])
                    cube([locator_length, locator_w, locator_h],
                         center = true);
        }

        for (sy = [-1, 1])
            translate([0, sy * FRAME_EAR_X, -EPS])
                cylinder(d = M2_CLEAR_D,
                         h = COMBINER_BASE_T + locator_h + 2 * EPS);
    }
}

module combiner_clamp() {
    difference() {
        linear_extrude(height = COMBINER_CLAMP_T) {
            frame_ring_2d();
            frame_ears_2d();
        }
        for (sy = [-1, 1])
            translate([0, sy * FRAME_EAR_X, -EPS])
                cylinder(d = M2_CLEAR_D,
                         h = COMBINER_CLAMP_T + 2 * EPS);
    }
}

module combiner_shim() {
    // Soft TPU/foam gasket only. It sits on the pane perimeter inside the
    // locator rails and compresses from 0.30 to the nominal 0.15 mm stack gap.
    linear_extrude(height = COMBINER_SHIM_T) difference() {
        square([COMBINER_PANE[0] - 0.6,
                COMBINER_PANE[1] - 0.6], center = true);
        square([COMBINER_CLEAR[0] - 0.2,
                COMBINER_CLEAR[1] - 0.2], center = true);
    }
}

module combiner_edge_liner() {
    // One-piece soft TPU/silicone collar. The free 29.8 mm opening stretches
    // 0.1 mm per side over the pane. Its 0.8 mm free wall then occupies the
    // conservative 31.6 mm fitted envelope used by the rigid-rail asserts.
    // Face recess prevents this radial guard becoming an axial clamp land;
    // dogbone reliefs keep rounded FDM corners off sharp glass corners.
    liner_outer = [COMBINER_EDGE_LINER_FREE_OUTER,
                   COMBINER_EDGE_LINER_FREE_OUTER];
    liner_inner = [COMBINER_EDGE_LINER_FREE_INNER,
                   COMBINER_EDGE_LINER_FREE_INNER];
    liner_h = COMBINER_PANE[2] - 2 * COMBINER_EDGE_LINER_FACE_RECESS;
    linear_extrude(height = liner_h) difference() {
        square(liner_outer, center = true);
        square(liner_inner, center = true);
        for (sx = [-1, 1])
            for (sy = [-1, 1])
                translate([sx * liner_inner[0] / 2,
                           sy * liner_inner[1] / 2])
                    circle(r = COMBINER_EDGE_LINER_CORNER_RELIEF_R);
    }
}

module combiner_pane_proxy() {
    color([0.45, 0.8, 1.0, 0.28])
        translate([-COMBINER_PANE[0] / 2, -COMBINER_PANE[1] / 2, 0])
            cube(COMBINER_PANE);
}

module combiner_stack_preview(open = 0) {
    combiner_frame();
    translate([0, 0, COMBINER_BASE_T + open
                     + COMBINER_EDGE_LINER_FACE_RECESS])
        color([1.0, 0.45, 0.1, 0.8]) combiner_edge_liner();
    translate([0, 0, COMBINER_BASE_T + open]) combiner_pane_proxy();
    translate([0, 0, COMBINER_BASE_T + COMBINER_PANE[2]
                     + COMBINER_PANE_GAP + 2 * open])
        color("dimgray") combiner_clamp();
}

// ---------- Temple mounting ----------

module temple_v_groove() {
    translate([0, 0, -EPS])
        prism_along_y([
            [-SADDLE_V_WIDTH / 2, 0],
            [0, SADDLE_V_DEPTH],
            [SADDLE_V_WIDTH / 2, 0]
        ], SADDLE[1] + 2 * EPS);
}

module temple_saddle() {
    difference() {
        union() {
            translate([-SADDLE[0] / 2, -SADDLE[1] / 2, 0])
                cube(SADDLE);
            translate([0, 0, SADDLE[2]]) dovetail_male();
        }

        temple_v_groove();

        // Two independent strap stations; each band wraps around the temple.
        for (station = STRAP_STATIONS)
            for (sx = [-1, 1])
                translate([sx * 6.3 - STRAP_SLOT[0] / 2,
                           station - STRAP_SLOT[1] / 2, -EPS])
                    cube([STRAP_SLOT[0], STRAP_SLOT[1],
                          SADDLE[2] + 2 * EPS]);
    }
}

module quick_release() {
    difference() {
        translate([-QUICK[0] / 2, -QUICK[1] / 2, 0]) cube(QUICK);
        translate([0, 0, -EPS]) dovetail_void();

        // Side-access M2.5 set screw locks fore/aft position without being
        // covered by the adapter/engine stack.
        translate([RAIL_BOTTOM_W / 2 + FIT - EPS,
                   QUICK[1] / 2 - 4.0, 1.7])
            x_cylinder(M25_PILOT_D,
                       QUICK[0] / 2
                       - (RAIL_BOTTOM_W / 2 + FIT) + 2 * EPS);
        translate([QUICK[0] / 2 - 1.2,
                   QUICK[1] / 2 - 4.0, 1.7])
            x_cylinder(5.2, 1.2 + EPS);

        // Blind pilots accept two M2x5 screws from the adapter's top face;
        // they do not break into or obstruct the sliding rail channel.
        for (sx = [-1, 1])
            translate([sx * 6.0, 0, QUICK[2] - 3.5])
                cylinder(d = M2_PILOT_D, h = 3.5 + EPS);
    }
}

module compact_carriage() {
    central_gap = HINGE_MOVING_W + 2 * HINGE_SIDE_GAP;
    axis_z = HINGE_AXIS_ABOVE_CARRIAGE;
    difference() {
        union() {
            translate([-COMPACT_CARRIAGE[0] / 2,
                       -COMPACT_CARRIAGE[1] / 2, 0])
                cube(COMPACT_CARRIAGE);

            // Two fixed knuckles accept the engine clamp's central leaf. The
            // barrels overlap the body by 0.3 mm for a manifold print.
            for (sx = [-1, 1])
                translate([sx * (central_gap / 2 + HINGE_KNUCKLE_W / 2),
                           0, axis_z])
                    x_cylinder(HINGE_BARREL_D, HINGE_KNUCKLE_W,
                               center = true);

            // Twin fixed stop spines at both travel limits. Each overlaps its
            // fixed knuckle radially and starts 0.50 mm outside the moving
            // barrel. The deployed pair meets the moving wings' trailing
            // planes at 100 degrees; the parked pair meets their leading
            // radial planes at 200 degrees. Two 1.30 x 1.30 mm patches share
            // the load at each limit.
            translate([0, 0, axis_z])
                for (sx = [-1, 1])
                    scale([sx, 1, 1]) {
                        hinge_radial_tab(
                            DEPLOYED_STOP_FIXED_ANGLE,
                            PARK_STOP_FIXED_SPINE_X,
                            [PARK_STOP_ATTACH_R, PARK_STOP_OUTER_R],
                            DEPLOYED_STOP_FIXED_TANGENT);
                        hinge_radial_tab(
                            PARK_STOP_FIXED_ANGLE,
                            PARK_STOP_FIXED_SPINE_X,
                            [PARK_STOP_ATTACH_R, PARK_STOP_OUTER_R],
                            [0, PARK_STOP_TANGENTIAL_T]);
                    }

            // Outboard front/rear keeper pegs. A short silicone/TPU loop tied
            // through the moving leaf is shifted between these two pegs to
            // retain deployed and parked poses positively.
            for (sy = [-1, 1]) {
                translate([COMPACT_CARRIAGE[0] / 2 - 0.3,
                           sy * 8.0, 3.2])
                    x_cylinder(3.0, 3.0);
                translate([COMPACT_CARRIAGE[0] / 2 + 2.3,
                           sy * 8.0, 3.2])
                    x_cylinder(4.2, 0.8);
            }

            // The elastomer keeper described in the build guide pulls the
            // moving tabs against one fixed stop pair or the other; it never
            // substitutes for either hard contact plane.
        }

        translate([0, 0, -EPS]) dovetail_void(COMPACT_CARRIAGE[1] + 2 * EPS);

        // One continuous M2.5 pivot through both fixed knuckles and leaf.
        translate([-COMPACT_CARRIAGE[0] / 2 - EPS, 0, axis_z])
            x_cylinder(M25_CLEAR_D,
                       COMPACT_CARRIAGE[0] + 2 * EPS);

        // Give the moving barrel 0.35 mm below-body swing clearance.
        translate([-central_gap / 2,
                   -HINGE_BARREL_D / 2 - FIT,
                   COMPACT_CARRIAGE[2] - 0.45])
            cube([central_gap,
                  HINGE_BARREL_D + 2 * FIT,
                  1.0]);

        // The deployed bridge occupies the front/top centre of the carriage.
        // Open that roof down to the existing dovetail void so the radial stop
        // faces, rather than accidental bridge/body overlap, define 0 degrees.
        translate([-HINGE_BRIDGE_POCKET_X / 2,
                   HINGE_BRIDGE_POCKET_Y0,
                   HINGE_BRIDGE_POCKET_Z0])
            cube([HINGE_BRIDGE_POCKET_X,
                  COMPACT_CARRIAGE[1] / 2 - HINGE_BRIDGE_POCKET_Y0 + EPS,
                  COMPACT_CARRIAGE[2] - HINGE_BRIDGE_POCKET_Z0 + EPS]);

        // Side-access M2.5 set screw retains the original fore/aft rail
        // adjustment without the old cross adapter and four attachment screws.
        translate([RAIL_BOTTOM_W / 2 + FIT - EPS,
                   COMPACT_CARRIAGE[1] / 2 - 4.0, 1.7])
            x_cylinder(M25_PILOT_D,
                       COMPACT_CARRIAGE[0] / 2
                       - (RAIL_BOTTOM_W / 2 + FIT) + 2 * EPS);
        translate([COMPACT_CARRIAGE[0] / 2 - 1.2,
                   COMPACT_CARRIAGE[1] / 2 - 4.0, 1.7])
            x_cylinder(5.2, 1.2 + EPS);
    }
}

module mount_adapter() {
    size = [20.0, 20.0, 3.0];
    difference() {
        translate([-size[0] / 2, -size[1] / 2, 0]) cube(size);
        // X clearance pair screws into blind carriage pilots. Recessed heads
        // sit below the engine pad installed in the next assembly step.
        for (sx = [-1, 1])
            translate([sx * 6.0, 0, -EPS])
                cylinder(d = M2_CLEAR_D, h = size[2] + 2 * EPS);
        for (sx = [-1, 1])
            translate([sx * 6.0, 0, size[2] - 1.4])
                cylinder(d = 4.4, h = 1.4 + EPS);

        // Y pair is an undersized printed pilot for two M2x6 screws inserted
        // through the engine pad from above; no hidden nuts are required.
        for (sy = [-1, 1])
            translate([0, sy * 6.0, -EPS])
                cylinder(d = M2_PILOT_D, h = size[2] + 2 * EPS);

    }
}

module engine_square_ring() {
    difference() {
        translate([-ENGINE_CLAMP_X / 2,
                   -ENGINE_CLAMP_OUTER[0] / 2,
                   -ENGINE_CLAMP_OUTER[1] / 2])
            cube([ENGINE_CLAMP_X,
                  ENGINE_CLAMP_OUTER[0], ENGINE_CLAMP_OUTER[1]]);
        translate([-ENGINE_CLAMP_X / 2 - EPS,
                   -ENGINE_CLAMP_INNER[0] / 2,
                   -ENGINE_CLAMP_INNER[1] / 2])
            cube([ENGINE_CLAMP_X + 2 * EPS,
                  ENGINE_CLAMP_INNER[0], ENGINE_CLAMP_INNER[1]]);
    }
}

module engine_cradle() {
    difference() {
        union() {
            // Lower half of a split square collar around the light tunnel.
            intersection() {
                engine_square_ring();
                translate([-ENGINE_CLAMP_X / 2 - EPS,
                           -ENGINE_CLAMP_OUTER[0] / 2 - EPS,
                           -ENGINE_CLAMP_OUTER[1] / 2 - EPS])
                    cube([ENGINE_CLAMP_X + 2 * EPS,
                          ENGINE_CLAMP_OUTER[0] + 2 * EPS,
                          ENGINE_CLAMP_OUTER[1] / 2
                          - ENGINE_SEAM_GAP + EPS]);
            }

            // Screw flanges overlap the collar walls by 0.8 mm.
            for (sy = [-1, 1])
                translate([-ENGINE_CLAMP_X / 2,
                           sy * ENGINE_FLANGE_Y - ENGINE_FLANGE_W / 2,
                           -3.0])
                    cube([ENGINE_CLAMP_X, ENGINE_FLANGE_W,
                          3.0 - ENGINE_SEAM_GAP]);

        }

        for (sy = [-1, 1])
            translate([0, sy * ENGINE_FLANGE_Y, -3.0 - EPS])
                cylinder(d = M2_PILOT_D,
                         h = 3.0 - ENGINE_SEAM_GAP + 2 * EPS);

    }
}

module engine_clamp() {
    difference() {
        union() {
            // Upper half of the split collar.
            intersection() {
                engine_square_ring();
                translate([-ENGINE_CLAMP_X / 2 - EPS,
                           -ENGINE_CLAMP_OUTER[0] / 2 - EPS,
                           ENGINE_SEAM_GAP])
                    cube([ENGINE_CLAMP_X + 2 * EPS,
                          ENGINE_CLAMP_OUTER[0] + 2 * EPS,
                          ENGINE_CLAMP_OUTER[1] / 2
                          - ENGINE_SEAM_GAP + EPS]);
            }
            for (sy = [-1, 1])
                translate([-ENGINE_CLAMP_X / 2,
                           sy * ENGINE_FLANGE_Y - ENGINE_FLANGE_W / 2,
                           ENGINE_SEAM_GAP])
                    cube([ENGINE_CLAMP_X, ENGINE_FLANGE_W,
                          3.0 - ENGINE_SEAM_GAP]);

            // Rearward bridge terminates in the moving centre leaf of the
            // clear-away hinge. It replaces the old 20 x 20 mm pad, separate
            // cross adapter, and four pad/adapter screws.
            hull() {
                translate([-ENGINE_CLAMP_X / 2,
                           -ENGINE_CLAMP_OUTER[0] / 2,
                           ENGINE_CLAMP_OUTER[1] / 2 - 3.0])
                    cube([ENGINE_CLAMP_X, 4.0, 3.0]);
                translate([-HINGE_MOVING_W / 2,
                           ENGINE_OFFSET_Y + 2.0,
                           ENGINE_HINGE_Z - 2.0])
                    cube([HINGE_MOVING_W, 4.0, 4.0]);
            }
            translate([0, ENGINE_OFFSET_Y, ENGINE_HINGE_Z])
                x_cylinder(HINGE_BARREL_D, HINGE_MOVING_W,
                           center = true);

            // One paired set of moving root/wing tabs serves both limits. The
            // root overlaps the moving barrel but remains 0.30 mm inside the
            // fixed knuckles; the wider wing begins beyond the barrel radius.
            // At zero rotation its trailing faces contact the fixed deployed
            // spines. At +100 degrees its leading faces meet the fixed parked
            // spines. The keeper retains contact but is not the geometric stop.
            translate([0, ENGINE_OFFSET_Y, ENGINE_HINGE_Z])
                for (sx = [-1, 1])
                    scale([sx, 1, 1]) {
                        hinge_radial_tab(
                            PARK_STOP_MOVING_ANGLE,
                            PARK_STOP_MOVING_ROOT_X,
                            [PARK_STOP_ATTACH_R, PARK_STOP_OUTER_R],
                            DEPLOYED_STOP_MOVING_TANGENT);
                        hinge_radial_tab(
                            PARK_STOP_MOVING_ANGLE,
                            PARK_STOP_MOVING_WING_X,
                            [PARK_STOP_CONTACT_R, PARK_STOP_OUTER_R],
                            DEPLOYED_STOP_MOVING_TANGENT);
                    }
        }

        for (sy = [-1, 1])
            translate([0, sy * ENGINE_FLANGE_Y,
                       ENGINE_SEAM_GAP - EPS])
                cylinder(d = M2_CLEAR_D,
                         h = 3.0 - ENGINE_SEAM_GAP + 2 * EPS);

        translate([-HINGE_MOVING_W / 2 - EPS,
                   ENGINE_OFFSET_Y, ENGINE_HINGE_Z])
            x_cylinder(M25_CLEAR_D, HINGE_MOVING_W + 2 * EPS);

        // Tie the replaceable keeper loop through this protected bridge hole.
        translate([-HINGE_MOVING_W / 2 - EPS,
                   ENGINE_OFFSET_Y + 6.0, ENGINE_HINGE_Z + 1.0])
            x_cylinder(2.2, HINGE_MOVING_W + 2 * EPS);

    }
}

// Developer probe used by validate.sh. A valid 0..100 degree sweep has an
// empty volumetric intersection; one degree beyond either hard limit must
// produce a solid intersection at the paired stop faces.
module hinge_interference_probe() {
    intersection() {
        compact_carriage();
        translate([0, 0, HINGE_AXIS_ABOVE_CARRIAGE])
            rotate([hinge_probe_angle, 0, 0])
                translate([0, -ENGINE_OFFSET_Y, -ENGINE_HINGE_Z])
                    engine_clamp();
    }
}

module combiner_bracket() {
    screw_c = TUNNEL_OUTER / 2 - 2.25;
    frame_half_h = FRAME_OUTER[1] / 2;
    socket_top_z = -frame_half_h + COMBINER_SOCKET_DEPTH;
    socket_bottom_z = socket_top_z - COMBINER_SOCKET_BASE_T;
    slot_width = FRAME_STACK_T + PANE_SLOT_CLEAR;
    capture_ear = [COMBINER_BASE_CENTER_X,
                   COMBINER_BASE_CENTER_Y, -FRAME_EAR_X];
    capture_normal = [sin(COMBINER_ANGLE), -cos(COMBINER_ANGLE), 0];
    capture_center = capture_ear
                     - capture_normal * COMBINER_CAPTURE_BOSS_T / 2;

    union() {
        difference() {
            union() {
                // This plate replaces lens_retainer in the wearable assembly.
                translate([-BRACKET_PLATE_T,
                           -TUNNEL_OUTER / 2, -TUNNEL_OUTER / 2])
                    cube([BRACKET_PLATE_T, TUNNEL_OUTER, TUNNEL_OUTER]);

                // Support dives beneath the lower ear before reaching the
                // rear socket flange. Its endpoint stays behind the frame
                // plane, so the swept arm cannot intersect the glass stack.
                hull() {
                    translate([-BRACKET_PLATE_T, -3.0,
                               -TUNNEL_OUTER / 2 - 1.2])
                        cube([BRACKET_PLATE_T, 6.0, 2.4]);
                    translate([COMBINER_BASE_CENTER_X
                               - 0.5 * COMBINER_NORMAL_X,
                               COMBINER_BASE_CENTER_Y
                               - 0.5 * COMBINER_NORMAL_Y,
                               -FRAME_EAR_X - FRAME_EAR_D / 2 - 1.25])
                        rotate([0, 0, COMBINER_ANGLE])
                            cube([4.0, 1.0, 2.0], center = true);
                }

                translate([COMBINER_SOCKET_CENTER_X,
                           COMBINER_SOCKET_CENTER_Y,
                           socket_bottom_z + COMBINER_SOCKET_BASE_T / 2])
                    rotate([0, 0, COMBINER_ANGLE])
                        cube([BRACKET_SOCKET_LENGTH, BRACKET_SOCKET_WIDTH,
                              COMBINER_SOCKET_BASE_T], center = true);

                // Boss sits behind the lower frame ear. The frame cannot escape
                // the shallow socket once the M2 through-bolt/nut is fitted.
                // The boss overlaps the socket's rear flange directly. A
                // swept hull here would intrude into the assembled frame ear.
                translate(capture_center)
                    rotate([90, 0, COMBINER_ANGLE])
                        cylinder(d = COMBINER_CAPTURE_BOSS_D,
                                 h = COMBINER_CAPTURE_BOSS_T,
                                 center = true);
            }

            lens_front_relief(-BRACKET_PLATE_T, BRACKET_PLATE_T);
            for (s = [-1, 1])
                translate([-BRACKET_PLATE_T - EPS,
                           s * screw_c, s * screw_c])
                    x_cylinder(M2_CLEAR_D, BRACKET_PLATE_T + 2 * EPS);

            // Sliding socket aligns the frame; the ear bolt is the retention.
            translate([COMBINER_SOCKET_CENTER_X,
                       COMBINER_SOCKET_CENTER_Y,
                       socket_top_z - COMBINER_SOCKET_DEPTH / 2 + EPS])
                rotate([0, 0, COMBINER_ANGLE])
                    cube([FRAME_OUTER[0] + 2 * FIT, slot_width,
                          COMBINER_SOCKET_DEPTH + 2 * EPS], center = true);

            // The vertical lower ear extends beneath the ring into the socket
            // base. Clear its complete stack, not just the shallow ring slot.
            translate([COMBINER_SOCKET_CENTER_X,
                       COMBINER_SOCKET_CENTER_Y, -FRAME_EAR_X])
                rotate([90, 0, COMBINER_ANGLE])
                    cylinder(d = FRAME_EAR_D + 2 * FIT,
                             h = FRAME_STACK_T + 2 * FIT,
                             center = true, $fn = 50);

            translate(capture_center)
                rotate([90, 0, COMBINER_ANGLE])
                    cylinder(d = M2_CLEAR_D,
                             h = COMBINER_CAPTURE_BOSS_T + 2 * EPS,
                             center = true);
        }
        lens_front_pads(-BRACKET_PLATE_T, BRACKET_PLATE_T);
    }
}

// ---------- Rear battery / controller pod ----------

module rear_strap_ears() {
    ear_x = REAR_OUTER[0] / 2 + 2.8 - REAR_TAB_OVERLAP;
    for (sy = [-1, 1])
        for (sx = [-1, 1])
            translate([sx * ear_x - 2.8, sy * REAR_STRAP_Y - 4.2, 0])
                cube([5.6, 8.4, 3.0]);
}

module rear_lid_ears(height) {
    for (sx = [-1, 1])
        translate([sx * REAR_LID_BOSS_X, 0, 0])
            cylinder(d = REAR_LID_EAR_D, h = height);
}

module rear_component_guides() {
    guide_h = 2.0;
    guide_w = 1.0;
    // Rails leave a controlled gap for soft, removable pouch-cell padding.
    for (sx = [-1, 1])
        translate([sx * (REAR_CELL[0] / 2 + REAR_CELL_PAD_CLEAR
                         + guide_w / 2) - guide_w / 2,
                   REAR_CELL_CENTER_Y - (REAR_CELL[1] - 4.0) / 2,
                   REAR_FLOOR - 0.2])
            cube([guide_w, REAR_CELL[1] - 4.0, guide_h + 0.2]);
    translate([-5.0,
               REAR_CELL_CENTER_Y - REAR_CELL[1] / 2
               - REAR_CELL_PAD_CLEAR - guide_w,
               REAR_FLOOR - 0.2])
        cube([10.0, guide_w, guide_h + 0.2]);

    // XIAO rails locate the forward half; the included FPC antenna is on lid.
    for (sx = [-1, 1])
        translate([sx * (REAR_MCU[0] / 2 + REAR_MCU_CLEAR
                         + guide_w / 2) - guide_w / 2,
                   REAR_MCU_CENTER_Y - 3.0,
                   REAR_FLOOR - 0.2])
            cube([guide_w, 13.5, guide_h + 0.2]);

    // Low divider prevents the protected pouch cell sliding into the board.
    translate([-6.0, 8.2, REAR_FLOOR - 0.2])
        cube([12.0, 0.6, guide_h + 0.2]);
}

module rear_lid_accessory_guides() {
    guide_t = 0.8;
    cage_overlap = 0.25;
    antenna_guide_h = 1.0;
    button_cavity = [REAR_USER_BUTTON[0] + 2 * FIT,
                     REAR_USER_BUTTON[1] + 2 * FIT];
    button_y0 = REAR_USER_BUTTON_CENTER[1] - button_cavity[1] / 2;

    // Low rails locate (but do not crush) the supplied adhesive FPC antenna.
    // Keep the radiator against the plastic lid and secure with Kapton.
    for (sy = [-1, 1])
        translate([REAR_ANTENNA_CENTER[0] - REAR_ANTENNA[0] / 2,
                   REAR_ANTENNA_CENTER[1]
                   + sy * (REAR_ANTENNA[1] / 2 + FIT + guide_t / 2)
                   - guide_t / 2,
                   -antenna_guide_h])
            cube([REAR_ANTENNA[0], guide_t,
                  antenna_guide_h + EPS]);

    // The full-height three-sided cage locates a long-stem 6 mm tactile BTN1.
    // Two integral bottom ledges carry a removable forked retainer, so press
    // force reacts into the lid instead of adhesive tape.
    for (sx = [-1, 1])
        translate([REAR_USER_BUTTON_CENTER[0]
                   + sx * (REAR_USER_BUTTON[0] / 2 + FIT + guide_t / 2)
                   - guide_t / 2,
                   button_y0,
                   -REAR_BUTTON_CAGE_H])
            cube([guide_t, button_cavity[1],
                  REAR_BUTTON_CAGE_H + EPS]);
    translate([REAR_USER_BUTTON_CENTER[0]
               - button_cavity[0] / 2 - cage_overlap,
               button_y0 - guide_t,
               -REAR_BUTTON_CAGE_H])
        cube([button_cavity[0] + 2 * cage_overlap,
              guide_t,
              REAR_BUTTON_CAGE_H + EPS]);

    for (sx = [-1, 1])
        translate([REAR_USER_BUTTON_CENTER[0]
                   + sx * (button_cavity[0] / 2
                            - REAR_BUTTON_LEDGE_W / 2)
                   - REAR_BUTTON_LEDGE_W / 2,
                   button_y0,
                   -REAR_BUTTON_CAGE_H])
            cube([REAR_BUTTON_LEDGE_W, button_cavity[1],
                  REAR_BUTTON_LEDGE_T]);
}

module rear_button_retainer() {
    // Slide this open-ended fork under the wired switch from the cage's +Y
    // side. The central U-slot clears leads without requiring desoldering.
    retainer_w = REAR_BUTTON_RETAINER_BODY[0];
    retainer_l = REAR_BUTTON_RETAINER_BODY[1];
    slot_y0 = -REAR_BUTTON_RETAINER_SLOT[1] / 2;
    difference() {
        union() {
            translate([-retainer_w / 2, -retainer_l / 2, 0])
                cube([retainer_w, retainer_l, REAR_BUTTON_RETAINER_T]);
            translate([-retainer_w / 2, retainer_l / 2 - EPS, 0])
                cube([retainer_w, REAR_BUTTON_RETAINER_TAB + EPS,
                      REAR_BUTTON_RETAINER_T]);
        }
        translate([-REAR_BUTTON_RETAINER_SLOT[0] / 2,
                   slot_y0, -EPS])
            cube([REAR_BUTTON_RETAINER_SLOT[0],
                  retainer_l / 2 + REAR_BUTTON_RETAINER_TAB
                  - slot_y0 + 2 * EPS,
                  REAR_BUTTON_RETAINER_T + 2 * EPS]);
    }
}

module rear_pod() {
    difference() {
        union() {
            difference() {
                rounded_box_xy(REAR_OUTER, REAR_RADIUS);
                translate([0, 0, REAR_FLOOR])
                    linear_extrude(height = REAR_OUTER[2] + EPS)
                        rounded_rect_2d([REAR_INNER[0], REAR_INNER[1]],
                                        max(1.0, REAR_RADIUS - WALL));
            }

            // External bosses do not cross the battery or controller envelope.
            rear_lid_ears(REAR_OUTER[2]);
            rear_strap_ears();
            rear_component_guides();
        }

        // Lid pilots.
        for (sx = [-1, 1])
            translate([sx * REAR_LID_BOSS_X, 0, -EPS])
                cylinder(d = M2_PILOT_D,
                         h = REAR_OUTER[2] + 2 * EPS);

        // Four external strap slots keep bands away from the pouch cell.
        ear_x = REAR_OUTER[0] / 2 + 2.8 - REAR_TAB_OVERLAP;
        for (sy = [-1, 1])
            for (sx = [-1, 1])
                translate([sx * ear_x - 1.0,
                           sy * REAR_STRAP_Y - STRAP_WIDTH / 2, -EPS])
                    cube([2.0, STRAP_WIDTH, 3.0 + 2 * EPS]);

        // USB-C opening at the forward controller end.
        translate([-REAR_USB_CUTOUT[0] / 2,
                   REAR_OUTER[1] / 2 - WALL - EPS,
                   REAR_FLOOR + 0.6])
            cube([REAR_USB_CUTOUT[0], 2 * WALL + 2 * EPS,
                  REAR_USB_CUTOUT[1]]);

        // Generic wired slide-switch opening; adjust to the purchased switch.
        translate([REAR_OUTER[0] / 2 - WALL - EPS,
                   REAR_MCU_CENTER_Y - REAR_SWITCH_CUTOUT[0] / 2,
                   REAR_FLOOR + 2.0])
            cube([2 * WALL + 2 * EPS, REAR_SWITCH_CUTOUT[0],
                  REAR_SWITCH_CUTOUT[1]]);

        // Separate front cable exit for the four-wire OLED harness.
        translate([-REAR_OUTER[0] / 2 + 3.0,
                   REAR_OUTER[1] / 2 - WALL - EPS,
                   REAR_OUTER[2] - REAR_CABLE_CUTOUT[1]])
            cube([REAR_CABLE_CUTOUT[0], 2 * WALL + 2 * EPS,
                  REAR_CABLE_CUTOUT[1] + EPS]);
    }
}

module rear_pod_lid() {
    lip_outer = [REAR_INNER[0] - 2 * FIT,
                 REAR_INNER[1] - 2 * FIT];
    lip_inner = [lip_outer[0] - 2.0, lip_outer[1] - 2.0];
    difference() {
        union() {
            union() {
                linear_extrude(height = REAR_LID_T)
                    rounded_rect_2d([REAR_OUTER[0], REAR_OUTER[1]],
                                    REAR_RADIUS);
                rear_lid_ears(REAR_LID_T);
            }
            translate([0, 0, -REAR_LIP_H])
                linear_extrude(height = REAR_LIP_H) difference() {
                    rounded_rect_2d(lip_outer, max(1.0, REAR_RADIUS - WALL));
                    union() {
                        rounded_rect_2d(lip_inner,
                                        max(0.8, REAR_RADIUS - 2 * WALL));
                        // Local notch prevents the nominal switch body from
                        // clipping the otherwise continuous insertion lip.
                        translate(REAR_USER_BUTTON_CENTER)
                            square([REAR_USER_BUTTON[0] + 2 * FIT,
                                    REAR_USER_BUTTON[1] + 2 * FIT],
                                   center = true);
                    }
                }
            rear_lid_accessory_guides();
        }

        for (sx = [-1, 1])
            translate([sx * REAR_LID_BOSS_X, 0, -REAR_LIP_H - EPS])
                cylinder(d = M2_CLEAR_D,
                         h = REAR_LIP_H + REAR_LID_T + 2 * EPS);
        for (sx = [-1, 1])
            translate([sx * REAR_LID_BOSS_X, 0, REAR_LID_T - 0.8])
                cylinder(d1 = M2_CLEAR_D, d2 = 5.0, h = 0.8 + EPS);

        // External access for the long-stem D2 pause/fetch button; remove the
        // lid for the XIAO's separate boot/reset controls.
        translate([REAR_USER_BUTTON_CENTER[0],
                   REAR_USER_BUTTON_CENTER[1],
                   -REAR_LIP_H - EPS])
            cylinder(d = REAR_USER_BUTTON_HOLE_D,
                     h = REAR_LIP_H + REAR_LID_T + 2 * EPS);

        translate([-REAR_OUTER[0] / 2 + 3.0,
                   REAR_OUTER[1] / 2 - 2.0,
                   -REAR_LIP_H - EPS])
            cube([REAR_CABLE_CUTOUT[0], 3.0,
                  REAR_LIP_H + REAR_LID_T + 2 * EPS]);
    }
}

// ---------- Split controller and body-battery pods ----------

module controller_strap_ears() {
    ear_x = CTRL_OUTER[0] / 2 + 2.5 - REAR_TAB_OVERLAP;
    for (sy = [-1, 1])
        for (sx = [-1, 1])
            translate([sx * ear_x - 2.5, sy * CTRL_STRAP_Y - 4.0, 0])
                cube([5.0, 8.0, 2.8]);
}

module controller_lid_ears(height) {
    for (sx = [-1, 1])
        translate([sx * CTRL_LID_BOSS_X, 0, 0])
            cylinder(d = CTRL_LID_EAR_D, h = height);
}

module controller_pod() {
    difference() {
        union() {
            difference() {
                rounded_box_xy(CTRL_OUTER, CTRL_RADIUS);
                translate([0, 0, CTRL_FLOOR])
                    linear_extrude(height = CTRL_OUTER[2] + EPS)
                        rounded_rect_2d(CTRL_INNER,
                                        max(0.8, CTRL_RADIUS - WALL));
            }
            controller_lid_ears(CTRL_OUTER[2]);
            controller_strap_ears();

            // Four low rails locate the XIAO without hiding its USB end.
            for (sx = [-1, 1])
                translate([sx * (REAR_MCU[0] / 2 + REAR_MCU_CLEAR + 0.5),
                           CTRL_MCU_CENTER_Y - 5.5,
                           CTRL_FLOOR - 0.2])
                    cube([1.0, 13.0, 2.0]);
        }

        for (sx = [-1, 1])
            translate([sx * CTRL_LID_BOSS_X, 0, -EPS])
                cylinder(d = M2_PILOT_D,
                         h = CTRL_OUTER[2] + 2 * EPS);

        ear_x = CTRL_OUTER[0] / 2 + 2.5 - REAR_TAB_OVERLAP;
        for (sy = [-1, 1])
            for (sx = [-1, 1])
                translate([sx * ear_x - 1.0,
                           sy * CTRL_STRAP_Y - STRAP_WIDTH / 2, -EPS])
                    cube([2.0, STRAP_WIDTH, 2.8 + 2 * EPS]);

        // USB faces rearward; the short OLED harness and two-wire protected
        // battery tether share the strain-relieved forward opening.
        translate([-REAR_USB_CUTOUT[0] / 2,
                   -CTRL_OUTER[1] / 2 - EPS, CTRL_FLOOR + 0.4])
            cube([REAR_USB_CUTOUT[0], 2 * WALL + 2 * EPS,
                  REAR_USB_CUTOUT[1]]);
        translate([-CTRL_CABLE_CUTOUT[0] / 2,
                   CTRL_OUTER[1] / 2 - WALL - EPS,
                   CTRL_OUTER[2] - CTRL_CABLE_CUTOUT[1]])
            cube([CTRL_CABLE_CUTOUT[0], 2 * WALL + 2 * EPS,
                  CTRL_CABLE_CUTOUT[1] + EPS]);
    }
}

module controller_lid_guides() {
    guide_t = 0.8;
    cage_h = REAR_USER_BUTTON[2] + REAR_BUTTON_AXIAL_CLEAR
             + REAR_BUTTON_RETAINER_T + REAR_BUTTON_LEDGE_T;
    cavity = [REAR_USER_BUTTON[0] + 2 * FIT,
              REAR_USER_BUTTON[1] + 2 * FIT];
    button_y0 = CTRL_BUTTON_CENTER[1] - cavity[1] / 2;

    // Antenna guide rails keep the FPC against the plastic lid.
    for (sy = [-1, 1])
        translate([CTRL_ANTENNA_CENTER[0] - REAR_ANTENNA[0] / 2,
                   CTRL_ANTENNA_CENTER[1]
                   + sy * (REAR_ANTENNA[1] / 2 + FIT + guide_t / 2)
                   - guide_t / 2, -1.0])
            cube([REAR_ANTENNA[0], guide_t, 1.0 + EPS]);

    // Three-sided long-stem button cage with the same removable retainer used
    // by the integrated pod.
    for (sx = [-1, 1])
        translate([CTRL_BUTTON_CENTER[0]
                   + sx * (REAR_USER_BUTTON[0] / 2 + FIT + guide_t / 2)
                   - guide_t / 2,
                   button_y0, -cage_h])
            cube([guide_t, cavity[1], cage_h + EPS]);
    translate([CTRL_BUTTON_CENTER[0] - cavity[0] / 2 - 0.25,
               button_y0 - guide_t, -cage_h])
        cube([cavity[0] + 0.5, guide_t, cage_h + EPS]);
    for (sx = [-1, 1])
        translate([CTRL_BUTTON_CENTER[0]
                   + sx * (cavity[0] / 2 - REAR_BUTTON_LEDGE_W / 2)
                   - REAR_BUTTON_LEDGE_W / 2,
                   button_y0, -cage_h])
            cube([REAR_BUTTON_LEDGE_W, cavity[1], REAR_BUTTON_LEDGE_T]);
}

module controller_pod_lid() {
    lip_outer = [CTRL_INNER[0] - 2 * FIT,
                 CTRL_INNER[1] - 2 * FIT];
    lip_inner = [lip_outer[0] - 2.0, lip_outer[1] - 2.0];
    difference() {
        union() {
            linear_extrude(height = CTRL_LID_T)
                rounded_rect_2d(CTRL_OUTER, CTRL_RADIUS);
            controller_lid_ears(CTRL_LID_T);
            translate([0, 0, -CTRL_LIP_H])
                linear_extrude(height = CTRL_LIP_H) difference() {
                    rounded_rect_2d(lip_outer, max(0.8, CTRL_RADIUS - WALL));
                    rounded_rect_2d(lip_inner, max(0.6, CTRL_RADIUS - 2 * WALL));
                }
            controller_lid_guides();
        }

        for (sx = [-1, 1])
            translate([sx * CTRL_LID_BOSS_X, 0, -CTRL_LIP_H - EPS])
                cylinder(d = M2_CLEAR_D,
                         h = CTRL_LIP_H + CTRL_LID_T + 2 * EPS);
        translate([CTRL_BUTTON_CENTER[0], CTRL_BUTTON_CENTER[1],
                   -CTRL_LIP_H - EPS])
            cylinder(d = REAR_USER_BUTTON_HOLE_D,
                     h = CTRL_LIP_H + CTRL_LID_T + 2 * EPS);
        translate([-CTRL_CABLE_CUTOUT[0] / 2,
                   CTRL_OUTER[1] / 2 - 2.0, -CTRL_LIP_H - EPS])
            cube([CTRL_CABLE_CUTOUT[0], 3.0,
                  CTRL_LIP_H + CTRL_LID_T + 2 * EPS]);
    }
}

module body_battery_lid_ears(height) {
    for (sx = [-1, 1])
        translate([sx * BODY_CELL_LID_BOSS_X, 0, 0])
            cylinder(d = BODY_CELL_LID_EAR_D, h = height);
}

module body_battery_pod() {
    difference() {
        union() {
            difference() {
                rounded_box_xy(BODY_CELL_OUTER, BODY_CELL_RADIUS);
                translate([0, 0, BODY_CELL_FLOOR])
                    linear_extrude(height = BODY_CELL_OUTER[2] + EPS)
                        rounded_rect_2d(BODY_CELL_INNER,
                                        max(1.0, BODY_CELL_RADIUS - WALL));
            }
            body_battery_lid_ears(BODY_CELL_OUTER[2]);

            // Low cell guides leave space for removable closed-cell padding.
            for (sx = [-1, 1])
                translate([sx * (REAR_CELL[0] / 2
                                  + REAR_CELL_PAD_CLEAR + 0.5),
                           -REAR_CELL[1] / 2 + 2.0,
                           BODY_CELL_FLOOR - 0.2])
                    cube([1.0, REAR_CELL[1] - 4.0, 2.0]);
        }

        for (sx = [-1, 1])
            translate([sx * BODY_CELL_LID_BOSS_X, 0, -EPS])
                cylinder(d = M2_PILOT_D,
                         h = BODY_CELL_OUTER[2] + 2 * EPS);
        translate([BODY_CELL_OUTER[0] / 2 - WALL - EPS,
                   -BODY_CELL_SWITCH_CUTOUT[0] / 2,
                   BODY_CELL_FLOOR + 1.5])
            cube([2 * WALL + 2 * EPS,
                  BODY_CELL_SWITCH_CUTOUT[0],
                  BODY_CELL_SWITCH_CUTOUT[1]]);
        translate([-BODY_CELL_CABLE_CUTOUT[0] / 2,
                   BODY_CELL_OUTER[1] / 2 - WALL - EPS,
                   BODY_CELL_OUTER[2] - BODY_CELL_CABLE_CUTOUT[1]])
            cube([BODY_CELL_CABLE_CUTOUT[0], 2 * WALL + 2 * EPS,
                  BODY_CELL_CABLE_CUTOUT[1] + EPS]);
    }
}

module body_battery_pod_lid() {
    lip_outer = [BODY_CELL_INNER[0] - 2 * FIT,
                 BODY_CELL_INNER[1] - 2 * FIT];
    lip_inner = [lip_outer[0] - 2.0, lip_outer[1] - 2.0];
    difference() {
        union() {
            linear_extrude(height = BODY_CELL_LID_T)
                rounded_rect_2d(BODY_CELL_OUTER, BODY_CELL_RADIUS);
            body_battery_lid_ears(BODY_CELL_LID_T);
            translate([0, 0, -BODY_CELL_LIP_H])
                linear_extrude(height = BODY_CELL_LIP_H) difference() {
                    rounded_rect_2d(lip_outer,
                                    max(1.0, BODY_CELL_RADIUS - WALL));
                    rounded_rect_2d(lip_inner,
                                    max(0.8, BODY_CELL_RADIUS - 2 * WALL));
                }

            // Raised spring clip accepts a collar edge or pocket hem. It is a
            // convenience retainer, never part of the tether breakaway claim.
            translate([-BODY_CLIP[0] / 2,
                       -BODY_CLIP[1] / 2,
                       BODY_CELL_LID_T + 2.0])
                cube(BODY_CLIP);
            translate([-BODY_CLIP[0] / 2,
                       -BODY_CLIP[1] / 2,
                       BODY_CELL_LID_T])
                cube([BODY_CLIP[0], 3.0, 4.2]);
        }

        for (sx = [-1, 1])
            translate([sx * BODY_CELL_LID_BOSS_X, 0,
                       -BODY_CELL_LIP_H - EPS])
                cylinder(d = M2_CLEAR_D,
                         h = BODY_CELL_LIP_H + BODY_CELL_LID_T + 2 * EPS);
        translate([-BODY_CELL_CABLE_CUTOUT[0] / 2,
                   BODY_CELL_OUTER[1] / 2 - 2.0,
                   -BODY_CELL_LIP_H - EPS])
            cube([BODY_CELL_CABLE_CUTOUT[0], 3.0,
                  BODY_CELL_LIP_H + BODY_CELL_LID_T + 2 * EPS]);
    }
}

// ---------- Fit coupon and cutting template ----------

module fit_coupon() {
    base = [120.0, 40.0, 3.0];
    lens_test_outer = LENS_D + 6.0;
    slot_adjust = [-0.10, 0.00, 0.10];

    difference() {
        union() {
            translate([-base[0] / 2, -base[1] / 2, 0]) cube(base);

            translate([-44, 0, base[2]])
                cylinder(d = lens_test_outer, h = 6.0);

            for (i = [0 : 2])
                translate([-20 + i * 11 - 4.0, -12.0, base[2]])
                    cube([8.0, 24.0, 8.0]);

            translate([23, 0, base[2]]) dovetail_male(24.0);
            translate([44 - (QUICK[0] + 2.0) / 2, -12.0, base[2]])
                cube([QUICK[0] + 2.0, 24.0, QUICK[2]]);
        }

        // Lens pocket tests the configured diametral allowance.
        translate([-44, 0, base[2] - EPS])
            cylinder(d = LENS_D + LENS_POCKET_DIAMETRAL_CLEAR,
                     h = 6.0 + 2 * EPS);

        // Left to right: tight, nominal, and loose pane slots.
        for (i = [0 : 2])
            translate([-20 + i * 11
                       - (COMBINER_PANE[2] + PANE_SLOT_CLEAR
                          + slot_adjust[i]) / 2,
                       -10.0, base[2] - EPS])
                cube([COMBINER_PANE[2] + PANE_SLOT_CLEAR + slot_adjust[i],
                      20.0, 8.0 + 2 * EPS]);

        translate([44, 0, base[2] - EPS]) dovetail_void(24.0 + 2 * EPS);
    }
}

module combiner_cut_template_2d() {
    difference() {
        rounded_rect_2d([COMBINER_PANE[0], COMBINER_PANE[1]],
                        COMBINER_CORNER_R);
        // Chamfered source-side corner is a permanent coating-orientation mark.
        translate([COMBINER_PANE[0] / 2, COMBINER_PANE[1] / 2])
            rotate(45) square([4.2, 4.2], center = true);
    }
}

module cut_template_print() {
    linear_extrude(height = 0.6) combiner_cut_template_2d();
}

// ---------- Focus bench ----------

module bench_cradle(x_pos) {
    cradle_w = 7.0;
    side_t = 3.0;
    cradle_outer_y = TUNNEL_OUTER + 2 * side_t;
    difference() {
        translate([x_pos - cradle_w / 2, -cradle_outer_y / 2,
                   BENCH_BASE_T])
            cube([cradle_w, cradle_outer_y,
                  BENCH_AXIS_Z + TUNNEL_OUTER / 2 - BENCH_BASE_T]);
        translate([x_pos - cradle_w / 2 - EPS,
                   -TUNNEL_OUTER / 2 - FIT,
                   BENCH_AXIS_Z - TUNNEL_OUTER / 2 - FIT])
            cube([cradle_w + 2 * EPS,
                  TUNNEL_OUTER + 2 * FIT,
                  TUNNEL_OUTER + 3.0]);
    }
}

module bench_frame_support(u_pos) {
    support_z0 = BENCH_BASE_T - EPS;
    support_h = BENCH_FRAME_SUPPORT_H + EPS;
    support_w = FRAME_STACK_T + 2 * FIT + 2 * WALL;
    translate([COMBINER_SOCKET_CENTER_X
               + u_pos * cos(COMBINER_ANGLE),
               COMBINER_SOCKET_CENTER_Y
               + u_pos * sin(COMBINER_ANGLE),
               support_z0 + support_h / 2])
        rotate([0, 0, COMBINER_ANGLE])
            cube([4.0, support_w, support_h], center = true);
}

module focus_bench_jig() {
    x_min = -36.0;
    x_max = TUNNEL_LENGTH + 7.0;
    y_min = -50.0;
    y_max = 25.0;
    base_size = [x_max - x_min, y_max - y_min, BENCH_BASE_T];
    base_center = [(x_min + x_max) / 2, (y_min + y_max) / 2];

    difference() {
        union() {
            translate([base_center[0], base_center[1], 0])
                rounded_box_xy(base_size, 3.0);
            bench_cradle(8.0);
            bench_cradle(TUNNEL_LENGTH - 8.0);
            // Two pedestals support the ring while their wider feet remain
            // joined to the base on both sides of the shallow sandwich slot.
            bench_frame_support(-10.0);
            bench_frame_support(10.0);
        }

        // Slot receives the assembled combiner sandwich at 45 degrees.
        translate([COMBINER_SOCKET_CENTER_X, COMBINER_SOCKET_CENTER_Y,
                   BENCH_BASE_T - BENCH_SLOT_DEPTH / 2])
            rotate([0, 0, COMBINER_ANGLE])
                cube([FRAME_OUTER[0] + 2 * FIT,
                      FRAME_STACK_T + 2 * FIT,
                      BENCH_SLOT_DEPTH + EPS], center = true);

        // Eye/camera pupil datum and shallow reflected-ray alignment groove.
        translate([-FOLD_GAP, -EYE_DATUM_DISTANCE, -EPS])
            cylinder(d = 4.0, h = BENCH_BASE_T + 2 * EPS);
        translate([-FOLD_GAP - 0.25, -EYE_DATUM_DISTANCE,
                   BENCH_BASE_T - 0.35])
            cube([0.5, EYE_DATUM_DISTANCE, 0.4]);
    }
}

module bench_assembly_preview() {
    focus_bench_jig();
    translate([0, 0, BENCH_AXIS_Z]) color("#252525") lens_tunnel();

    cart_x = LENS_PRINCIPAL_FROM_FRONT_RIM + FOCUS_NOMINAL - OLED_FACE_X;
    translate([cart_x, 0, BENCH_AXIS_Z])
        color("#404040") oled_focus_cartridge();
    translate([-LENS_RETAINER_T - exploded, 0, BENCH_AXIS_Z])
        color("#333333") lens_retainer();

    translate([COMBINER_BASE_CENTER_X,
               COMBINER_BASE_CENTER_Y, BENCH_AXIS_Z])
        rotate([90, 0, COMBINER_ANGLE])
            combiner_stack_preview(exploded);

    color([0.2, 1.0, 0.3, 0.8]) {
        segment([LENS_PRINCIPAL_FROM_FRONT_RIM + FOCUS_NOMINAL,
                 0, BENCH_AXIS_Z],
                [-FOLD_GAP, 0, BENCH_AXIS_Z]);
        segment([-FOLD_GAP, 0, BENCH_AXIS_Z],
                [-FOLD_GAP, -EYE_DATUM_DISTANCE, BENCH_AXIS_Z]);
    }
}

// ---------- Wearable assembly preview ----------

module preview_prescription_lens() {
    color([0.65, 0.85, 1.0, 0.18])
        translate([0, PRESCRIPTION_LENS_Y, 0])
            rotate([90, 0, 0])
                scale([1.25, 0.9, 1])
                    cylinder(d = 42, h = PRESCRIPTION_LENS_T, center = true);
}

module preview_eye() {
    // Pupil/corneal datum is y=0; the eyeball centre is posterior.
    color([0.85, 0.72, 0.58, 0.75])
        translate([0, -9.0, 0]) sphere(d = 18);
    color([0.1, 0.1, 0.1, 0.9])
        translate([0, -0.25, 0]) sphere(d = 4.0);
}

module preview_temple(x_pos, saddle_floor_z, rear_pod_y) {
    proxy_size = [4.0, 100.0, 3.0];
    proxy_margin = 5.0;
    proxy_y_min = rear_pod_y - REAR_STRAP_Y - STRAP_WIDTH / 2
                  - proxy_margin;
    proxy_y_max = proxy_y_min + proxy_size[1];
    proxy_top_above_floor = 0.5;
    groove_at_proxy_edge = SADDLE_V_DEPTH
                           * (1 - proxy_size[0] / SADDLE_V_WIDTH);
    assert(proxy_top_above_floor + 1.0 <= groove_at_proxy_edge,
           "Temple proxy plus 1 mm pad must clear the saddle V groove");
    for (station = [-REAR_STRAP_Y, REAR_STRAP_Y])
        assert(rear_pod_y + station - STRAP_WIDTH / 2 >= proxy_y_min
               && rear_pod_y + station + STRAP_WIDTH / 2 <= proxy_y_max,
               "Complete rear-pod strap footprint must land on temple proxy");
    // A real temple rests in the padded V and protrudes below the open saddle.
    // Keeping this 4 mm proxy's top at local z=0.5 leaves about 1.16 mm for
    // padding at x=+/-2. The Y range is derived from both rear-pod strap
    // stations rather than an arbitrary forward-biased 100 mm segment.
    color([0.15, 0.15, 0.18, 0.8])
        translate([x_pos - proxy_size[0] / 2, proxy_y_min,
                   saddle_floor_z + proxy_top_above_floor - proxy_size[2]])
            cube(proxy_size);
}

module preview_rear_straps(temple_x, pod_x, pod_y, pod_z) {
    // The pod is intentionally outboard, not centred over the temple. These
    // two translucent bridges show the complete Y footprint of both bands.
    rear_ear_x = REAR_OUTER[0] / 2 + 2.8 - REAR_TAB_OVERLAP;
    near_slot_x = pod_x - rear_ear_x;
    strap_x0 = min(temple_x, near_slot_x);
    strap_x1 = max(temple_x, near_slot_x);
    for (station = [-REAR_STRAP_Y, REAR_STRAP_Y])
        color([0.1, 0.1, 0.1, 0.65])
            translate([strap_x0,
                       pod_y + station - STRAP_WIDTH / 2,
                       pod_z + 1.1])
                cube([strap_x1 - strap_x0, STRAP_WIDTH, 0.6]);
}

module preview_controller_straps(temple_x, pod_x, pod_y, pod_z) {
    ear_x = CTRL_OUTER[0] / 2 + 2.5 - REAR_TAB_OVERLAP;
    near_slot_x = pod_x - ear_x;
    strap_x0 = min(temple_x, near_slot_x);
    strap_x1 = max(temple_x, near_slot_x);
    for (station = [-CTRL_STRAP_Y, CTRL_STRAP_Y])
        color([0.1, 0.1, 0.1, 0.65])
            translate([strap_x0,
                       pod_y + station - STRAP_WIDTH / 2,
                       pod_z + 1.0])
                cube([strap_x1 - strap_x0, STRAP_WIDTH, 0.6]);
}

module assembly_preview() {
    hand = side == "left" ? -1 : 1;
    pose_angle = wear_pose == "parked" ? HINGE_PARK_ANGLE : 0;
    engine_x = 15.0;
    engine_y = WEARABLE_ENGINE_Y;
    engine_z = 0.0;
    clamp_x = 48.0;
    mount_y = engine_y + ENGINE_OFFSET_Y;
    comb_center = [0, engine_y, engine_z]; // chief-ray intersection, not frame centre
    cart_x = LENS_PRINCIPAL_FROM_FRONT_RIM + FOCUS_NOMINAL - OLED_FACE_X;
    carriage_z = ENGINE_HINGE_Z - HINGE_AXIS_ABOVE_CARRIAGE;
    saddle_z = carriage_z - SADDLE[2];
    rear_x = clamp_x + REAR_OUTER[0] / 2 + 9.0;
    rear_y = -35.0;
    rear_z = saddle_z + 0.4;
    ctrl_x = clamp_x + CTRL_OUTER[0] / 2 + 9.0;
    ctrl_y = -24.0;
    ctrl_z = saddle_z + 0.4;

    assert(abs(rear_x - REAR_OUTER[0] / 2
               - (clamp_x + SADDLE[0] / 2)) < EPS,
           "Rear pod is intended to sit tangent and outboard of the saddle");

    if (show_wearer_proxy) {
        preview_eye();
        preview_prescription_lens();
    }

    // Mirror the complete optical engine for left-eye use.
    scale([hand, 1, 1]) {
        if (show_wearer_proxy)
            preview_temple(clamp_x, saddle_z, rear_y);

        // The complete optical engine rotates around the compact carriage's
        // X-axis hinge. At 100 degrees it parks above the primary sightline;
        // the carriage, saddle, temple, and optional rear pod stay fixed.
        translate([clamp_x, mount_y, ENGINE_HINGE_Z])
            rotate([pose_angle, 0, 0])
                translate([-clamp_x, -mount_y, -ENGINE_HINGE_Z]) {
                    translate([engine_x, engine_y, engine_z])
                        color("#222222") lens_tunnel();
                    translate([engine_x + cart_x + exploded,
                               engine_y, engine_z])
                        color("#3a3a3a") oled_focus_cartridge();
                    translate([engine_x - exploded, engine_y, engine_z])
                        color("#303030") combiner_bracket();

                    translate([engine_x + COMBINER_BASE_CENTER_X,
                               engine_y + COMBINER_BASE_CENTER_Y, engine_z])
                        rotate([90, 0, COMBINER_ANGLE])
                            combiner_stack_preview(exploded);

                    translate([clamp_x, engine_y, engine_z])
                        color("#404040") engine_cradle();
                    translate([clamp_x, engine_y, engine_z + exploded])
                        color("#555555") engine_clamp();
                }

        // One rail carriage now supplies fore/aft adjustment, pivot, two hard
        // stops, and keeper pegs. This removes the old cross adapter.
        translate([clamp_x, mount_y, carriage_z - exploded])
            color("#505050") compact_carriage();
        translate([clamp_x, mount_y, saddle_z - 3 * exploded])
            color("#303030") temple_saddle();

        if (show_rear_pod) {
            // Optional on-glasses rear pod; move it to a pocket/collar to
            // reduce head-worn mass. Hook-and-loop ears are the attachment.
            translate([rear_x, rear_y, rear_z])
                color("#242424") rear_pod();
            translate([rear_x, rear_y,
                       rear_z + REAR_OUTER[2] + exploded])
                color("#333333") rear_pod_lid();
            translate([rear_x + REAR_USER_BUTTON_CENTER[0],
                       rear_y + REAR_USER_BUTTON_CENTER[1],
                       rear_z + REAR_OUTER[2]
                       - REAR_USER_BUTTON[2] - REAR_BUTTON_AXIAL_CLEAR
                       - REAR_BUTTON_RETAINER_T + exploded])
                color("#555555") rear_button_retainer();
            preview_rear_straps(clamp_x, rear_x, rear_y, rear_z);
        }

        if (show_controller_pod) {
            translate([ctrl_x, ctrl_y, ctrl_z])
                color("#242424") controller_pod();
            translate([ctrl_x, ctrl_y,
                       ctrl_z + CTRL_OUTER[2] + exploded])
                color("#333333") controller_pod_lid();
            preview_controller_straps(clamp_x, ctrl_x, ctrl_y, ctrl_z);
        }
    }

    // Pupil-centred, same-height chief ray is optically coherent with the
    // vertical 45-degree pane. This v0.2 intentionally does not fake elevation.
    if (wear_pose == "deployed" && show_wearer_proxy) {
        color([0.2, 1.0, 0.3, 0.85]) {
            segment([hand * (engine_x + LENS_PRINCIPAL_FROM_FRONT_RIM
                             + FOCUS_NOMINAL),
                     engine_y, engine_z],
                    comb_center);
            segment(comb_center, [0, 0, 0]);
        }

        // Show only a physically meaningful first-order common box. The
        // compact experimental preset has a negative axis and is not promoted.
        if (COMMON_EYEBOX[0] > 0 && COMMON_EYEBOX[1] > 0)
            color([1.0, 0.55, 0.1, 0.4])
                translate([0, 0.8, 0])
                    cube([COMMON_EYEBOX[0], 0.5, COMMON_EYEBOX[1]], center = true);
    }
}

module split_pods_preview() {
    ctrl_x = -28.0;
    body_x = 26.0;
    lid_lift = 9.0;

    translate([ctrl_x, 0, 0]) {
        color([0.12, 0.12, 0.14, 0.82]) controller_pod();
        translate([0, 0, CTRL_OUTER[2] + lid_lift])
            color([0.18, 0.18, 0.20, 0.72]) controller_pod_lid();

        // XIAO, button, and supplied FPC antenna packaging proxies.
        color([0.08, 0.32, 0.20, 0.95])
            translate([-REAR_MCU[0] / 2,
                       CTRL_MCU_CENTER_Y - REAR_MCU[1] / 2,
                       CTRL_FLOOR + 0.3])
                cube([REAR_MCU[0], REAR_MCU[1], 1.2]);
        color([0.12, 0.12, 0.12, 0.95])
            translate([CTRL_BUTTON_CENTER[0], CTRL_BUTTON_CENTER[1],
                       CTRL_FLOOR + REAR_USER_BUTTON[2] / 2])
                cube(REAR_USER_BUTTON, center = true);
        color([0.75, 0.45, 0.12, 0.9])
            translate([CTRL_ANTENNA_CENTER[0] - REAR_ANTENNA[0] / 2,
                       CTRL_ANTENNA_CENTER[1] - REAR_ANTENNA[1] / 2,
                       CTRL_OUTER[2] + lid_lift - 1.2])
                cube(REAR_ANTENNA);
    }

    translate([body_x, 0, 0]) {
        color([0.12, 0.12, 0.14, 0.82]) body_battery_pod();
        translate([0, 0, BODY_CELL_OUTER[2] + lid_lift])
            color([0.18, 0.18, 0.20, 0.72]) body_battery_pod_lid();
        color([0.65, 0.68, 0.72, 0.95])
            translate([-REAR_CELL[0] / 2,
                       -REAR_CELL[1] / 2,
                       BODY_CELL_FLOOR + 0.3])
                cube(REAR_CELL);
    }

    // Two-wire protected-battery tether; the real build requires a tested
    // low-retention disconnect close to the glasses.
    color([0.8, 0.12, 0.12, 0.9])
        segment([ctrl_x + CTRL_OUTER[0] / 2, CTRL_OUTER[1] / 2, 3.0],
                [body_x - BODY_CELL_OUTER[0] / 2,
                 BODY_CELL_OUTER[1] / 2, 3.0], 0.7);
    color([0.08, 0.08, 0.08, 0.95])
        segment([ctrl_x + CTRL_OUTER[0] / 2, CTRL_OUTER[1] / 2, 2.0],
                [body_x - BODY_CELL_OUTER[0] / 2,
                 BODY_CELL_OUTER[1] / 2, 2.0], 0.7);
}

// ---------- Selector ----------

valid_part = part == "assembly"
          || part == "bench_assembly"
          || part == "split_pods_preview"
          || part == "focus_bench_jig"
          || part == "focus_bench"
          || part == "oled_cartridge"
          || part == "lens_tunnel"
          || part == "lens_retainer"
          || part == "combiner_frame"
          || part == "combiner_clamp"
          || part == "combiner_shim"
          || part == "combiner_edge_liner"
          || part == "temple_saddle"
          || part == "quick_release"
          || part == "compact_carriage"
          || part == "mount_adapter"
          || part == "engine_cradle"
          || part == "engine_clamp"
          || part == "hinge_interference_probe"
          || part == "combiner_bracket"
          || part == "rear_pod"
          || part == "rear_pod_lid"
          || part == "rear_button_retainer"
          || part == "controller_pod"
          || part == "controller_pod_lid"
          || part == "body_battery_pod"
          || part == "body_battery_pod_lid"
          || part == "fit_coupon"
          || part == "cut_template"
          || part == "cut_template_print";

assert(valid_part,
       str("Unknown part selector: ", part,
           ". See hardware/cad/README.md for valid values."));

if (part == "assembly") assembly_preview();
else if (part == "bench_assembly") bench_assembly_preview();
else if (part == "split_pods_preview") split_pods_preview();
else if (part == "focus_bench_jig") focus_bench_jig();
else if (part == "focus_bench") focus_bench_jig();
else if (part == "oled_cartridge") oled_focus_cartridge();
else if (part == "lens_tunnel") lens_tunnel();
else if (part == "lens_retainer") lens_retainer();
else if (part == "combiner_frame") combiner_frame();
else if (part == "combiner_clamp") combiner_clamp();
else if (part == "combiner_shim") combiner_shim();
else if (part == "combiner_edge_liner") combiner_edge_liner();
else if (part == "temple_saddle") temple_saddle();
else if (part == "quick_release") quick_release();
else if (part == "compact_carriage") compact_carriage();
else if (part == "mount_adapter") mount_adapter();
else if (part == "engine_cradle") engine_cradle();
else if (part == "engine_clamp") engine_clamp();
else if (part == "hinge_interference_probe") hinge_interference_probe();
else if (part == "combiner_bracket") combiner_bracket();
else if (part == "rear_pod") rear_pod();
else if (part == "rear_pod_lid") rear_pod_lid();
else if (part == "rear_button_retainer") rear_button_retainer();
else if (part == "controller_pod") controller_pod();
else if (part == "controller_pod_lid") controller_pod_lid();
else if (part == "body_battery_pod") body_battery_pod();
else if (part == "body_battery_pod_lid") body_battery_pod_lid();
else if (part == "fit_coupon") fit_coupon();
else if (part == "cut_template") combiner_cut_template_2d();
else if (part == "cut_template_print") cut_template_print();
