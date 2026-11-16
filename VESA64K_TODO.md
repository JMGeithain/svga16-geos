# VESA64K implementation checklist (GeoWorks 1.x)

- [ ] Confirm exact SVGA8004/GeoWorks 1.x VDI strategy entry points for each drawing primitive.
- [ ] Implement VBE 4F00h controller/mode-list enumeration.
- [ ] Implement VBE 4F01h mode-info validation for packed 16-bpp Direct Color.
- [ ] Implement VBE 4F02h mode set with LFB request and verified bank fallback.
- [ ] Define a 32-bit framebuffer offset abstraction using reported BytesPerScanLine.
- [ ] Implement packed RGB pixel write/read and mask/shift conversion.
- [ ] Port horizontal/vertical line, fill, blit, glyph/bitmap, clipping, pointer and save-under.
- [ ] Add build_vesa64k.py producing VESA64K.GEO without modifying SVGA16.GEO.
- [ ] Validate output with geos1dump.py and run the GEOS 1.x test matrix.
- [ ] Verify 800x480x16 and 1024x600x16 on a VBE implementation exposing these modes.

No binary driver is provided until all code and runtime tests pass.
