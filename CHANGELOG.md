## 2026-11-16 11:36 CET — Export für Cursor / Notion aktualisiert

Kein Treiber- oder Spiel-Code geändert. Alter Export bleibt als Backup: `/workspace/geos-export/GEOS_Projekt_2026-11-15.zip` (SHA-256 `84b96696092b296a184222f59b90490194d539872022a7c7fb02e1aa903ffc98`).

Neuer Export `/workspace/geos-export/GEOS_Projekt_2026-11-16.zip` mit aktuellem Stand inkl. SVGA16 **ffb97152**, Mode-Test-Shots (lokale BaseBox) und unverändertem PIXJAGD **d7f6c6cd**. Übergabetext: `CURSOR_UEBERGABE.md`. Notion-Übergabeseite auf denselben Stand gezogen. SHA-256 und Größe des neuen ZIP stehen in `/workspace/geos-export/EXPORT_LOG.md`.

Offen bleibt der Test von ffb97152 und PIXJAGD in der echten BaseBox des Vaters. VESA64K weiter zurückgestellt.

## 2026-11-15 13:20 CET — SVGA16 Mode-Test + SaveUnder-Regression (ffb97152, nur Test)

Nur 16 Farben (VESA64K unberührt). Basis ffb97152 (bereits an Valentin geliefert). Backup `build/bak_ffb97152_pre_modetest.GEO`, Quellen `src/svga16_{bank,multi}.asm.bak_ffb97152`, `tools/build_svga16.py.bak_ffb97152`. **Kein Code-Change, kein neues GEO.** `/workspace/geos-game/` nicht angefasst. Nichts an Valentin geschickt. Ergebnisse: **lokale BaseBox**, nicht echte Hardware.

Ablauf Mode-Test (Prefs → Video → Ändern → VESA-Modus wählen → Listen-OK → äußeres Video-OK → **Ja** → Hinweis-OK): Nach dem Neustart erscheint das SETUP-Testbild („In jeder Bildschirmecke sollten Sie einen kleinen Pfeil sehen…“), dann ENTER → 16-Farben-Palette, ENTER → Bestätigung, ENTER → Desktop. Nicht F10 (das würde zurückschalten); Bestätigung nur per ENTER bzw. Maus, nicht die Liste mit Return abschließen.

### 1. Mode-Test 640/800/1024/1280 (lokale BaseBox)
Vater-Hang (`feedback/vesa16_2026-10-28_06/07_mode_test.png`: schwarz, Text abgeschnitten, blaue Quadrate statt Pfeile) in dieser Umgebung **nicht** reproduziert.

| Mode | Eckpfeile (alle 4) | Text scharf | Bestätigung (ENTER, Farben, zurück zum Desktop) | Hänger |
|------|--------------------|-------------|--------------------------------------------------|--------|
| 640×480 | ja | ja | ja, 16 Farben vollständig | nein (stabil) |
| 800×600 | ja | ja | ja, 16 Farben vollständig | nein (stabil) |
| 1024×768 | ja (auch unterhalb Bank y=512) | ja | ja, 16 Farben vollständig | nein (stabil) |
| 1280×1024 | ja (Bankgrenzen y=409/819 sauber) | ja | ja, 16 Farben vollständig | nein (stabil) |

Shots: `build/shot_SVGA16_{640,800,1024,1280}_bb_ffb97152_modetest.png` plus `_colors` / `_confirm`.

### 2. SaveUnder-Ablehnen, Regression 1024 und 1280
Kein RAM-Backing nötig: nach Schließen von Menüs/Dialogen zeichnet der Kernel den Hintergrund neu, ohne Lücken oder Müll.

- 1280: Dialog (Oberfläche) über Icons → nach Abbruch 0 Graureste, nur Mauszeiger-Diff; Express-Menü über erster Icon-Reihe → 0 Pixel-Diff zur vorherigen sauberen Fläche; Prefs über Icons ziehen (Expose der alten Lage sauber), Maus darüber ohne Müll. Shots `build/shot_SVGA16_1280_bb_ffb97152_su_{dialog_over_icons,after_dialog,express_menu,express_menu_closed,drag,drag_mouse}.png`.
- 1024: Prefs über Icons sauber (kein Band y=469); nach Wegnehmen der Prefs Icon-Fläche vollständig; Dialog „läuft bereits“ über Icons → nach OK identisch zur sauberen Fläche (nur Maus-Diff). Shots `build/shot_SVGA16_1024_bb_ffb97152_su_{overlap,prefs_over_icons,prefs_closed,dialog_over_icons,after_dialog}.png`.

