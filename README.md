# scad-print

A small tool I use to turn an OpenSCAD file into a PrusaSlicer project with my print settings saved inside.

On my Mac I use `brew bundle` to install OpenSCAD and PrusaSlicer. You'll also need Make, zip, and unzip. I tested this with PrusaSlicer 2.9.6.

```sh
make project
open -a PrusaSlicer build/print.3mf
```

That builds the sample cube. Open the 3MF as a project to see the settings. To use another model:

```sh
make project MODEL=part.scad SETTINGS=print.ini OUT=build/part.3mf
```

`print.ini` sets layer height, walls, infill, and skirt. The preview uses PrusaSlicer's default printer and filament. To use your own, export a full config from PrusaSlicer, save it under `local/`, and add `PROFILE=local/printer.ini` to the command. The part settings go on top of that profile.

`make check` builds the cube and checks that PrusaSlicer reads the settings back out of the 3MF.
