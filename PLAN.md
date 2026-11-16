# SVGA16.GEO – Plan & Status (GeoWorks 1.x)

Stand: 2026-11-15 13:20 (Europe/Berlin)

## Aktuelles Ergebnis

**Datei:** `build/SVGA16.GEO` (Checkpoint `build/SVGA16_ffb97152_su.GEO`) — **nicht ersetzt**
**SHA-256:** `ffb971527acce57f4e685777ee22ad4977a2f6e0a4933d0bcb988df5af45af85`
**Vorher:** abcf310e → Backup `build/bak_abcf310e_pre_menusmear.GEO`; diese Testrunde: `build/bak_ffb97152_pre_modetest.GEO`

Lokale BaseBox (nicht echte Hardware): Menü-Schmierspur weiter **behoben** (InstallSU, pitch≥128). Zusätzlich Mode-Test nach Grafikwechsel in allen vier Modi **ok** (vier Eckpfeile, ENTER-Bestätigung, kein Hänger; Vater-Hang mit schwarzem Bild/Quadraten hier nicht reproduziert). SaveUnder-Ablehnen ohne Lücken/Müll bei 1024/1280; **kein RAM-Backing nötig**.

| Mode | Mode-Test (Pfeile/ENTER) | SaveUnder-Regression | Smoke (Start/Maus/Prefs, 1280+Drag) |
|------|--------------------------|----------------------|-------------------------------------|
| 640×480 | OK | (nicht SU-kritisch, pitch 80) | OK |
| 800×600 | OK | Original-Puffer bleibt, Menü sauber | OK |
| 1024×768 | OK | Dialog/Prefs über Icons, nach Schließen sauber | OK |
| 1280×1024 | OK | Dialog, Express-Menü, Drag, Maus sauber | OK |

Offen: Mode-Test und SaveUnder-Expose nur in der **lokalen BaseBox** geprüft, nicht auf echter Hardware. RAM-Backing nur falls der Vater auf Hardware Lücken hinter überlappenden Fenstern sieht.
Debug-Schalter: `SKIP=SU`, sonst `SAMPLE=1`, `SKIP=CHARSCAN,…`, `NOFUNC=1`, `TRACE=1`, `HWCOPY=1`.

---
## Vorherige Runde (abcf310e)

Stand: 2026-11-15 09:36 (Europe/Berlin)

**Datei:** `build/SVGA16.GEO` (Checkpoint `build/SVGA16_abcf310e_rowtop.GEO`)
**SHA-256:** `abcf310e00cf62bc9654db569a1f8209fb99db8a9838589e370f010e5cd4be56`
**Vorher:** 8e0d9053 → Backup `build/bak_8e0d9053_pre_rowtop.GEO`, Quellen `*.bak_8e0d9053`

Lokale BaseBox: Pixelfehler nach Schließen der Voreinstellungen reproduziert (1024: Schmierspur y=469–496). RowTopBX-X-Offset + IncDi 38E6/3926. **Schmierspur blieb in jener Runde offen.**

---
## Vorherige Runde (8e0d9053)

Stand: 2026-10-30 08:12 (Europe/Berlin)

## Aktuelles Ergebnis

**Datei:** `build/SVGA16.GEO` (Checkpoint `build/SVGA16_8e0d9053_charsmc.GEO`)
**SHA-256:** `8e0d9053ff88423c2c4c0b3b0e50c0fc2317e489f5743e0e7ecca88be31e163e`
**Vorher:** f5613a75 → Backup `build/bak_f5613a75_pre_bbfix.GEO`, Quellen `*.bak_f5613a75`

Testumgebung neu: echtes pcgeos-basebox (Linux, `/workspace/basebox/…/binl64/basebox`), `testenv/bbctl.sh` / `testenv/run_bb.sh`. Vaters Fehler dort reproduziert (DOSBox-X zeigte sie nicht).

Fixes (Details CHANGELOG 2026-10-30):
1. CharScan-SMC-Kollision (wilder Call bei geclipptem Text) → `charDelta`-Variablen + `CharAdd0..4`.
2. Clipmasken-Puffer 0x44D8 (100 B) → `maskBuf` 192 B (Überlauf bei 1024/1280).
3. S2S-Kopie Standard per Software-Pfad (`HWCOPY=1` für alten HW-Pfad).