### 3. Gesamt-Smoke (finaler Build = ffb97152)
Start (bzw. Ankunft nach Mode-Wechsel), Maus, Prefs auf/zu, bei 1280 zusätzlich Fenster ziehen: in allen vier Modi in der lokalen BaseBox unauffällig. 640-Desktop: `build/shot_SVGA16_640_bb_ffb97152_smoke_{desktop,mouse}.png`.

**SHA-256 unverändert:** `ffb971527acce57f4e685777ee22ad4977a2f6e0a4933d0bcb988df5af45af85`. Checkpoint bleibt `build/SVGA16_ffb97152_su.GEO`. **Nicht ersetzen.**


## 2026-11-15 12:43 CET — SVGA16 Menü-Schmierspur / Save-Under 0xAEAA (ffb97152)

Nur 16 Farben (VESA64K unberührt). Basis abcf310e, Backup `build/bak_abcf310e_pre_menusmear.GEO`, Quellen `src/svga16_bank.asm.bak_abcf310e` (multi/py unverändert). `/workspace/geos-game/` nicht angefasst. Ergebnisse: **lokale BaseBox**, nicht echte Hardware.

### Reproduktion und Eingrenzung
- Die Spur liegt **fest** bei y=469–496 (1024) bzw. y=785–792 (1280 nach Drag in Bank 1) — unabhängig von der Menüposition. Datei-Menü oben ohne Spur; Prefs-Systemmenü auch ohne Fenster-Drag erzeugt die Spur bei y=469.
- `SKIP=PTR,SPLIT,ROWCOPY,VBE,ROWTOP,CHARSCAN` (alle optionalen Hooks aus): Spur **unverändert** (28 Zeilen, gleiches Muster). Täter ist also keiner dieser Patches.
- Die beiden EA70-Immediates im Zeiger-Pfad nach 0x2000 zu legen verschiebt die Spur nicht. Ursache ist ein anderer Puffer.

### Ursache
Das Original legt den Save-Under-Puffer (Menü/Fenster-Hintergrund) auf Segment **0xAEAA**, das ist physikalisch **A000:EAA0**. Bei 800×600 liegt das hinter y=600 (unsichtbar, nach dem 16×16-Zeiger bei EA70). Bei 1024 ist A000:EAA0 die sichtbare Zeile y=469, x=256; bei 1280 in Bank 0 y≈375, in Bank 1 y≈785. Der Treiber kopiert den Menühintergrund linear dorthin (`rep movsb`, Größe typisch ≈28×Pitch) — das erscheint als Schmierspur über die volle Breite. Nach dem Schließen der Voreinstellungen bleibt der rechte Rest stehen.

### Fix (Zyklus 2; ein Patch)
`InstallSU` (pitch≥128, `SKIP=SU` zum Abschalten): Allokation am Einstieg 0x1EE6 liefert Carry (kein Platz); Hide/Show dieser Tabelle (0x1F9D/0x1FA7) sind No-Ops. Der Kernel zeichnet den Hintergrund beim Schließen selbst neu (GetBits/Expose). Der Mauszeiger bleibt auf `InstallPtr`/CS-RAM, nicht auf diesem Puffer. Bei 800×600 bleibt der originale Offscreen-Puffer unverändert.

### Test lokale BaseBox (nicht echte Hardware)
- 1024: Systemmenü ohne und mit Drag über y=512 **ohne** Schmierspur; nach Schließen der Voreinstellungen **keine** Reste. Shots `build/shot_SVGA16_1024_bb_ffb97152_{menu_clean,prefs_closed,nodrag_menu}.png`.
- 1280: Systemmenü ohne Spur bei y=375/469/785. Shot `build/shot_SVGA16_1280_bb_ffb97152_menu_clean.png`.
- 800: Boot + Prefs + Systemmenü unverändert sauber (rechter Bildschirm ohne Spur). Shot `build/shot_SVGA16_800_bb_ffb97152_menu.png`.

