#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Build native GeoWorks 1.x RGB565 VESA drivers from the preserved renderer."""
from pathlib import Path
import hashlib, json, struct, subprocess, sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from inspect_geodes import inspect

TEMPLATE = HERE / "vendor" / "S16_1280.GEO"
EXPECTED = "5c56db2b0c39ac66e7448a672a68c8722876b547c7822a006cd31da26f98654d"
ORIGIN = 0x7B20
VARIANTS = [
    ("V800480.GEO", 800, 480, 0x30,
     "VESA Compatible SuperVGA: 800x480 64K-color",
     "VESA SVGA 800x480 64K"),
    ("V102460.GEO", 1024, 600, 0x34,
     "VESA Compatible SuperVGA: 1024x600 64K-color",
     "VESA SVGA 1024x600 64K"),
    ("V16_0720.GEO", 1280, 720, 0x3C,
     "VESA Compatible SuperVGA: 1280x720 64K-color",
     "VESA SVGA 1280x720 64K"),
]


def sha(data):
    return hashlib.sha256(data).hexdigest()


def putword(data, offset, value):
    struct.pack_into("<H", data, offset, value)


def compile_adapter(stem, width, height):
    work = HERE / "intermediate" / stem
    work.mkdir(parents=True, exist_ok=True)
    source = (
        f".equ KIND_BASEBOX,0\n.equ REQUEST_DPI,136\n"
        f".equ TARGET_WIDTH,{width}\n.equ TARGET_HEIGHT,{height}\n"
        + (HERE / "adapter.S").read_text()
    )
    (work / "adapter.S").write_text(source)
    commands = [
        ["as", "--32", "--fatal-warnings", "-o",
         str(work / "adapter.o"), str(work / "adapter.S")],
        ["ld", "-m", "elf_i386", "-Ttext", hex(ORIGIN), "-e", "InitFar",
         "-o", str(work / "adapter.elf"), str(work / "adapter.o")],
        ["objcopy", "-O", "binary", "--only-section=.text",
         str(work / "adapter.elf"), str(work / "adapter.bin")],
    ]
    for command in commands:
        subprocess.run(command, check=True, capture_output=True, text=True)

    symbols = {}
    for line in subprocess.check_output(
            ["nm", "-n", str(work / "adapter.elf")], text=True).splitlines():
        fields = line.split()
        if len(fields) == 3 and fields[1].lower() in ("t", "d", "b"):
            symbols[fields[2]] = int(fields[0], 16)

    code = (work / "adapter.bin").read_bytes()
    assert symbols["InitFar"] == ORIGIN
    assert symbols["AdapterEnd"] == ORIGIN + len(code)
    assert ORIGIN + len(code) < 0x10000
    return code, symbols, commands


