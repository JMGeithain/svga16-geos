# VESA64K – GeoWorks 1.x RGB565

Separate 16-bit RGB565 development track for the native GeoWorks 1.x renderer.

## Target drivers

| Driver | Resolution | Colour depth |
|---|---:|---:|
| `V800480.GEO` | 800×480 | 65,536 colours, RGB565 |
| `V102460.GEO` | 1024×600 | 65,536 colours, RGB565 |
| `V16_0720.GEO` | 1280×720 | 65,536 colours, RGB565 (reference build) |

The original `SVGA16.GEO` 4-bpp driver remains unchanged.

## Implementation and build

The new adapter reuses the native RGB565 raster, banking, drawing and pointer renderer from the supplied GeoWorks 1.x `S16_1280.GEO` template. It enumerates the VBE mode list and validates exact geometry, 16 bpp, Direct Color, RGB565 masks, pitch, VRAM and 64-KiB bank windows. It never guesses a VBE mode number.

Source, build instructions and generated manifests are in [`vesa64k/`](vesa64k/README.md). The exact template must be copied into `vesa64k/vendor/` as described there.

## Current validation

The two requested driver binaries were built and passed structural GEOS 1.x geode validation: correct kernel/video protocols, 3 resources, zero imports, zero UDATA, and all 73 original relocation records retained. The native renderer resource is preserved unchanged.

**Not yet runtime-verified:** Unicorn instruction tests could not run because Unicorn is unavailable in the build environment; Basebox desktop tests and physical VESA hardware tests for the new modes remain outstanding. The drivers are development builds, not a runtime-accepted release.

See [`vesa64k/VESA64K_TODO.md`](vesa64k/VESA64K_TODO.md) for remaining tests.
