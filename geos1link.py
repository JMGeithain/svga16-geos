#!/usr/bin/env python3
"""geos1link.py - Schreiben/Umbauen von GEOS-1.x-Geodes (Gegenstueck zu geos1dump.py).

Funktionen:
  load(path)            -> Geode (aus geos1dump), mit veraenderbaren Ressourcen
  serialize(geode)      -> bytes (neu layoutet: Header, Lib-, Export-, Ressourcentabellen, Ressourcen+Relocs)
  make_ext_info(names, infos) -> LMem-Block fuer DriverExtendedInfoTable (1.x-Layout wie in GENMOUSE/PS2/ABSGEN)
Selbsttest:  python3 geos1link.py --roundtrip DATEI...   (muss byte-identisch reproduzieren)
"""
import struct, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from geos1dump import Geode

def load(path):
    g = Geode(open(path, 'rb').read(), path)
    for r in g.res:
        r['data'] = bytearray(r['data']); r['relocs'] = list(r['relocs'])
    return g

def set_str(buf, off, size, s):
    b = s.encode('cp437')
    assert len(b) < size, s
    buf[off:off+size] = b + b'\0' * (size - len(b))

def serialize(g):
    d = bytearray(g.d[:0x120])
    n = len(g.res)
    struct.pack_into('<H', d, 0xD0, n); struct.pack_into('<H', d, 0x118, n)
    out = bytearray(d)
    for nm, at, pr, _ in g.libs:
        out += nm.encode('latin1').ljust(8, b' ') + struct.pack('<3H', at, pr[0], pr[1])
    for eo, er in g.exports:
        out += struct.pack('<2H', eo, er)
    tab = len(out)
    out += b'\0' * (n * 10)
    pos = len(out); sizes = []; poss = []; rels = []
    for r in g.res:
        sizes.append(len(r['data'])); poss.append(pos if r['data'] or r['id'] else pos)
        rb = b''.join(struct.pack('<BBH', *rl) for rl in r['relocs'])
        rels.append(len(rb))
        out += r['data'] + rb; pos = len(out)
    o = tab
    for v in sizes: struct.pack_into('<H', out, o, v); o += 2
    for v in poss: struct.pack_into('<I', out, o, v); o += 4
    for v in rels: struct.pack_into('<H', out, o, v); o += 2
    for r in g.res: struct.pack_into('<H', out, o, r['flags']); o += 2
    return bytes(out)

def align(v, a): return (v + a - 1) // a * a

def make_ext_info(res_id, names, infos):
    """LMem-Block wie vom 1.x-Esp erzeugt: LMBH(16) | DEIT(numDevices,nameTable,infoTable) |
    nameTable (lptr[], 0-terminiert) | infoTable (word[]) | Handletabelle @align16 | Chunks (Groessenwort, Daten @4n+2)."""
    n = len(names)
    nameTab = 0x16
    infoTab = nameTab + 2 * (n + 1)
    tabEnd = infoTab + 2 * n
    hOff = align(tabEnd, 16)
    nH = align(n, 2)
    cpos = hOff + 2 * nH
    blk = bytearray(cpos)
    chunks = []
    for s in names:
        b = s.encode('cp437') + b'\0'
        start = align(cpos, 4) if align(cpos, 4) + 2 > cpos else cpos
        start = align(cpos, 4)
        blk += b'\xcc' * (start - len(blk))
        blk += struct.pack('<H', len(b) + 2) + b
        chunks.append(start + 2); cpos = len(blk)
    blockSize = align(len(blk), 4)
    blk += b'\xcc' * (blockSize - len(blk))
    struct.pack_into('<8H', blk, 0, res_id, hOff, 0, 0, blockSize, nH, 0, 0)
    struct.pack_into('<3H', blk, 0x10, n, nameTab, infoTab)
    for i in range(n):
        struct.pack_into('<H', blk, nameTab + 2*i, hOff + 2*i)
        struct.pack_into('<H', blk, infoTab + 2*i, infos[i])
        struct.pack_into('<H', blk, hOff + 2*i, chunks[i])
    resSize = align(blockSize, 16)
    blk += b'\0' * (resSize - len(blk))
    return blk

if __name__ == '__main__':
    if sys.argv[1] == '--roundtrip':
        ok = True
        for f in sys.argv[2:]:
            a = open(f, 'rb').read(); b = serialize(load(f))
            print('%-40s %s' % (f, 'OK' if a == b else 'DIFF (%d vs %d)' % (len(a), len(b)))); ok &= a == b
        sys.exit(0 if ok else 1)
