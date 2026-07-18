#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source_file="$script_dir/open-occucue.scad"

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

stage_dir=$(mktemp -d "${TMPDIR:-/tmp}/open-occucue-previews.XXXXXX")
cleanup() {
  rm -rf -- "$stage_dir"
}
trap cleanup EXIT INT TERM

render_preview() {
  local output_name=$1
  shift
  local output="$stage_dir/$output_name"
  local log="$stage_dir/$output_name.log"

  if ! "${openscad_command[@]}" \
      --imgsize=1600,1000 \
      --autocenter \
      --viewall \
      --projection=ortho \
      --colorscheme=Tomorrow \
      "$@" \
      -o "$output" "$source_file" >"$log" 2>&1; then
    cat "$log" >&2
    return 1
  fi
  if grep -E '(WARNING|ERROR):' "$log" >/dev/null || [[ ! -s "$output" ]]; then
    cat "$log" >&2
    echo "error: rejected CAD preview $output_name" >&2
    return 1
  fi
  case $(head -c 8 "$output" | od -An -tx1 | tr -d ' \n') in
    89504e470d0a1a0a) ;;
    *) echo "error: $output_name is not a PNG" >&2; return 1 ;;
  esac
}

render_preview assembly-preview.png \
  -D 'part="assembly"' \
  -D 'wear_pose="deployed"' \
  -D 'show_controller_pod=true' \
  -D 'show_rear_pod=false'
render_preview parked-preview.png \
  -D 'part="assembly"' \
  -D 'wear_pose="parked"' \
  -D 'show_controller_pod=true' \
  -D 'show_rear_pod=false'
render_preview split-pods-preview.png \
  -D 'part="split_pods_preview"'

if [[ ${PREVIEW_CHECK:-0} == 1 ]]; then
  echo "Rendered three nonempty CAD previews in a temporary directory."
  exit 0
fi

for output_name in assembly-preview.png parked-preview.png split-pods-preview.png; do
  mv -f -- "$stage_dir/$output_name" "$script_dir/$output_name"
done
echo "Updated deployed, parked, and split-pod CAD previews in $script_dir"