| Mode | Boot | Prefs | Fenster-Drag |
|------|------|-------|--------------|
| 800×600 | OK | OK | OK |
| 1024×768 | OK (auch Absturz-Dialog lesbar) | OK inkl. Video/Ändern | OK über y=512 |
| 1280×1024 | OK | OK | OK, Rest-Punktlinie Zeile 409 |

Offen: 1280 Zeile 409 (Mid-Line-Bank im XOR-Musterpfad); Mode-Test nach Grafikwechsel nicht geprüft.
Debug-Schalter: `SAMPLE=1` (INT08-Sampler+Strategy-Log → COM1/Nullmodem 127.0.0.1:5555), `SKIP=CHARSCAN,…`, `NOFUNC=1`, `TRACE=1`.

---
## Vorherige Runde (f5613a75)

Stand: 2026-10-29 22:18 (Europe/Berlin)

## Aktuelles Ergebnis

**Datei:** `build/SVGA16.GEO` (Checkpoint `build/SVGA16_f5613a75_negbank.GEO`)
**SHA-256:** `f5613a7571425ae2e7b228c8410a2a854eba8dd742df68c3fc2f02fbb532ac70`
**Vorher:** 6a93a51e (PtrVis, nie an Vater geliefert) → Backup `build/bak_6a93a51e_pre_imul.GEO`

Fix dieser Runde: y·pitch signed (`imul`), negative Bank nicht an VBE ⇒ behebt Bank-0-Vollbildkorruption (Streifen/Weiß/Grau oben 512 Zeilen), im Emulator reproduziert und behoben. Details CHANGELOG 2026-10-29 22:18.

| Mode | Boot | Maus | Fenster-Drag |
|------|------|------|--------------|
| 800×600 | OK | OK | – |
| 1024×768 | OK | OK | OK (inkl. über oberen Rand) |
| 1280×1024 | OK | OK | OK, kein Absturz |

Offen: Prefs „Grafik-Typ ändern → OK“ bei 1024 hängt im Emulator (kein Treiberaufruf sichtbar); Mode-Test-Bild (Eck-Pfeile) nicht verifiziert.

---
## Vorherige Runde (6a93a51e)

Stand: 2026-10-28 12:51 (Europe/Berlin)

## Aktuelles Ergebnis

**Datei:** `build/SVGA16.GEO` (Checkpoint `build/SVGA16_6a93a51e_ptrvis.GEO`)
**SHA-256:** `6a93a51e561cc830807f9ed9793e8ac266c53746ea1bd2f8ff11767f1f0efa00`
**Backup vorher:** `build/SVGA16_25f37c34_pre_ptrvis.GEO` (= 25f37c34 CharScan-Stand)

| Mode | Statisch (DOSBox-X svga_s3) | Maus/Drag |
|------|-----------------------------|-----------|
| 640×480 | nicht neu regressiert | – |
| 800×600 | OK (`shot_n800_boot/after`, `build/shot_SVGA16_800_6a93a51e.png`) | Maus OK, keine Regression |
| 1024×768 | boot OK | Maus-Move + Drag ohne Vollbild-Streifen (`shot_n1024_*`); BaseBox-Retest kritisch |
| 1280×1024 | nicht neu getestet diese Runde | Absturz bei Fensterbewegung (User) — offen |

## Diese Runde (Feedback 2026-10-28)

Nur **16-Farben**; VESA64K pausiert. Symptome: 1024 startet, Maus→Streifen/Weiß; Prefs Crash/Hänger + eingebrannter Cursor; Mode-Test hängt; 800 stabil.

### Code-Änderungen
1. **`InstallPtr`:** PtrCalc-Hook @3662 entfernt → **CalcOffsetBP** (Bank+lastDI) bleibt.
2. **Visibility:** MultiSet schreibt `height−16` nach `0x368B`, `pitch−3` nach `0x3695`.
3. **PtrSave/Restore/Mask:** cli während Bank-I/O; PtrMask restored Bitmaske `FF08`.
4. Cave ~3224→3232 (16-pad); res1 weiter 16-fach.