### Offen
Kein RAM-Backing für Save-Under (nur Ablehnung). In der lokalen BaseBox hat das Expose-Redraw beim Schließen gereicht; falls auf echter Hardware hinter überlappenden Fenstern Lücken bleiben, wäre ein CS/DOS-Puffer mit 4-Plane-Kopie der nächste Schritt. Mode-Test mit Eckpfeilen weiter ungeprüft. 1280-Drag über y=409 in dieser Runde nicht extra wiederholt (die Spur kam vom gleichen AEAA-Schreiber).

**SHA-256:** `ffb971527acce57f4e685777ee22ad4977a2f6e0a4933d0bcb988df5af45af85`, Checkpoint `build/SVGA16_ffb97152_su.GEO`.


## 2026-11-15 09:36 CET — SVGA16 RowTopBX-X-Offset + IncDi 38E6/3926 (abcf310e)

Nur 16 Farben (VESA64K unberührt). Basis 8e0d9053, Backup `build/bak_8e0d9053_pre_rowtop.GEO`, Quellen `src/*.asm.bak_8e0d9053`, `tools/build_svga16.py.bak_8e0d9053`.

### Reproduktion (lokale BaseBox, nicht echte Hardware)
- 09:19 Mit 8e0d9053 @1024: Voreinstellungen nach unten über y=512 ziehen, Systemmenü (Schließen-Kasten) öffnen ⇒ **horizontale Schmierspur y=469–496, x≈393–989** (bunt/grau, volle Breite rechts vom Prefs-Fenster). Nach Schließen bleibt genau dieser rechte Rest stehen — entspricht den Linienresten des Vaters (`feedback/8e0d9053_2026-10-30_pixelfehler.png`). Shots: `build/shot_SVGA16_1024_bb_8e0d9053_{menu_smear,prefs_leftover}.png`.
- Die Spur liegt *oberhalb* der Bankgrenze y=512 (nicht auf der Grenze selbst). Entsteht beim Öffnen des Systemmenüs, nicht schon beim Fensterziehen.

### Änderungen (Zyklus 1; die 1024-Schmierspur bleibt)
1. **RowTopBX** (Muster/Bitmap-Zeilenstart @1592/@1AF7): hat DI auf `y*pitch` gesetzt und den **X-Offset verworfen** (Zeile startete bei x=0). Neu: DI bleibt erhalten, Bank aus 32-Bit-Adresse `y*pitch+x_off` inklusive Carry bei 64K-Wrap (wichtig für 1280 Mid-Line).
2. **IncDiLoop38/39**: `inc di / loop` in den Bitmap-AND-Schleifen 38E6 und 3926 schaltet bei Wrap die Bank weiter (1280 Mid-Line).

Build zwischendurch de8e594c (ohne Carry-Korrektur); final **abcf310e**.

### Test lokale BaseBox (nicht echte Hardware)
- 1024: Schmierspur nach Systemmenü **unverändert** (auch nach RowTopBX-Fix). Shot `build/shot_SVGA16_1024_bb_de8e594c_menu_smear.png`.
- 1280: Boot + Fenster-Drag über y=409 in der weißen Fläche **ohne** gepunktete Restlinie bei x≈994–1219 (`shot_SVGA16_1280_bb_abcf310e_drag.png`). Nach Menü-Klick dünne Schmierspur y=785–792 über die Breite (`..._menu_smear.png`).
- 800: diese Hooks nur bei pitch≥128, nicht extra getestet.

### Offen
Die zu breite Schreiboperation beim Systemmenü/Dateimenü (rechte Kante des Clip/Fill offenbar Fenster- oder Bildschirmbreite statt Menübreite) ist **nicht behoben**. Das ist vermutlich die Ursache der Pixelfehler des Vaters nach dem Schließen der Voreinstellungen. Nächster Ansatz: welcher Fill/Blit-Pfad beim Menü CX/rechte Kante setzt (nicht RowTopBX). Mode-Test mit Eckpfeilen weiter ungeprüft.

**SHA-256:** `abcf310e00cf62bc9654db569a1f8209fb99db8a9838589e370f010e5cd4be56`, Checkpoint `build/SVGA16_abcf310e_rowtop.GEO`.



## 2026-10-30 08:12 CET — SVGA16 Fix-Runde BaseBox (8e0d9053)

