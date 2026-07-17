#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
release_dir="$script_dir/stl"
source_file="$script_dir/openglasshole.scad"
mesh_check="$script_dir/validate_mesh.py"
parts=(
  focus_bench_jig oled_cartridge lens_tunnel lens_retainer
  combiner_frame combiner_clamp combiner_shim combiner_edge_liner
  temple_saddle quick_release
  mount_adapter engine_cradle engine_clamp combiner_bracket
  rear_pod rear_pod_lid rear_button_retainer fit_coupon cut_template_print
)

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

mkdir -p -- "$release_dir"
stage_dir=$(mktemp -d "${TMPDIR:-/tmp}/openglasshole-release.XXXXXX")
cleanup() {
  rm -rf -- "$stage_dir"
}
trap cleanup EXIT INT TERM

for selected_part in "${parts[@]}"; do
  temporary="$stage_dir/$selected_part.stl"
  log="$stage_dir/$selected_part.log"
  if ! "${openscad_command[@]}" \
      -D 'lens_preset="budget_25x45"' \
      -D "part=\"$selected_part\"" \
      -o "$temporary" "$source_file" >"$log" 2>&1; then
    cat "$log" >&2
    exit 1
  fi
  if grep -E '(WARNING|ERROR):' "$log" >/dev/null || [[ ! -s "$temporary" ]]; then
    cat "$log" >&2
    echo "error: rejected release mesh for $selected_part" >&2
    exit 1
  fi
  "$mesh_check" "$temporary"
done

if [[ ${RELEASE_CHECK:-0} == 1 ]]; then
  tracked_count=$(find "$release_dir" -maxdepth 1 -type f -name '*.stl' | wc -l)
  if [[ $tracked_count -ne ${#parts[@]} ]]; then
    echo "error: tracked STL count is $tracked_count; expected ${#parts[@]}" >&2
    exit 1
  fi
  for selected_part in "${parts[@]}"; do
    tracked="$release_dir/$selected_part.stl"
    if [[ ! -s $tracked ]]; then
      echo "error: missing tracked release mesh: $tracked" >&2
      exit 1
    fi
    if ! "$mesh_check" --equivalent \
        "$tracked" "$stage_dir/$selected_part.stl"; then
      echo "error: stale tracked release mesh: $tracked" >&2
      exit 1
    fi
  done
  echo "Tracked budget-preset STL set exactly matches regenerated meshes."
  exit 0
fi

# Do not touch the tracked set until every candidate has rendered and passed.
for selected_part in "${parts[@]}"; do
  mv -f -- "$stage_dir/$selected_part.stl" \
    "$release_dir/$selected_part.stl"
done

echo "Reviewed budget-preset STL set written to $release_dir"
