# VESA64K implementation status – GeoWorks 1.x

- [x] Reuse the native RGB565 renderer from the supplied GeoWorks 1.x `S16_1280.GEO` template.
- [x] Add independent VBE mode-list discovery; do not hardcode VBE mode IDs.
- [x] Validate packed 16-bpp Direct Color, RGB565 masks, exact geometry, scanline pitch, VRAM and bank windows.
- [x] Add fixed 800×480 and 1024×600 adapters.
- [x] Preserve native drawing, bitmap, glyph, cursor and banking routines; patch only four adapter dispatch sites and the selected device string.
- [x] Build `V800480.GEO` and `V102460.GEO`; structural GEOS 1.x geode inspection passes.
- [ ] Run Unicorn instruction-emulator tests (Unicorn 2.1.4 unavailable in this build environment).
- [ ] Test both modes in Basebox BLD285.
- [ ] Test both modes on physical VESA hardware where the BIOS exposes them.

A standard VBE mode must be present and validated on ordinary hardware. Only compatible Basebox HostIf can request a missing fixed geometry as a fallback.
