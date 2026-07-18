#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source_file="$script_dir/openglasshole.scad"
output_dir="$script_dir/build"

printable_parts=(
  focus_bench_jig focus_bench oled_cartridge lens_tunnel lens_retainer
  combiner_frame combiner_clamp combiner_shim combiner_edge_liner
  temple_saddle quick_release compact_carriage
  mount_adapter engine_cradle engine_clamp combiner_bracket
  rear_pod rear_pod_lid rear_button_retainer fit_coupon cut_template_print
  controller_pod controller_pod_lid body_battery_pod body_battery_pod_lid
)
two_d_parts=(cut_template)
presets=(budget_25x45 compact_23x30)

usage() {
  cat <<'EOF'
Usage: ./export.sh PART [stl|3mf|dxf|svg] [LENS_PRESET]

Examples:
  ./export.sh fit_coupon stl
  ./export.sh lens_tunnel stl compact_23x30
  ./export.sh cut_template dxf

The output directory is hardware/cad/build. Existing files are preserved unless
FORCE=1 is set. LENS_PRESET defaults to budget_25x45. OPENSCAD_BIN may name a
custom OpenSCAD executable.
EOF
}

contains() {
  local needle=$1
  shift
  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

if [[ $# -lt 1 || $# -gt 3 ]]; then
  usage >&2
  exit 2
fi

selected_part=$1
format=${2:-stl}
lens_preset=${3:-budget_25x45}

if ! contains "$lens_preset" "${presets[@]}"; then
  echo "error: unknown lens preset '$lens_preset'" >&2
  exit 2
fi

case "$format" in
  stl|3mf)
    if ! contains "$selected_part" "${printable_parts[@]}"; then
      echo "error: '$selected_part' is not a whitelisted printable part" >&2
      exit 2
    fi
    ;;
  dxf|svg)
    if ! contains "$selected_part" "${two_d_parts[@]}"; then
      echo "error: '$selected_part' is not a whitelisted 2D part" >&2
      exit 2
    fi
    ;;
  *)
    echo "error: unsupported format '$format'" >&2
    usage >&2
    exit 2
    ;;
esac

if [[ -n ${OPENSCAD_BIN:-} ]]; then
  if [[ ! -x "$OPENSCAD_BIN" ]]; then
    echo "error: OPENSCAD_BIN is not executable: $OPENSCAD_BIN" >&2
    exit 127
  fi
  openscad_command=("$OPENSCAD_BIN")
elif command -v openscad >/dev/null 2>&1; then
  openscad_command=(openscad)
elif command -v flatpak >/dev/null 2>&1 \
     && flatpak info org.openscad.OpenSCAD >/dev/null 2>&1; then
  openscad_command=(flatpak run org.openscad.OpenSCAD)
else
  echo "error: OpenSCAD was not found on the host or as org.openscad.OpenSCAD" >&2
  exit 127
fi

mkdir -p -- "$output_dir"
suffix=""
if [[ "$lens_preset" != budget_25x45 ]]; then
  suffix="-$lens_preset"
fi
destination="$output_dir/$selected_part$suffix.$format"

if [[ -e "$destination" && ${FORCE:-0} != 1 ]]; then
  echo "error: refusing to overwrite $destination (set FORCE=1 to replace)" >&2
  exit 3
fi

temporary="$output_dir/.$selected_part$suffix.$$.tmp.$format"
cleanup() {
  [[ ! -e "$temporary" ]] || rm -f -- "$temporary"
}
trap cleanup EXIT INT TERM

"${openscad_command[@]}" \
  -D "part=\"$selected_part\"" \
  -D "lens_preset=\"$lens_preset\"" \
  -o "$temporary" \
  "$source_file"

if [[ ! -s "$temporary" ]]; then
  echo "error: OpenSCAD did not create a non-empty output" >&2
  exit 4
fi

mv -f -- "$temporary" "$destination"
trap - EXIT INT TERM
echo "$destination"