- 07:27 Testumgebung: echtes **pcgeos-basebox** (CI-latest, BLD285, dosbox-staging 0.83, Linux-Binary) unter `/workspace/basebox/`; Skripte `testenv/run_bb.sh`, `testenv/bbctl.sh` (Session-Steuerung, Maus relativ mit Home, Raw-Capture Ctrl+F5). memsize=6 wie basebox.conf.
- 07:35 **Reproduziert** in BaseBox mit f5613a75 @1024: Voreinstellungen öffnen ⇒ Hänger (Zeiger weg, Statuszeile GeoManager rechts vom Prefs-Fenster nicht mehr gezeichnet). In DOSBox-X gleicher Ablauf OK. Nicht abhängig von WinFuncPtr (NOFUNC-Build), memsize, core.
- 07:40 Backup `build/bak_f5613a75_pre_bbfix.GEO`, `src/*.asm.bak_f5613a75`, `tools/build_svga16.py.bak_f5613a75`. Build-Schalter `NOFUNC=1` (nur INT10 4F05) und `SAMPLE=1` (INT-08-Sampler CS:IP → COM1/Nullmodem, nur Debug).
- 07:47 Sampler: CPU läuft im Treiber-CS (2F0F) bei Offset 0x8FC7–0x8FE5 = **außerhalb des Treibers** (wilder Sprung) bzw. alternativ Deadlock.
- 07:52 **Ursache gefunden:** Zeilen-Clipmaske des Originals bei CS:0x44D8 ist 100 Byte groß (800/8). Kernel-Aufruf 0x1C4 schreibt width/8 Byte ⇒ bei 1024 128 Byte, bei 1280 160 Byte ⇒ überschreibt Treiber-Variablen 0x453C…0x4578 (u. a. Zeigerposition/-zustand). Tritt nur bei teilweise verdeckten Fenstern auf (komplexes Clipping) ⇒ Prefs über GeoManager, Fenster ziehen.
- 07:54 Fix: neuer Puffer `maskBuf` (192 Byte) in der Cave; Build biegt 4 Referenzen (0B99, 0C56, 22A9, 2493) um. Build 6260de04 (Test folgt).
- 07:56 Test 6260de04 (nur Maskenfix) in BaseBox: weiterhin Hänger, jetzt mit **Grau-Fläche oben 512 Zeilen** = exakt Vaters Bild „Voreinstellungen“.
- 07:59 Bisect per Build-Schalter `SKIP=PTR,SPLIT,ROWCOPY,VBE,ROWTOP,CHARSCAN` (überspringt Install-Routinen, nur Debug): `SKIP=CHARSCAN` ⇒ kein Hänger, Statuszeile korrekt.
- 08:02 **Hauptursache gefunden (CharScan, seit 25f37c34):** Die Glyph-Zeilenschleifen enden mit `add di,imm16`, dessen Imm16 das Original pro Zeichen per SMC neu schreibt (0B53→0BAF, 0C06→0C72, 0C8A→0CC5, 0CF4→0D23, 229A→232E). CharScan hatte dort `call NextScanDI` eingesetzt ⇒ der SMC-Schreiber überschrieb das High-Byte des Call-Ziels ⇒ **wilder Call** (Zeichensalat, Speicherkorruption, Hänger, Grau). Außerdem addierte NextScanDI die volle Pitch statt pitch−Glyphbreite. Nur bei geclipptem/teilverdecktem Text aktiv ⇒ in DOSBox-X selten sichtbar.
- 08:04 Fix: SMC-Schreiber-Operanden (0B56, 0C09, 0C8D, 0CF6, 229B) auf eigene Variablen `charDelta[0..4]` umgebogen; Sites rufen `CharAdd0..4` (DI += Delta signed, Bank ±1 bei Über-/Unterlauf). S2S-Kopie per Standard über Software-Pfad (FORCESW; `HWCOPY=1` reaktiviert HW-Pfad 36DA/37C7, der bei Fehlausrichtung einen Zeilenpuffer von width/8+2 Byte auf den Thread-Stack legt). Build 8e0d9053: 1024 Prefs öffnen in BaseBox OK, Statuszeile korrekt, Maus lebt.
- 08:10 Ergebnis BaseBox (8e0d9053): 1024 Prefs öffnen/Video/„Ändern…“-Liste (alle 4 Modi gelistet)/Abbruch OK, Prefs-Fenster über Bankgrenze y=512 runter und wieder hoch gezogen OK; Dialog „letzte Arbeitssitzung…“ sauberer Text; 1280 Prefs + Drag ohne Einfrieren; 800 Prefs + Drag OK.
- Offen: 1280 nach Fenster-Drag gepunkteter Rest in Zeile 409 (Bankgrenze mitten in der Zeile, XOR-Zieh-Rahmen, x≈994–1219) = Vaters „verirrte Linie“. Nicht mehr bearbeitet (Zyklus-Limit).
- **SHA-256:** `8e0d9053ff88423c2c4c0b3b0e50c0fc2317e489f5743e0e7ecca88be31e163e`, Checkpoint `build/SVGA16_8e0d9053_charsmc.GEO`. Shots `build/shot_SVGA16_{1024_bb_8e0d9053_prefs,1024_bb_8e0d9053_drag,1024_bb_8e0d9053_dialog,1280_bb_8e0d9053_drag,800_bb_8e0d9053_drag}.png`.