### Erwartung vs. Emulator
DOSBox-X zeigte die BaseBox-Korruption oft nicht; Fixes zielen auf nachgewiesene Bank-/Visibility-Bugs. Bitte auf BaseBox: 1024 Maus bewegen, Prefs öffnen, Fenster draggen.

## Offene Risiken
- Prefs-Crash / Mode-Test-Hänger: Emulator-Prefs nicht sicher geöffnet — BaseBox prüfen.
- 1280 Fensterbewegung Absturz (User „1280×768“) — noch kein gezielter Fix.
- CharScan (25f37c34) unverändert aktiv; A/B gegen aa1e18d3 nur bei neuer Regression.
- FORCESW=1 bleibt Fallback bei S2S-Verdacht.
- FreeGEOS VESA64K: eigener Track, zurückgestellt.

## Build / Test

```bash
python3 tools/build_svga16.py
./testenv/run_drag.sh <tag> build/SVGA16.GEO "<Gerätename>" <bootsek> "<cmds>"
# FORCESW=1 python3 tools/build_svga16.py
```

Quellen: `src/svga16_multi.asm`, `src/svga16_bank.asm`, `src/gen_mul2.inc`, `tools/build_svga16.py`.
Basis: `drivers_video/SVGA8004_de.GEO` (unverändert).
INI: `driver = SVGA16.GEO`, `device = VESA … 16 Farben`, `info = 16384`.

Feedback: `feedback/vesa16_2026-10-28_*.png`.

---
## Historie – Stand aa1e18d3 (2026-10-19)

## Historie (vorheriger Stand, SHA 6b45fc1e… / 84ce7768…)

Stand: 2026-10-19 18:09 (Europe/Zagreb)

## Ziel

Super-VGA 16 Farben: 640×480, 800×600, 1024×768, 1280×1024.

## Ergebnis dieser Runde

**Datei:** `build/SVGA16.GEO` 
**SHA-256:** `6b45fc1ec5c94addeb7a2c6848c833e5f62c86d40be7a23a2d03cee2d7add627`

| Mode | Set | Ergebnis | Screenshot |
|------|-----|----------|------------|
| **800×600×16** | BIOS 6Ah | **OK** (Regression) | `build/shot_SVGA16_800x600.png` |
| **640×480×16** | BIOS 12h | Lesbar; **vertikale Bänder** bleiben | `build/shot_SVGA16_640x480.png` |
| **1024×768×16** | VESA 104h | UI oben **lesbar** (GeoManager-Titel/Icons); **Bankgrenze ~Zeile 512** bleibt | `build/shot_SVGA16_1024x768.png` |
| 1280×1024×16 | VESA 106h | DOSBox-X S3: oft 1280×960, korrupt — nicht priorisiert | — |

## Technik dieser Runde

### Was funktioniert
- Cave `InstallAddPitch` / `NextScanDI|SI`: Imm8-`add di/si,pitch` → `call NextScan*` bei pitch≥128 (Carry→Bank++).
- **Blit-Pfad 1 (302F):** statt Call an die Imm16-`add`-Stelle (zerstört SMC / Schwarzbild) → **LoopEnd1-Trampoline** an `3048` (`dec bp/jnz` → `call LoopEnd1`): liest SMC-Delta `[cs:3031]`, `add di`, Carry→Bank++, Continue bei `3033`.
- Call an `302F`/`3091` oder SMC-Redirect + Call → **Schwarzbild** (verifiziert). Frühe Imm16-Pitch-Liste in der Cave ebenfalls toxisch bei 1024.
- `SetVESABank`: Window A+B (4F05). CalcOffset setzt Bank aus MUL-Highwort (64K-Granularität).

### Hartes Limit: Full-Width `rep stosb` über 64K
Bei voller Zeilenbreite ist SMC-`lineDelta` ≈ 0. DI läuft während `rep stosb` über die Bankgrenze **ohne Carry auf dem späteren `add di,delta`**. LoopEnd sieht keinen Carry → kein Bank++. 
Deshalb bleibt die **Bankgrenze bei Y≈512** (65536/128) für große Rechteck-Fills (GeoManager-Fensterfläche).

