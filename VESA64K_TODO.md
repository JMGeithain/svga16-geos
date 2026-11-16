# VESA64K – next steps

Implementation and structural build are in `vesa64k/`.

- [x] Reuse the native GeoWorks 1.x RGB565 renderer.
- [x] Add VBE mode enumeration and strict RGB565 / pitch / VRAM / banking checks.
- [x] Build fixed 800×480 and 1024×600 drivers.
- [x] Validate GEOS 1.x headers, protocols, resources and relocation table.
- [ ] Run Unicorn instruction-emulator tests.
- [ ] Test both drivers in Basebox BLD285.
- [ ] Test on physical VESA hardware that exposes the requested modes.

Do not modify the existing `SVGA16.GEO` 16-colour path as part of this work.
