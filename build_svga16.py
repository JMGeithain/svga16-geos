#!/usr/bin/env python3
"""build_svga16.py — SVGA16.GEO Multi-Mode + Cave-Banking (NextScan)."""
import os, struct, sys, hashlib, subprocess, re
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import geos1link as L
from geos1dump import Geode

BASE = os.path.join(ROOT, 'drivers_video', 'SVGA8004_de.GEO')
BLOB_OFF = 0x2C40
BLOB_LIMIT = 0x3009
RES1_LEN = 0x4460
# Laufzeit-Variablen des Originals liegen bei 0x4460..0x45BB (hinter den Dateidaten)!
# Die Cave darf dort NICHT liegen -> hinter den Variablenbereich legen.
CAVE_OFF = 0x4600
VID_TEST_TAB = 0x13F
VID_SET_TAB  = 0x165
NUM = 4
MASKBUF_REFS = (0x0B99, 0x0C56, 0x22A9, 0x2493)

NAMES = [
    'VESA Kompatible Super VGA: 640x480 16 Farben',
    'VESA Kompatible Super VGA: 800x600 16 Farben',
    'VESA Kompatible Super VGA: 1024x768 16 Farben',
    'VESA Kompatible Super VGA: 1280x1024 16 Farben',
]

ADD_PITCH8 = [
    0x3009, 0x305E, 0x30C7, 0x30D9, 0x30EB,
    0x345A, 0x34FA, 0x3544, 0x357C, 0x35BF, 0x3623,
]

def parse_syms(lst_path, base=0):
    """Label auf eigener Zeile; naechste Zeile mit Hex-Bytes liefert die Adresse."""
    lines = open(lst_path).readlines()
    syms = {}
    label_re = re.compile(r'^\s*\d+\s+([A-Za-z_][A-Za-z0-9_]*):\s*$')
    data_re = re.compile(r'^\s*\d+\s+([0-9A-Fa-f]+)\s+[0-9A-Fa-f]{2}')
    for i, line in enumerate(lines):
        m = label_re.match(line)
        if not m:
            continue
        name = m.group(1)
        for j in range(i + 1, min(i + 8, len(lines))):
            m2 = data_re.match(lines[j])
            if m2:
                syms[name] = base + int(m2.group(1), 16)
                break
    return syms

# (Adresse, r, T, Stub) -- r = r*pitch + T  (Original: 18 Byte Shift-Folge fuer *100)
MUL2 = [(0x050D, 3, 0, 'MulBXAX'), (0x1750, 3, 6, 'MulBX0'), (0x1766, 2, 7, 'MulDX0'),
        (0x18B6, 6, 1, 'MulSI0'), (0x2061, 6, 0, 'MulSIAX')]

def mul100(r, T):
    sh = bytes([0xD1, 0xE0 + r])
    return sh*2 + bytes([0x03, 0xC0 + T*8 + r]) + sh*3 + bytes([0x03, 0xC0 + T*8 + r]) + sh + bytes([0x03, 0xC0 + r*8 + T])

def mul80(r, T):
    sh = bytes([0xD1, 0xE0 + r])
    return sh*4 + bytes([0x03, 0xC0 + T*8 + r]) + sh*2 + bytes([0x03, 0xC0 + r*8 + T]) + b'\x90\x90'

def gen_mul2_inc(orig):
    out = ['mul2Tab:']
    for a, r, T, stub in MUL2:
        assert orig[a:a+18] == mul100(r, T), (hex(a), orig[a:a+18].hex(), mul100(r,T).hex())
        out.append('        dw 0x%04X, %s' % (a, stub))
        out.append('        db ' + ','.join('0x%02X' % b for b in mul80(r, T)))
    out.append('        dw 0')
    open(os.path.join(ROOT, 'src', 'gen_mul2.inc'), 'w').write('\n'.join(out) + '\n')