## 2026-10-29 22:18 CET — SVGA16 negative Bank / imul (f5613a75)

Nur 16 Farben (VESA64K unberührt). Basis 6a93a51e (PtrVis), Backup `build/bak_6a93a51e_pre_imul.GEO`, Quellen `src/*.asm.bak_6a93a51e_pre_imul`.

### Reproduktion (DOSBox-X svga_s3, cycles=fixed 50000, `testenv/run_drag2.sh`)
- 1024: Prefs → Video → „Ändern…“ → OK ⇒ **komplette obere 512 Zeilen (= Bank 0) einfarbig grau**, Rest unverändert — exakt das Bild vom Vater (Streifen/Weiß nur in Bank 0). Shot: `build/shot_SVGA16_1024_6a93a51e_prefs_bank0gray.png`.
- Port-E9-Trace (`TRACE=1 OUTNAME=SVGA16_trace.GEO`): kurz davor `SETVESABANK(0x7F)`.

### Ursache
y·pitch wurde **unsigned** (`mul`) gerechnet. Für Zeilen y<0 (GEOS zeichnet/clippt Bereiche oberhalb des Bildschirms) ⇒ DX=0x7F ⇒ Bank 127. VBE lehnt ungültige Bank ab ⇒ Hardware bleibt in Bank 0, `curBank`/NextScan zählen weiter (0x80, 0x81…) ⇒ ganze Fläche landet wiederholt in Bank 0 ⇒ Vollbild-Streifen/Weiß/Grau oben, Bank 1 unberührt. Bei 800 (kein Banking) unsichtbar.

### Fix
- Alle y·pitch-Stellen `mul` → **`imul`** (CalcOffsetBP/CalcOffset0, Mul2-Stubs, RowTopBX, GetRow, RowCopy, PtrAddr) ⇒ y<0 ergibt Bank −1, nach der ersten Zeile korrekt 0.
- `NewSetBank`: negative Bank nur merken, keine VBE-Umschaltung.
- Build-Script: `TRACE=1` / `OUTNAME=` für Debug-Builds (Port E9: T/S Test/Set, p/r/m Zeiger, R/G/C/W Hooks, Bankziffern). Normal-Build ohne TRACE byte-identisch zu 6a93a51e reproduziert vor dem Fix.

### Build / Test
- **SHA-256:** `f5613a7571425ae2e7b228c8410a2a854eba8dd742df68c3fc2f02fbb532ac70`, Checkpoint `build/SVGA16_f5613a75_negbank.GEO`
- 800: Boot + Maus OK (`build/shot_SVGA16_800_f5613a75_mouse.png`)
- 1024: Boot + Maus OK, Fenster-Drag runter/hoch über Rand/rechts OK (`..._1024_f5613a75_{mouse,drag}.png`), Prefs-Ablauf: **kein Bank-0-Grau mehr** (`..._1024_f5613a75_prefs.png`)
- 1280: Boot + Maus OK, Fenster-Drag OK, kein Absturz (`..._1280_f5613a75_{mouse,drag}.png`)
- Offen: Im Emulator nach „Grafik-Typ ändern → OK“ bei 1024 bleibt Prefs mit Sperr-Zeiger stehen (Dialog halb neu gezeichnet); Trace zeigt **keinen** Test/Set-Aufruf in den Treiber. Unklar ob Treiber- oder Prefs/Emulator-Effekt.

