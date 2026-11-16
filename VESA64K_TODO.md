# VESA64K – next steps

Implementation, structural build validation and the user's Basebox runtime tests are documented in `vesa64k/`.

- [x] Reuse the native GeoWorks 1.x RGB565 renderer.
- [x] Add VBE mode enumeration and strict RGB565 / pitch / VRAM / banking checks.
- [x] Build fixed 800×480 and 1024×600 drivers.
- [x] Validate GEOS 1.x headers, protocols, resources and relocation table.
- [x] User-confirmed Basebox runtime tests for both 800×480×64K and 1024×600×64K.
- [x] Confirm RGB565 colour-proof output and return to the GeoWorks desktop.
- [ ] Test on physical VESA hardware that exposes the requested modes.
- [ ] Run Unicorn instruction-emulator tests, if a suitable environment becomes available.

Do not modify the existing `SVGA16.GEO` 16-colour path as part of this work.