Mögliche Next Steps (nicht in diesem Stand): `rep stosb` splitten wenn `DI+CX` wrappt; oder 32-bit `scanLinear` mit sicherem Zeilenanfang-Hook (Call an `3033` war ebenfalls schwarz).

### 640 Bänder
Weiterhin offen vs. VGA.GEO (Pitch−N / Planar-Shifts). Keine Änderung in dieser Runde.

### 1280
DOSBox-X `svga_s3` liefert keinen zuverlässigen 1280×1024×4-Bit-Mode.

## Build / Test

```bash
python3 tools/build_svga16.py
./testenv/run_video2.sh <tag> SVGA16.GEO "<Gerätename>" <Sek>
```

Quellen: `src/svga16_multi.asm`, `src/svga16_bank.asm`, `tools/build_svga16.py` 
Basis: `drivers_video/SVGA8004_de.GEO`

## Laufendes Log 2026-10-19 abends (Europe/Zagreb)
- 19:55 Fund: Original nutzt CS-Variablen 0x4460..0x45BB HINTER den Dateidaten (Laufzeit-RAM). Cave lag bei 0x4460 → überlappte Variablen. Cave jetzt bei **0x4600** (Padding). 800×600 unverändert OK.
- 19:59 LoopEnd2 für Blit-Pfad 2 (Muster, 30C3/[3093]/3095) + Bank-Test „neue DI < pitch“ statt Carry.
- 20:01 Fund: 5 weitere ungepatchte y*100-Stellen (0x050D, 0x1750, 0x1766, 0x18B6, 0x2061). pitch 80 → Shift-Template, pitch≥128 → Mul-Stubs mit Bank. **640×480 jetzt sauber (keine Bänder)**. Checkpoint `build/SVGA16_mul2_163b2634.GEO`.
- 20:03 **1024×768 über volle Höhe lesbar** (GeoManager, Taskleiste unten). Reststörung: gepunktete Linie bei y≈468, Cursor-Rest. Gleicher Build 163b2634.
- 20:09 Imm8-Stellen (pitch-N, cmp/sub bx/cx,pitch, add dx Blit-Delta) bei pitch≥128 → Call-Stubs; NextScan mit Test 'DI<pitch'. INSTALL_ADD_PITCH jetzt NACH den Byte-Patches. 1024 unverändert gut, **1280 (S3) erstmals lesbar** (sichtbarer Ausschnitt). Checkpoint build/SVGA16_imm8_e58f1aff.GEO
- 21:20 Zeiger neu (RAM-Save-Under, bankfest) → build/SVGA16_ptr_9ac41ba1.GEO. Mauszeiger-Test mit autolock=true + Klick + xdotool mousemove_relative funktioniert (testenv/run_video6.sh/run_video7.sh). Alt-Build: Geisterzeiger reproduziert; neu: kein Geist.
- 21:35 Mid-Line-Bank-Split (StosSplit 303D, IncDiMovCx 30A3, IncDiLoop 30B1, advd-Flag in LoopEnd/2) → 1280 Strich Zeile 819 weg. Checkpoint build/SVGA16_split_72ca884f.GEO
- 21:50 RowCopy (S2S-Kopie bankfest, SW-Pfad bei Bankkonflikt) → build/SVGA16_rowcopy_815dbccb.GEO. Automatischer Fenster-Drag-Test testenv/run_drag.sh: 1024 Fenster 240px runter verschoben → Inhalt korrekt, kein Einfrieren.
- 22:05 VBE (Granularität, WinFuncPtr, WinB nur wenn vorhanden) → SVGA16_vbe_bbff77e8.GEO; RowTop-Hooks (Bitmap 1AF7, Muster 1592, GetBits 18D2) → SVGA16_rowtop.GEO (aa1e18d3). Drag-Tests 1024: runter OK, hoch OK, hoch+rechts: Iconzeilen 3+ bleiben weiß (Alt-Build schlimmer: Icons oben Zeile 0-15). 800 gleicher Test OK.
- 22:20 Regression aa1e18d3: 640 + 800 pixelgleich, 1024/1280 statisch OK (Shots *_aa1e.png). Docs aktualisiert.