def build():
    g = L.load(BASE)
    res1, res2 = g.res[1], g.res[2]
    d = bytearray(res1['data'])
    assert len(d) == RES1_LEN, hex(len(d))
    gen_mul2_inc(bytes(d))
    d.extend(b'\0' * (CAVE_OFF - RES1_LEN))

    multi_asm = os.path.join(ROOT, 'src', 'svga16_multi.asm')
    bank_asm = os.path.join(ROOT, 'src', 'svga16_bank.asm')
    multi_bin = os.path.join(ROOT, 'build', 'svga16_multi.bin')
    bank_bin = os.path.join(ROOT, 'build', 'svga16_bank.bin')
    multi_lst = multi_bin + '.lst'
    bank_lst = bank_bin + '.lst'

    subprocess.check_call([
        'nasm', '-f', 'bin', '-o', multi_bin, multi_asm, '-l', multi_lst,
        '-DINSTALL_ADD_PITCH=%d' % CAVE_OFF,
    ])
    blob = bytearray(open(multi_bin, 'rb').read())
    assert len(blob) <= BLOB_LIMIT - BLOB_OFF, 'blob %d > limit' % len(blob)
    msyms = parse_syms(multi_lst, BLOB_OFF)
    need = ('MultiTest', 'MultiSet', 'CalcOffsetBP', 'CalcOffset0',
            'SetVESABank', 'pitch', 'curBank', 'lastDI', 'useBanking', 'modeTable')
    for n in need:
        assert n in msyms, (n, sorted(msyms))

    # 2026-10-30: S2S-SW-Kopie (FORCESW) ist Standard; HWCOPY=1 reaktiviert den HW-Pfad 36DA/37C7
    subprocess.check_call([
        'nasm', '-f', 'bin', '-i', os.path.join(ROOT, 'src') + '/', '-o', bank_bin, bank_asm, '-l', bank_lst,
        '-DCAVE=%d' % CAVE_OFF,
        '-DSETVESABANK=%d' % msyms['SetVESABank'],
        '-DPITCH=%d' % msyms['pitch'],
        '-DCURBANK=%d' % msyms['curBank'],
        '-DLASTDI=%d' % msyms['lastDI'],
        '-DUSEBANKING=%d' % msyms['useBanking'],
        '-DMODETABLE=%d' % msyms['modeTable'],
        '-DMULTITEST=%d' % msyms['MultiTest'],
        '-DMULTISET=%d' % msyms['MultiSet'],
    ] + (['-DTRACE'] if os.environ.get('TRACE') else []) + (['-DFORCESW'] if (os.environ.get('FORCESW') or not os.environ.get('HWCOPY')) else []) + (['-DNOFUNC'] if os.environ.get('NOFUNC') else []) + (['-DSAMPLE'] if os.environ.get('SAMPLE') else []) + ['-DNO%s' % x for x in os.environ.get('SKIP', '').split(',') if x] + [
    ])
    cave = bytearray(open(bank_bin, 'rb').read())
    while len(cave) % 16:
        cave.append(0)
    bsyms = parse_syms(bank_lst, CAVE_OFF)
    for n in ('InstallAddPitch', 'NextScanDI', 'NextScanSI'):
        assert n in bsyms, (n, sorted(bsyms))
    assert bsyms['InstallAddPitch'] == CAVE_OFF, hex(bsyms['InstallAddPitch'])

    d[BLOB_OFF:BLOB_OFF + len(blob)] = blob
    d.extend(cave)

    # Clipmasken-Puffer 0x44D8 (100 Byte) -> maskBuf (192 Byte) in der Cave
    for a in MASKBUF_REFS:
        assert struct.unpack_from('<H', d, a)[0] == 0x44D8, hex(a)
        struct.pack_into('<H', d, a, bsyms['maskBuf'])

    for src in ADD_PITCH8:
        assert d[src] == 0x83 and d[src + 2] == 0x64, hex(src)

    tt, ts = msyms['MultiTest'], msyms['MultiSet']
    if os.environ.get('TRACE'):
        tt, ts = bsyms['TraceTest'], bsyms['TraceSet']
    if os.environ.get('SAMPLE'):
        ts = bsyms['SampleSet']
    for i in range(NUM):
        struct.pack_into('<H', d, VID_TEST_TAB + 2 * i, tt)
        struct.pack_into('<H', d, VID_SET_TAB + 2 * i, ts)

    struct.pack_into('<5H', d, 0x0E, 600, 800, 80, 80, 400)

    res1['data'] = d
    res2['data'] = L.make_ext_info(2, NAMES, [0] * NUM)
    if not any(r[2] == 0 for r in res2['relocs']):
        res2['relocs'].append((35, 0, 0))

    hdr = bytearray(g.d)
    L.set_str(hdr, 0x20, 36, 'Super VGA 16-clr VESA Multi')
    hdr[0xF4:0xFC] = b'svga16  '
    g.d = bytes(hdr)

    out = L.serialize(g)
    dst = os.path.join(ROOT, 'build', os.environ.get('OUTNAME', 'SVGA16.GEO'))
    open(dst, 'wb').write(out)
    Geode(out, dst)
    sha = hashlib.sha256(out).hexdigest()
    print('%s: %d Bytes, sha256 %s' % (dst, len(out), sha))
    print('  multi blob=%d cave=%d res1=%d' % (len(blob), len(cave), len(d)))
    print('  NextScanDI=%s NextScanSI=%s' % (hex(bsyms['NextScanDI']), hex(bsyms['NextScanSI'])))
    return dst, sha

if __name__ == '__main__':
    build()
