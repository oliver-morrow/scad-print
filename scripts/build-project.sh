#!/bin/sh
set -eu

model=$1
settings=$2
output=$3
profile=${PROFILE:-}
openscad=${OPENSCAD:-openscad}
slicer=${SLICER:-prusa-slicer}
mac_slicer=/Applications/PrusaSlicer.app/Contents/MacOS/PrusaSlicer
if [ -z "${SLICER:-}" ] && [ -x "$mac_slicer" ]; then
    slicer=$mac_slicer
fi

case "$model" in /*) ;; *) model="$PWD/$model";; esac
case "$output" in /*) ;; *) output="$PWD/$output";; esac
case "$output" in *.3mf) ;; *) echo 'OUT must end in .3mf.' >&2; exit 2;; esac
if [ -d "$output" ]; then
    echo "Output is a directory: $output" >&2
    exit 2
fi

for command in "$openscad" "$slicer" zip unzip; do
    if ! command -v "$command" >/dev/null; then
        echo "Missing tool: $command" >&2
        exit 2
    fi
done

output_dir=$(dirname "$output")
mkdir -p "$output_dir"
scratch=$(mktemp -d "$output_dir/.scad-print.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
trap 'exit 1' HUP INT TERM
state="$scratch/slicer"
config="$scratch/effective.ini"
metadata=Metadata/Slic3r_PE.config
mkdir "$state" "$scratch/Metadata"

set -- --load "$settings"
if [ -n "$profile" ]; then
    set -- --load "$profile" "$@"
fi
"$slicer" --datadir "$state" --config-compatibility disable "$@" --save "$config"

center=$(awk -F ' = ' '
    /^bed_shape = / {
        count=split($2, points, ",")
        for (i=1; i<=count; i++) {
            split(points[i], point, "x")
            x=point[1]+0
            y=point[2]+0
            if (i==1 || x<left) left=x
            if (i==1 || x>right) right=x
            if (i==1 || y<front) front=y
            if (i==1 || y>back) back=y
        }
        printf "%g,%g", (left+right)/2, (front+back)/2
    }
' "$config")

# Keep the model name in the slicer's object list.
mesh="$scratch/$(basename "$model" .scad).stl"
"$openscad" --hardwarnings -o "$mesh" "$model"
"$slicer" --datadir "$state" --config-compatibility disable --load "$config" \
    --center "$center" --export-3mf --output "$scratch/project.3mf" "$mesh"

# PrusaSlicer 2.9's command-line exporter omits this project setting entry.
awk '/^# / { print "; " substr($0, 3); next }
     /^[a-z][a-z0-9_]* = / { print "; " $0 }' "$config" > "$scratch/$metadata"
(cd "$scratch" && zip -q project.3mf "$metadata")
unzip -tq "$scratch/project.3mf" >/dev/null

# Reopen the archive without a settings file. Compare everything except headers.
"$slicer" --datadir "$state" --config-compatibility disable \
    --save "$scratch/reopened.ini" "$scratch/project.3mf"
sed '/^#/d' "$config" > "$scratch/expected"
sed '/^#/d' "$scratch/reopened.ini" > "$scratch/actual"
if ! cmp -s "$scratch/expected" "$scratch/actual"; then
    echo 'PrusaSlicer did not restore the saved settings.' >&2
    exit 1
fi

mv -f "$scratch/project.3mf" "$output"
printf 'Saved %s\n' "$output"
