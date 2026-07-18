#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source_file="$script_dir/openglasshole.scad"
mesh_check="$script_dir/validate_mesh.py"

printable_parts=(
  focus_bench_jig focus_bench oled_cartridge lens_tunnel lens_retainer
  combiner_frame combiner_clamp combiner_shim combiner_edge_liner
  temple_saddle quick_release compact_carriage
  mount_adapter engine_cradle engine_clamp combiner_bracket
  rear_pod rear_pod_lid rear_button_retainer fit_coupon cut_template_print
  controller_pod controller_pod_lid body_battery_pod body_battery_pod_lid
)
preview_parts=(assembly bench_assembly split_pods_preview)
presets=(budget_25x45 compact_23x30)

if [[ -n ${OPENSCAD_BIN:-} ]]; then
  openscad_command=("$OPENSCAD_BIN")
elif command -v openscad >/dev/null 2>&1; then
  openscad_command=(openscad)
elif command -v flatpak >/dev/null 2>&1 \
     && flatpak info org.openscad.OpenSCAD >/dev/null 2>&1; then
  openscad_command=(flatpak run org.openscad.OpenSCAD)
else
  echo "error: OpenSCAD was not found; set OPENSCAD_BIN or install OpenSCAD" >&2
  exit 127
fi

if [[ ! -x "$mesh_check" ]]; then
  echo "error: mesh validator is not executable: $mesh_check" >&2
  exit 126
fi

validation_dir=$(mktemp -d "${TMPDIR:-/tmp}/openglasshole-cad.XXXXXX")
cleanup() {
  if [[ ${VALIDATION_KEEP:-0} == 1 ]]; then
    echo "kept validation outputs: $validation_dir"
  else
    rm -rf -- "$validation_dir"
  fi
}
trap cleanup EXIT INT TERM

render() {
  local preset=$1
  local selected_part=$2
  local extension=$3
  local output="$validation_dir/$preset-$selected_part.$extension"
  local log="$validation_dir/$preset-$selected_part.log"

  if ! "${openscad_command[@]}" \
      -D "lens_preset=\"$preset\"" \
      -D "part=\"$selected_part\"" \
      -o "$output" "$source_file" >"$log" 2>&1; then
    cat "$log" >&2
    return 1
  fi
  if grep -E '(WARNING|ERROR):' "$log" >/dev/null; then
    cat "$log" >&2
    return 1
  fi
  if [[ ! -s "$output" ]]; then
    echo "error: empty output for $preset/$selected_part" >&2
    return 1
  fi
  if [[ "$extension" == stl ]]; then
    "$mesh_check" "$output"
  fi
}

validate_asymmetric_lens_guards() {
  local pass_output="$validation_dir/asymmetric-rear-heavy-lens.stl"
  local pass_log="$validation_dir/asymmetric-rear-heavy-lens.log"
  local fail_output="$validation_dir/asymmetric-front-heavy-lens.stl"
  local fail_log="$validation_dir/asymmetric-front-heavy-lens.log"

  # Both overrides preserve edge + front + rear = centre thickness. A larger
  # rear crown must remain buildable because it only lengthens tunnel relief.
  if ! "${openscad_command[@]}" \
      -D 'lens_preset="budget_25x45"' \
      -D 'part="lens_retainer"' \
      -D 'LENS_FRONT_SAG=1.0' \
      -D 'LENS_REAR_SAG=2.8' \
      -o "$pass_output" "$source_file" >"$pass_log" 2>&1; then
    cat "$pass_log" >&2
    return 1
  fi
  if grep -E '(WARNING|ERROR):' "$pass_log" >/dev/null \
      || [[ ! -s "$pass_output" ]]; then
    cat "$pass_log" >&2
    return 1
  fi
  "$mesh_check" "$pass_output"

  # Flipping those crown heights puts the large sag against the hard stop. It
  # must trip the full-taper clearance assertion rather than silently render.
  if "${openscad_command[@]}" \
      -D 'lens_preset="budget_25x45"' \
      -D 'part="lens_retainer"' \
      -D 'LENS_FRONT_SAG=3.6' \
      -D 'LENS_REAR_SAG=0.2' \
      -o "$fail_output" "$source_file" >"$fail_log" 2>&1; then
    echo "error: unsafe front-heavy asymmetric lens was accepted" >&2
    return 1
  fi
  if ! grep -F 'Hard aperture-stop gap below 0.6 mm' "$fail_log" >/dev/null; then
    cat "$fail_log" >&2
    echo "error: asymmetric lens failed for an unexpected reason" >&2
    return 1
  fi
}

validate_hinge_stops() {
  local angle output log
  local sweep_angles=(
    0.1 1 2 5 10 20 30 40 50 60 70 80 90 95 98 99 99.9
  )

  # Inside the two asserted, exactly coincident contact planes, the moving
  # clamp and fixed carriage must have no volumetric interference. Endpoint
  # surface contact is checked algebraically in the SCAD; exporting a
  # zero-thickness STL is renderer-dependent, so probe just inside each limit.
  for angle in "${sweep_angles[@]}"; do
    output="$validation_dir/hinge-clear-$angle.stl"
    log="$validation_dir/hinge-clear-$angle.log"
    # OpenSCAD exits nonzero when an intersection is intentionally empty, so
    # judge these probes from the diagnostic and absence of an output mesh.
    "${openscad_command[@]}" \
        -D 'lens_preset="budget_25x45"' \
        -D 'part="hinge_interference_probe"' \
        -D "hinge_probe_angle=$angle" \
        -o "$output" "$source_file" >"$log" 2>&1 || true
    if grep -E '(WARNING|ERROR):' "$log" >/dev/null \
        || [[ -s "$output" ]] \
        || ! grep -F 'Current top level object is empty' "$log" >/dev/null; then
      cat "$log" >&2
      echo "error: hinge parts interfere at $angle degrees" >&2
      return 1
    fi
  done

  # A small move beyond either limit must create real overlap. This proves the
  # radial faces block travel instead of merely approaching with a gap.
  for angle in -1 101; do
    output="$validation_dir/hinge-block-$angle.stl"
    log="$validation_dir/hinge-block-$angle.log"
    if ! "${openscad_command[@]}" \
        -D 'lens_preset="budget_25x45"' \
        -D 'part="hinge_interference_probe"' \
        -D "hinge_probe_angle=$angle" \
        -o "$output" "$source_file" >"$log" 2>&1; then
      cat "$log" >&2
      return 1
    fi
    if grep -E '(WARNING|ERROR):' "$log" >/dev/null || [[ ! -s "$output" ]]; then
      cat "$log" >&2
      echo "error: hinge hard stop does not block beyond $angle degrees" >&2
      return 1
    fi
  done
}

"${openscad_command[@]}" --version
for preset in "${presets[@]}"; do
  for selected_part in "${printable_parts[@]}"; do
    render "$preset" "$selected_part" stl
  done
  for selected_part in "${preview_parts[@]}"; do
    render "$preset" "$selected_part" csg
  done
  render "$preset" cut_template dxf
done

validate_asymmetric_lens_guards
validate_hinge_stops

echo "CAD validation passed for both lens presets and every selector."
