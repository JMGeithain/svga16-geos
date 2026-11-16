# VESA64K – GeoWorks 1.x RGB565 video drivers

Two additional native GeoWorks Ensemble / GeoWorks Pro **1.x** drivers use the existing RGB565 renderer from the supplied `S16_1280.GEO` template:

| Driver | GEOS device | Target | Format |
|---|---|---:|---|
| `V800480.GEO` | `VESA Compatible SuperVGA: 800x480 64K-color` | 800×480 | 16-bit RGB565 / 65,536 colors |
| `V102460.GEO` | `VESA Compatible SuperVGA: 1024x600 64K-color` | 1024×600 | 16-bit RGB565 / 65,536 colors |

`V16_0720.GEO` is retained as a reference/regression build for 1280×720.

## Implementation

- Retains the native raster, drawing, banking, pointer and save-under routines from the supplied GeoWorks 1.x RGB565 driver.
- Adds an independent 16-bit adapter for VBE controller/mode-list discovery.
- Validates exact geometry, 16 bpp, Direct Color model, RGB565 component masks, scanline pitch, VRAM capacity and usable 64-KiB bank windows.
- Discovers VBE mode IDs at runtime; no assumed mode number is hardcoded.
- If the exact mode is absent from the VBE list, a compatible Basebox HostIf may request the same fixed geometry. This fallback is Basebox-specific; ordinary DOSBox or physical hardware must expose the requested VBE mode itself.

## Build

Requirements: Python 3 and GNU binutils (`as`, `ld`, `objcopy`, `nm`). Copy the exact `S16_1280.GEO` template into `vendor/` as explained in `vendor/README.md`. Then run:

```sh
python3 build_vesa64k.py
```

The script verifies the template SHA-256, assembles one adapter per geometry, patches four documented native dispatch operands and the selected device-name handle/string, retains all 73 native relocation records, and validates each output with `inspect_geodes.py`.

Template SHA-256: `5c56db2b0c39ac66e7448a672a68c8722876b547c7822a006cd31da26f98654d`.

## Installation

Copy the chosen `.GEO` to `GEOWORKS/SYSTEM` and configure `[screen 0]` in `GEOS.INI`:

```ini
[screen 0]
driver = V800480.GEO
device = VESA Compatible SuperVGA: 800x480 64K-color
```

For 1024×600, use `V102460.GEO` and its matching device string. Back up `GEOS.INI` first. If startup fails, exit the emulator and restore the previous driver/device settings from the host.

## Validation status

### Build and static validation

- Build completed; all three fixed VESA outputs pass structural GEOS 1.x geode inspection.
- The original native renderer bytes are retained unchanged; the builder asserts this.
- VBE discovery, mode validation and RGB565 checks are implemented.
- Unicorn instruction-emulator tests were not run: Unicorn 2.1.4 is not installed and cannot be downloaded in this environment.

### Basebox runtime validation – 16 November 2026

- **800×480×64K:** user-confirmed successful selection and operation in Basebox.
- **1024×600×64K:** user-confirmed successful operation; the supplied screenshots show GeoWorks running with the 1024×600 device selected.
- The RGB565 colour-proof application ran and displayed the expected native RGB colour gradients (32 red, 64 green and 32 blue levels).
- The display test returned to the GeoWorks desktop; no crash was reported.
- These results validate both requested modes in the user's Basebox environment. They do not establish compatibility with physical VESA hardware or unrelated emulators.

### Still open

- Physical VESA hardware tests where the BIOS exposes the requested modes.
- Unicorn instruction-emulator tests, if a suitable environment becomes available.

## Provenance

`vendor/S16_1280.GEO` is the exact supplied native GeoWorks 1.x RGB565 renderer template. Its original ownership is retained; this repository does not relicense that binary. The adapter/build additions are marked Apache-2.0 in their source headers.
