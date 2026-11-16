# SVGA16 – Super-VGA 16 Farben für GeoWorks 1.x

Videotreiber-Add-on für **GeoWorks Ensemble 1.x**: 640×480, 800×600, 1024×768, 1280×1024 (je 16 Farben).

## Download / Installation

1. [`dist/SVGA16.GEO`](dist/SVGA16.GEO) nach `GEOWORKS\SYSTEM` kopieren.
2. In der INI bzw. unter Voreinstellungen → Video z. B.:

```ini
driver = SVGA16.GEO
device = VESA Kompatible Super VGA: 1024x768 16 Farben
info = 16384
```

Weitere Geräte (Präfix `VESA Kompatible Super VGA: `): `640x480 16 Farben`, `800x600 16 Farben`, `1280x1024 16 Farben`.

3. Neu starten. Modus in der Liste **mit der Maus** wählen (nicht Return). Im SETUP-Testbild **Enter** (nicht F10).

## SHA-256

```
ffb971527acce57f4e685777ee22ad4977a2f6e0a4933d0bcb988df5af45af85  dist/SVGA16.GEO
```

Build-Stand: **ffb97152** (u. a. Fix gegen Menü-Schmierspur bei 1024/1280).

## Inhalt

- `dist/SVGA16.GEO` – fertiger Treiber
- `svga16_*.asm`, `gen_mul2.inc`, `build_svga16.py` – Patch-/Build-Quellen
- `CHANGELOG.md`, `PLAN.md` – Technik und Historie
- `docs/` – Beispiel-Screenshots

**Nicht enthalten:** GeoWorks-Installation und Original-Basis-Treiber (`SVGA8004` o. Ä.). Zum Neubauen lokal die Basis aus *eurer* Installation bereitstellen.

---

## Hinweis: mit KI erstellt

**Dieser Treiber und diese Dokumentation wurden mit KI erstellt** (u. a. Grok Bot / Cursor-Agenten), begleitet und getestet von Valentin Möller und Johannes Möller. Community-/Hobby-Projekt, kein offizielles GeoWorks-Produkt.
