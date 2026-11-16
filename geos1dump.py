#!/usr/bin/env python3
"""geos1dump.py - Parser/Dumper fuer GEOS 1.x Geodes (GeoWorks Ensemble 1.x, Signatur c7 45 cf 53).

Layout (aus pcgeos Tools/include/os90File.h + geode.h, 1.x-Varianten; am Binaer verifiziert):
  0x000 GeosFileHeader (1.x)       200 Bytes
  0x0C8 ExecutableFileHeader-Rest   24 Bytes
  0x0E0 GeodeHeader-Rest            64 Bytes
  0x120 ImportedLibraryEntry[libCount]   je 14 Bytes (name[8], attrs, proto major, minor)
        ExportEntry[exportCount]         je 4 Bytes  (offset, resourceID)
        resSize[resCount]                je 2 Bytes
        resPos[resCount]                 je 4 Bytes (Dateioffset)
        relocSize[resCount]              je 2 Bytes (Bytes)
        resFlags[resCount]               je 2 Bytes (HeapFlags|HeapAllocFlags)
  Ressource i liegt an resPos[i], Laenge resSize[i]; direkt danach (resPos+resSize) relocSize[i]
  Bytes Relocations: je 4 Bytes  info(byte: source<<4|type), extra(byte: lib-Nr), offset(word)
"""
import struct, sys, argparse

RTYPE = {0:'FAR_PTR',1:'OFFSET',2:'SEGMENT',3:'HANDLE',4:'CALL',5:'LAST_XIP'}
RSRC = {0:'KERNEL',1:'LIBRARY',2:'RESOURCE'}
RESF = [(0x0001,'SWAPPED'),(0x0002,'DISCARDED'),(0x0004,'DEBUG'),(0x0008,'LMEM'),(0x0010,'SWAPABLE'),
        (0x0020,'DISCARDABLE'),(0x0040,'SHARED'),(0x0080,'FIXED'),(0x0100,'CONFORMING'),(0x0200,'CODE'),
        (0x0400,'OBJECT'),(0x0800,'READ_ONLY'),(0x1000,'UI')]
GA = [(0x8000,'PROCESS'),(0x4000,'LIBRARY'),(0x2000,'DRIVER'),(0x1000,'KEEP_FILE_OPEN'),(0x0800,'SYSTEM'),
      (0x0400,'MULTI_LAUNCHABLE'),(0x0200,'APPLICATION'),(0x0100,'DRIVER_INIT'),(0x0080,'LIB_INIT'),
      (0x0040,'GEODE_INIT'),(0x0020,'USES_COPROC'),(0x0010,'REQ_COPROC')]

def flags(v, tab): return '|'.join(n for b,n in tab if v & b) or '0'
def cstr(b): return b.split(b'\0')[0].decode('cp437', 'replace')
W = lambda d,o: struct.unpack_from('<H', d, o)[0]

