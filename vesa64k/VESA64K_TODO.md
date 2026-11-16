# VESA64K implementation status – GeoWorks 1.x

- [x] Reuse the native RGB565 renderer from the supplied GeoWorks 1.x `S16_1280.GEO` template.
- [x] Add independent VBE mode-list discovery; do not hardcode VBE mode IDs.
- [x] Validate packed 16-bpp Direct Color, RGB565 masks, exact geometry, scanline pitch, VRAM and bank windows.
- [x] Add fixed 800×480 and 1024×600 adapters.
- [x] Preserve native drawing, bitmap, glyph, cursor and banking routines; patch only four adapter dispatch sites and the selected device string.
- [x] Build `V800480.GEO` and `V102460.GEO`; structural GEOS 1.x geode inspection passes.
- [x] User-confirmed Basebox runtime test of 800×480×64K and 1024×600×64K (16 November 2026).
- [x] RGB565 colour-proof application displayed native colour gradients; GeoWorks returned to the desktop without a reported crash.
- [ ] Test both modes on physical VESA hardware where the BIOS exposes them.
- [ ] Run Unicorn instruction-emulator tests, if a suitable environment becomes available (Unicorn 2.1.4 was unavailable in the build environment).

The Basebox runtime confirmation applies to the user's Basebox environment only. A standard VBE mode must be present and validated on ordinary hardware. Only compatible Basebox HostIf can request a missing fixed geometry as a fallback.
