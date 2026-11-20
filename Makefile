MODEL ?= cube.scad
SETTINGS ?= print.ini
PROFILE ?=
OUT ?= build/print.3mf
OPENSCAD ?= openscad
SLICER ?=

export MODEL SETTINGS PROFILE OUT OPENSCAD SLICER

.PHONY: project check

project:
	sh scripts/build-project.sh "$$MODEL" "$$SETTINGS" "$$OUT"

check:
	sh -n scripts/build-project.sh
	@mkdir -p build
	@set -eu; \
		scratch=$$(mktemp -d build/check.XXXXXX); \
		trap 'rm -rf "$$scratch"' EXIT; \
		PROFILE= sh scripts/build-project.sh cube.scad print.ini "$$scratch/cube.3mf"; \
		unzip -p "$$scratch/cube.3mf" Metadata/Slic3r_PE.config > "$$scratch/settings"; \
		for setting in 'layer_height = 0.2' 'perimeters = 4' 'fill_pattern = gyroid'; do \
			grep -Fqx "; $$setting" "$$scratch/settings"; \
		done; \
		echo 'Cube project check passed.'
