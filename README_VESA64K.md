# VESA64K – Entwicklungszweig für GeoWorks Ensemble 1.x

Dieser Zweig ergänzt das Repository um einen **separaten Entwicklungsstrang für 16-Bit-High-Color-Modi (RGB 5:6:5)**. Der bestehende, getestete Vier-Planen-Treiber `SVGA16.GEO` bleibt unverändert.

## Zielmodi

| Modus | VBE-Modus-ID (zu Laufzeit prüfen) | Auflösung | Farbtiefe | Speicherbedarf |
|---|---:|---:|---:|---:|
| 800×480×16 | `0x????` | 800×480 | 16 bpp RGB 5:6:5 | 768.000 Byte |
| 1024×600×16 | `0x????` | 1024×600 | 16 bpp RGB 5:6:5 | 1.228.800 Byte |

**Die VBE-Modus-IDs werden absichtlich nicht fest eingetragen.** VESA-Modusnummern für OEM-/VBE-Implementierungen können variieren. Der Treiber muss die Modusliste zur Laufzeit enumerieren und für jeden Treffer die Modusinformationen prüfen.

## Architekturentscheidung

Der vorhandene `SVGA16.GEO` ist ein 4-bpp-Planartreiber. Seine Routinen aus `svga16_bank.asm` setzen VGA-Planen, Bitmasken und die zugehörigen vier Schreibebenen voraus. Sie sind **kein** 16-bpp-Pixelpfad.

Der neue Treiber muss daher unabhängig davon implementiert werden:

1. VBE Controller Information via INT 10h AX=4F00h lesen.
2. Modusliste terminieren und vollständig durchlaufen.
3. Für jeden Kandidaten INT 10h AX=4F01h ausführen und mindestens `XResolution`, `YResolution`, `BitsPerPixel`, `MemoryModel`, `BytesPerScanLine`, `PhysBasePtr` sowie unterstützte Attribute prüfen.
4. 16-bpp-Modus nur bei RGB 5:6:5 / Direct Color akzeptieren. Masken aus den tatsächlichen Mode-Info-Feldern lesen, nicht blind annehmen.
5. LFB nur verwenden, wenn das Mode-Info-Attribut es ausweist und `PhysBasePtr` gültig ist. Modus mit LFB-Bit setzen (VBE 4F02h, Bit 14). Andernfalls VBE-Fenster, Granularität und Window-Segment sauber ermitteln und Bankzugriffe abstrahieren.
6. GEOS-Pixelfunktionen auf 16-Bit-Elemente portieren: Pixel setzen, horizontale/vertikale Linien, Füllungen, Screen-to-Screen- und RAM-to-Screen-Kopien, Bitmaps, Glyphen, Cursor-Save/Restore sowie Clipping.
7. Pitch aus `BytesPerScanLine` übernehmen. Niemals `width*2` voraussetzen, wenn die Hardware ein anderes Pitch meldet.
8. Speichergrenzen mit 32-Bit-Offsets berechnen. Der Laufzeitbedarf ist `BytesPerScanLine × YResolution`; die Tabellenwerte oben sind die Mindestgröße bei dichtem Pitch.

## Warum dieser Zweig zunächst nur Spezifikation / Gerüst ist

Das Repository enthält den Quellcode und das GEOS-Basisobjekt für den 4-bpp-Treiber, aber keinen nachgewiesenen vollständigen GEOS-1.x-16-bpp-Treiberpfad. Eine echte Portierung erfordert die Zuordnung der GEOS-VDI-Einstiegspunkte zu 16-Bit-Implementierungen. Ein bloßer Wechsel von Modusnamen, Modus-IDs oder Pitch-Werten würde falsche Pixelzugriffe und sehr wahrscheinlich Abstürze/Korruption erzeugen.

**Status in diesem Commit:** Spezifikation und Prüfgerüst. Es wird bewusst noch keine lauffähige `VESA64K.GEO` ausgeliefert.

## Speicherbedarf

Berechnung bei 16 bpp (2 Byte/Pixel), ohne Pitch-Padding:

- 800 × 480 × 2 = **768.000 Byte**
- 1024 × 600 × 2 = **1.228.800 Byte**

Die tatsächliche Framebuffer-Größe für die GEOS-Konfiguration ist mindestens `BytesPerScanLine × YResolution`.

## Build / Test-Plan

- `SVGA16.GEO` muss byte-identisch bleiben.
- Ein künftiger `build_vesa64k.py` muss ein eigenes GEOS-Objekt erzeugen und `VESA64K.GEO` ausgeben.
- Modusabfrage und LFB-/Bank-Fallback separat testen.
- Erst nach Implementierung der 16-bpp-VDI-Routinen in DOSBox/BaseBox und, soweit verfügbar, auf realer VESA-Hardware testen.
- Regression: vorhandene 640×480, 800×600, 1024×768 und 1280×1024 ×16 bleiben mit `SVGA16.GEO` unverändert verfügbar.

## Referenzen im Repository

- `svga16_multi.asm`: bestehende VBE-Moduswahl und Multi-Mode-Geometrie (4 bpp).
- `svga16_bank.asm`: Banking und planare Zeichen-/Kopierpfade (4 bpp).
- `build_svga16.py`: Erzeugung des bisherigen `SVGA16.GEO`.