class Geode:
    def __init__(self, data, name='?'):
        self.d = d = data; self.name = name
        if d[:4] != b'\xc7\x45\xcf\x53':
            raise ValueError('keine GEOS-1.x-Signatur (c7 45 cf 53): %r' % d[:4])
        h = {}
        h['type'], h['flags'] = struct.unpack_from('<HH', d, 4)
        h['release'] = struct.unpack_from('<4H', d, 8)
        h['protocol'] = struct.unpack_from('<2H', d, 0x10)
        h['token'] = (d[0x14:0x18].decode('latin1'), W(d,0x18))
        h['creator'] = (d[0x1a:0x1e].decode('latin1'), W(d,0x1e))
        h['longName'] = cstr(d[0x20:0x44]); h['userNotes'] = cstr(d[0x44:0xa8]); h['reserved'] = cstr(d[0xa8:0xc8])
        (h['attributes'], h['fileType'], kpm, kpn, h['resourceCount'], h['importLibraryCount'],
         h['exportEntryCount'], h['udataSize'], h['classOffset'], h['classResource'],
         h['appObjChunk'], h['appObjResource']) = struct.unpack_from('<12H', d, 0xc8)
        h['kernelProtocol'] = (kpm, kpn)
        g = struct.unpack_from('<3H4H2HH', d, 0xe0)
        h['geodeAttr'], h['geodeFileType'] = g[1], g[2]
        h['geodeRelease'] = g[3:7]; h['geodeProtocol'] = g[7:9]; h['serial'] = g[9]
        h['permName'] = d[0xf4:0xfc].decode('latin1'); h['permExt'] = d[0xfc:0x100].decode('latin1')
        h['geodeToken'] = (d[0x100:0x104].decode('latin1'), W(d,0x104))
        (h['refCount'], h['driverTabOff'], h['driverTabRes'], h['libEntryOff'], h['libEntryRes'],
         h['exportLibTabOff'], h['exportCount2'], h['libCount'], h['libOffset'], h['resCount'],
         h['resHandleOff'], h['resPosOff'], h['resRelocOff']) = struct.unpack_from('<13H', d, 0x106)
        self.h = h
        o = 0x120
        self.libs = []
        for i in range(h['libCount']):
            nm = d[o:o+8].decode('latin1'); at, pm, pn = struct.unpack_from('<3H', d, o+8)
            self.libs.append((nm.strip(), at, (pm, pn), o)); o += 14
        self.exports = []
        for i in range(h['exportEntryCount']):
            self.exports.append(struct.unpack_from('<2H', d, o)); o += 4
        n = h['resCount']; self.tabOffs = {}
        self.tabOffs['size'] = o; sizes = struct.unpack_from('<%dH' % n, d, o); o += 2*n
        self.tabOffs['pos'] = o; pos = struct.unpack_from('<%dI' % n, d, o); o += 4*n
        self.tabOffs['reloc'] = o; rel = struct.unpack_from('<%dH' % n, d, o); o += 2*n
        self.tabOffs['flags'] = o; fl = struct.unpack_from('<%dH' % n, d, o); o += 2*n
        self.tabEnd = o
        self.res = []
        for i in range(n):
            relocs = []
            ro = pos[i] + sizes[i]
            for k in range(rel[i] // 4):
                info, extra, off = struct.unpack_from('<BBH', d, ro + 4*k)
                relocs.append((info, extra, off))
            self.res.append(dict(id=i, size=sizes[i], pos=pos[i], relocSize=rel[i], flags=fl[i],
                                 data=d[pos[i]:pos[i]+sizes[i]], relocs=relocs))

    def reloc_desc(self, r, data):
        info, extra, off = r
        src, typ = info >> 4, info & 0xf
        w0 = W(data, off) if off+2 <= len(data) else None
        w1 = W(data, off+2) if off+4 <= len(data) else None
        s = '%s/%s' % (RSRC.get(src,'?%d'%src), RTYPE.get(typ,'?%d'%typ))
        if src == 0: tgt = 'kernel#%d(0x%X)' % (w0, w0)
        elif src == 1: tgt = '%s#%d' % (self.libs[extra][0] if extra < len(self.libs) else 'lib%d'%extra, w0)
        else:
            tgt = 'res%d' % w0
            if typ == 4: tgt = 'res%d:%04X' % (w0, w1)
        return s, tgt

    def report(self, out=sys.stdout, disasm=True):
        h = self.h; p = lambda *a: print(*a, file=out)
        p('=== %s (%d Bytes) ===' % (self.name, len(self.d)))
        p('0x000 signature   c7 45 cf 53 ("GEOS" mit Bit7 an G,O) -> GEOS 1.x')
        p('0x004 type        %d (1.x: GFT-1 => 0=EXECUTABLE)   0x006 flags 0x%04X' % (h['type'], h['flags']))
        p('0x008 release     %d.%d.%d.%d' % h['release'])
        p('0x010 protocol    %d.%03d' % h['protocol'])
        p('0x014 token       %s/%d   0x01A creator %s/%d' % (h['token'] + h['creator']))
        p('0x020 longName    "%s"' % h['longName'])
        p('0x044 userNotes   "%s"   0x0A8 notice "%s"' % (h['userNotes'], h['reserved']))
        p('0x0C8 attributes  0x%04X %s' % (h['attributes'], flags(h['attributes'], GA)))
        p('0x0CA fileType    %d (1=APP 2=LIB 3=DRIVER)' % h['fileType'])
        p('0x0CC kernelProto %d.%03d' % h['kernelProtocol'])
        p('0x0D0 resCount %d  0x0D2 importLibs %d  0x0D4 exports %d  0x0D6 udata 0x%X' % (
            h['resourceCount'], h['importLibraryCount'], h['exportEntryCount'], h['udataSize']))
        p('0x0D8 class %04X:%04X  0x0DC appObj %04X:%04X' % (h['classResource'], h['classOffset'], h['appObjResource'], h['appObjChunk']))
        p('0x0E2 geodeAttr 0x%04X  0x0E4 geodeFileType %d' % (h['geodeAttr'], h['geodeFileType']))
        p('0x0E6 geodeRelease %d.%d.%d.%d  0x0EE geodeProtocol %d.%03d  0x0F2 serial 0x%04X' % (h['geodeRelease'] + h['geodeProtocol'] + (h['serial'],)))
        p('0x0F4 permName "%s.%s"  0x100 token %s/%d' % ((h['permName'], h['permExt']) + h['geodeToken']))
        p('0x108 driverTab  res%d:%04X   0x10C libEntry res%d:%04X' % (h['driverTabRes'], h['driverTabOff'], h['libEntryRes'], h['libEntryOff']))
        p('0x110 exportLibTabOff 0x%X  0x112 exportCount %d  0x114 libCount %d  0x118 resCount %d' % (
            h['exportLibTabOff'], h['exportCount2'], h['libCount'], h['resCount']))
        for nm, at, pr, o in self.libs:
            p('  0x%03X import "%s" attrs 0x%04X (%s) protocol %d.%03d' % (o, nm, at, flags(at, GA), pr[0], pr[1]))
        for i, (eo, er) in enumerate(self.exports):
            p('  export #%d -> res%d:%04X' % (i, er, eo))
        p('Tabellen: size@0x%X pos@0x%X reloc@0x%X flags@0x%X end@0x%X' % (self.tabOffs['size'], self.tabOffs['pos'], self.tabOffs['reloc'], self.tabOffs['flags'], self.tabEnd))
        for r in self.res:
            p('  res%d: file 0x%04X size 0x%04X relocs %d (@0x%04X) flags 0x%04X %s' % (
                r['id'], r['pos'], r['size'], r['relocSize']//4, r['pos']+r['size'], r['flags'], flags(r['flags'], RESF)))
        for r in self.res:
            if not r['size']: continue
            p('\n--- res%d (file 0x%04X, 0x%X Bytes, %s) ---' % (r['id'], r['pos'], r['size'], flags(r['flags'], RESF)))
            for rl in r['relocs']:
                s, t = self.reloc_desc(rl, r['data'])
                p('  reloc @%04X  info %02X extra %02X  %-18s -> %s' % (rl[2], rl[0], rl[1], s, t))
            if r['id'] == h['driverTabRes']:
                self.dump_drivertab(r, p)
            if r['flags'] & 0x0008:
                self.dump_lmem(r, p)
            if disasm and (r['flags'] & 0x0200):
                self.disasm(r, p)
            else:
                hexdump(r['data'], p, r['pos'])

    def dump_drivertab(self, r, p):
        d = r['data']; o = self.h['driverTabOff']
        p('  DriverInfo @%04X: strategy %04X:%04X(seg reloc) attrs 0x%04X type %d' % (o, W(d,o+2), W(d,o), W(d,o+4), W(d,o+6)))
        p('  (Folgewoerter) ' + ' '.join('%04X' % W(d,o+8+2*i) for i in range(6)))

    def dump_lmem(self, r, p):
        d = r['data']
        p('  LMem-Block, Woerter: ' + ' '.join('%04X' % W(d, 2*i) for i in range(min(len(d)//2, 28))))
        # Strings mit vorangehendem Groessenwort finden
        i = 0
        while i < len(d) - 3:
            sz = W(d, i)
            if 3 <= sz < 0x200 and i + sz <= len(d) and d[i+sz-1] == 0 and all(32 <= c < 256 for c in d[i+2:i+sz-1]):
                p('  chunk @%04X size %d: "%s"' % (i+2, sz, d[i+2:i+sz-1].decode('cp437')))
                i += sz; continue
            i += 1

    def disasm(self, r, p):
        try:
            from capstone import Cs, CS_ARCH_X86, CS_MODE_16
        except ImportError:
            hexdump(r['data'], p, r['pos']); return
        md = Cs(CS_ARCH_X86, CS_MODE_16)
        rmap = {}
        for rl in r['relocs']:
            rmap[rl[2]] = self.reloc_desc(rl, r['data'])
        data = r['data']; off = 0
        while off < len(data):
            got = False
            for ins in md.disasm(data[off:], off):
                note = ''
                for ro, (s, t) in rmap.items():
                    if ins.address <= ro < ins.address + ins.size:
                        note += '   ; RELOC %s -> %s' % (s, t)
                p('  %04X  %-20s %s %s%s' % (ins.address, ins.bytes.hex(), ins.mnemonic, ins.op_str, note))
                off = ins.address + ins.size; got = True
            if off < len(data):
                p('  %04X  %-20s db 0x%02X' % (off, '%02x' % data[off], data[off])); off += 1

def hexdump(b, p, base=0):
    for i in range(0, len(b), 16):
        c = b[i:i+16]
        p('  %04X (f%05X): %-48s %s' % (i, base+i, ' '.join('%02x' % x for x in c), ''.join(chr(x) if 32 <= x < 127 else '.' for x in c)))

if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('files', nargs='+'); ap.add_argument('--no-disasm', action='store_true')
    a = ap.parse_args()
    for f in a.files:
        g = Geode(open(f, 'rb').read(), f); g.report(disasm=not a.no_disasm); print()