def build_one(original, filename, width, height, string_handle, device, title):
    stem = filename.rsplit(".", 1)[0]
    code, symbols, commands = compile_adapter(stem, width, height)

    header = bytearray(original[:318])
    resource1 = bytearray(original[318:26686])
    reloc1 = original[26686:26974]
    resource2 = bytearray(original[26974:28750])
    reloc2 = original[28750:28754]

    assert len(resource1) == 0x6700
    assert struct.unpack_from("<H", header, 214)[0] == 0x141A
    assert struct.unpack_from("<H", resource2, 0x10)[0] == 1
    assert struct.unpack_from("<H", resource2, 0x12)[0] == 0x16
    assert struct.unpack_from("<H", resource2, 0x16)[0] == 0x46
    assert resource1[0x4D3:0x4D6] == bytes.fromhex("bc1a7b")
    assert resource1[0x625C:0x6263] == bytes.fromhex("5051525356061e")
    assert resource1[0xB8:0xBC] == bytes.fromhex("12160100")
    assert resource1[0xC8:0xCC] == bytes.fromhex("65160100")
    assert resource1[0x248:0x24A] == bytes.fromhex("9c60")
    assert resource1[0x290:0x292] == bytes.fromhex("5c62")

    string_pos = struct.unpack_from("<H", resource2, string_handle)[0]
    current_device = bytes(resource2[string_pos:]).split(b"\0", 1)[0].decode("ascii")
    if current_device != device:
        next_pos = struct.unpack_from("<H", resource2, string_handle + 2)[0]
        assert next_pos > string_pos
        slot_size = next_pos - string_pos
        encoded = device.encode("ascii") + b"\0"
        assert len(encoded) <= slot_size, (device, len(encoded), slot_size)
        resource2[string_pos:next_pos] = encoded.ljust(slot_size, b"\0")

    patches = []
    for offset, symbol in (
        (0xB8, "InitFar"), (0xC8, "ProbeFar"),
        (0x248, "ProbeNear"), (0x290, "SetupNear")
    ):
        old = struct.unpack_from("<H", resource1, offset)[0]
        putword(resource1, offset, symbols[symbol])
        patches.append({
            "resource": 1, "offset": offset, "old_word": old,
            "new_word": symbols[symbol], "reason": symbol
        })

    resource1.extend(b"\0" * (ORIGIN - len(resource1)))
    assert len(resource1) == ORIGIN
    resource1.extend(code)

    putword(resource2, 0x16, string_handle)
    putword(header, 214, 0)
    title_bytes = title.encode("ascii")
    assert len(title_bytes) < 36
    header[32:68] = title_bytes + b"\0" * (36 - len(title_bytes))
    header[244:252] = stem.lower().encode("ascii").ljust(8, b" ")

    serial = int.from_bytes(
        hashlib.sha256(stem.encode() + code).digest()[:2], "little") or 1
    putword(header, 242, serial)
    putword(header, 14, 1)
    putword(header, 236, 1)

    size1 = len(resource1)
    padded1 = (size1 + 15) & ~15
    start2 = 318 + padded1 + len(reloc1)
    putword(header, 290, size1)
    struct.pack_into("<I", header, 302, start2)

    output = (
        bytes(header) + bytes(resource1)
        + b"\0" * (padded1 - size1)
        + reloc1 + bytes(resource2) + reloc2
    )
    destination = HERE / "drivers" / filename
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(output)

    parsed = inspect(destination)
    assert parsed["validation_errors"] == []
    assert parsed["format"] == "GEOS 1.x geode"
    assert parsed["kernel_protocol"] == [622, 3]
    assert parsed["geode_protocol"] == [601, 0]
    assert parsed["udata_size"] == 0
    assert parsed["relocation_count"] == 73
    assert parsed["import_count"] == 0

    changed = [
        i for i in range(0x6700)
        if resource1[i] != original[318 + i]
    ]
    allowed = {
        offset + byte
        for offset in (0xB8, 0xC8, 0x248, 0x290)
        for byte in (0, 1)
    }
    assert set(changed) <= allowed

    manifest = {
        "filename": filename,
        "bytes": len(output),
        "sha256": sha(output),
        "template_sha256": EXPECTED,
        "geometry": {"width": width, "height": height},
        "pixel_format": "RGB565",
        "bpp": 16,
        "colors": 65536,
        "device": device,
        "mode_selection": (
            "Enumerate VBE list; validate exact RGB565 geometry; if absent, "
            "use compatible Basebox HostIf fixed-size fallback only"
        ),
        "adapter_bytes": len(code),
        "adapter_sha256": sha(code),
        "symbols": symbols,
        "patches": patches,
        "retained_native_renderer_sha256": sha(original[318:26686]),
        "relocations_retained": 73,
        "validation": (
            "GEOS 1.x geode structural inspection passed; runtime not yet tested"
        ),
        "commands": commands,
    }
    (HERE / "drivers" / (filename + ".json")).write_text(
        json.dumps(manifest, indent=2) + "\n"
    )
    return manifest


def main():
    if not TEMPLATE.exists():
        raise FileNotFoundError(
            "Copy S16_1280.GEO from the supplied Basebox-SVGA-Ensemble12 "
            "package into vesa64k/vendor/"
        )
    original = TEMPLATE.read_bytes()
    assert sha(original) == EXPECTED, "Unexpected S16_1280.GEO template"

    manifests = [build_one(original, *variant) for variant in VARIANTS]
    (HERE / "drivers" / "MANIFEST.json").write_text(
        json.dumps(manifests, indent=2) + "\n"
    )
    print(json.dumps([
        {key: item[key] for key in (
            "filename", "bytes", "sha256", "geometry", "adapter_bytes"
        )}
        for item in manifests
    ], indent=2))


if __name__ == "__main__":
    main()
