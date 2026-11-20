// Setup check: all dimensions are in millimetres.
size_mm = 20;
assert(size_mm > 0, "Cube size must be positive.");
cube([size_mm, size_mm, size_mm]);