## 2026-10-28 12:51 CET — SVGA16 PtrVis / CalcOffsetBP (6a93a51e)

Priorität: **nur 16-Farben**. Feedback t13u: 1024 Maus→Streifen/Weiß, Prefs Crash/Hänger, eingebrannter Cursor; 800 stabil; 64K zurückgestellt.

### Ursache (Analyse)
1. **PtrCalc-Override @3662** ersetzte `CalcOffsetBP` (mul+adc+**SetBank**+15 NOPs) durch Offset-only ohne Bank/`lastDI` → Bank-Desync bei Mausbewegungen (Streifen/Weiß), SaveUnder-Restore unzuverlässig (eingebrannter Cursor).
2. **Visibility-Hardcodes** in 362f: `cmp bp,0x248` (600−16) und `cmp cl,0x61` (100−3) nicht für 1024/1280 gepatcht → Zeiger unterhalb y≈584 bzw. rechts von Spalte 97 als „unsichtbar“.

### Fix
- `InstallPtr`: kein PtrCalc mehr; 3662 bleibt CalcOffsetBP aus multi.
- `MultiSet`: patcht Imm16@368B = height−16, Imm8@3695 = pitch−3.
- PtrSave/Restore/Mask: `cli`/`sti` (pushf/popf) um Bank-Schleifen; PtrMask setzt Bitmaske FF08 zurück.
- Backup: `build/SVGA16_25f37c34_pre_ptrvis.GEO` + Source-`.bak_25f37c34_pre_ptrvis`.

### Build / Test (DOSBox-X svga_s3)
- **SHA-256:** `6a93a51e561cc830807f9ed9793e8ac266c53746ea1bd2f8ff11767f1f0efa00`
- Checkpoint: `build/SVGA16_6a93a51e_ptrvis.GEO`
- 800×600: boot+Maus OK (`build/shot_SVGA16_800_6a93a51e.png`, `testenv/shot_n800_*`)
- 1024×768: boot+aggressive Maus+Drag OK, keine Vollbild-Streifen (`build/shot_SVGA16_1024_6a93a51e_{boot,mouse}.png`)
- Prefs-Doppelklick im Emulator nicht zuverlässig getroffen — BaseBox-Retest nötig.
- 1280 / Mode-Test-Hänger: noch offen.

### INI (unverändert)
`driver = SVGA16.GEO`, `device = VESA Kompatible Super VGA: … 16 Farben`, `info = 16384`.


## 2026-10-28 12:40 CET — Valentin Feedback SVGA16 / VESA16 (DOSBox)

Quelle: t12u/t13u Screenshots + Text. Priorität: **nur 16-Farben**, VESA64K zurückgestellt.

### Symptome (User)
- **1024×768×16**: startet; **Mausbewegung** → Korruption (Streifen / weiße Fläche)
- **Voreinstellungen**: GeoWorks + DOSBox **Absturz** oder Hänger
- **1280×768×16** (User-Wortlaut): Absturz bei **Fensterbewegung**
- **800×600×16**: relativ stabil
- **64K**: jede Auflösung sofort ab — **erstmal egal**

### Shots
- `feedback/vesa16_2026-10-28_01.png` (früher)
- `02_stripes` Express + vertikale Streifen
- `03_white` weiße Fläche + Express unten
- `04_video_dialog` Video-Dialog bestätigt `VESA … 1024x768 16 Farben`; Schmier/Ghost
- `05_prefs_cursor` Voreinstellungen offen, **Mauszeiger „eingebrannt“** auf Titelleiste
- `06/07_mode_test` Mode-Test-Text („In jeder Bildschirmecke…“), schwarzer BG, Eck-Quadrate statt Pfeile → Hänger beim Karten-/Mode-Wechsel-Test

### Einordnung
Maus/SaveUnder/Pointer bei 1024 (pitch 128) und Mode-Switch-Test kaputt; 800 ok → bank/pitch/PtrCalc-Pfad. Weiter: CharScan-Retest + Pointer/SaveUnder + Prefs-Crash.

## 2026-10-30 13:07 CET – BaseBox-Feedback 8e0d9053
- Vater: alle Auflösungen sehr stabil, kein Absturz.
- Offen: 1024 und 1280 Pixelfehler nach Schließen der Voreinstellungen (feedback/8e0d9053_2026-10-30_pixelfehler.png). Testen pausiert.
