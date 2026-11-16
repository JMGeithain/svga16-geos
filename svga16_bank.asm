; LoopEnd @3048 (bewährt 6b45fc1e): SMC-Delta, Carry→Bank++. Imm8→NextScan.
; StosbSplit/Exact-Fill/Dual-Patch: toxisch oder Dual→Schwarz. Hartes Limit bleibt.
bits 16
org CAVE
%macro TR 1
%ifdef TRACE
        push    ax
        mov     al, %1
        out     0xE9, al
        mov     al, 10
        out     0xE9, al
        pop     ax
%endif
%endmacro

InstallAddPitch:
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        call    InstallMul2
        call    InstallImm8
%ifndef NOPTR
        call    InstallPtr
%endif
%ifndef NOSPLIT
        call    InstallSplit
%endif
%ifndef NOROWCOPY
        call    InstallRowCopy
%endif
%ifndef NOVBE
        call    InstallVbe
%endif
%ifndef NOROWTOP
        call    InstallRowTop
%endif
%ifndef NOCHARSCAN
        call    InstallCharScan
%endif
%ifndef NOSU
        call    InstallSU
%endif

        mov     si, addPitch8
.lp8:   mov     di, [cs:si]
        or      di, di
        jz      .blit
        mov     dl, [cs:si+2]
        cmp     ax, 128
        jae     .c8
        mov     byte [cs:di], 0x83
        mov     bl, 0xC7
        test    dl, dl
        jz      .m8
        mov     bl, 0xC6
.m8:    mov     [cs:di+1], bl
        mov     [cs:di+2], al
        jmp     .n8
.c8:    mov     bx, NextScanDI
        test    dl, dl
        jz      .t8
        mov     bx, NextScanSI
.t8:    call    WriteCall3
.n8:    add     si, 3
        jmp     .lp8

.blit:  cmp     ax, 128
        jb      .lo
        mov     di, 0x3048
        mov     bx, LoopEnd
        call    WriteCall3
        mov     di, 0x30C3
        mov     bx, LoopEnd2
        call    WriteCall3
        jmp     .done
.lo:    mov     byte [cs:0x3048], 0x4D
        mov     byte [cs:0x3049], 0x75
        mov     byte [cs:0x304A], 0xE4
        mov     byte [cs:0x30C3], 0x4D
        mov     byte [cs:0x30C4], 0x75
        mov     byte [cs:0x30C5], 0xC6
.done:  pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        ret

WriteCall3:
        mov     byte [cs:di], 0xE8
        mov     cx, bx
        sub     cx, di
        sub     cx, 3
        mov     [cs:di+1], cx
        ret

addPitch8:
        dw 0x3009
        db 0
        dw 0x305E
        db 0
        dw 0x30C7
        db 0
        dw 0x30D9
        db 0
        dw 0x30EB
        db 0
        dw 0x345A
        db 0
        dw 0x34FA
        db 1
        dw 0x3544
        db 0
        dw 0x357C
        db 0
        dw 0x35BF
        db 0
        dw 0x3623
        db 0
        dw 0

; Bankwechsel-Test: neue Zeilenposition < pitch  <=> 64K-Grenze ueberschritten
; (erkennt auch Wrap innerhalb rep stosb / inc di, wo kein Carry entsteht)
LoopEnd:
        dec     bp
        jz      .done
        push    ax
        push    dx
        mov     ax, [cs:0x3031]
        add     di, ax
        cmp     di, [cs:PITCH]
        jae     .go
        cmp     byte [cs:advd], 0
        jne     .go
        mov     dx, [cs:CURBANK]
        inc     dx
        call    SETVESABANK
.go:    mov     byte [cs:advd], 0
        pop     dx
        pop     ax
        add     sp, 2
        jmp     0x3033
.done:  mov     byte [cs:advd], 0
        ret

NextScanDI:
        push    ax
        mov     ax, [cs:PITCH]
        add     di, ax
        cmp     di, ax
        jae     .ok
        push    dx
        mov     dx, [cs:CURBANK]
        inc     dx
        call    SETVESABANK
        pop     dx
.ok:    pop     ax
        ret

NextScanSI:
        push    ax
        mov     ax, [cs:PITCH]
        add     si, ax
        cmp     si, ax
        jae     .ok
        push    dx
        mov     dx, [cs:CURBANK]
        inc     dx
        call    SETVESABANK
        pop     dx
.ok:    pop     ax
        ret

; Blit-Pfad 2 (Muster): Loop 308C..30C4, Delta SMC [cs:3093], weiter bei 3095
LoopEnd2:
        dec     bp
        jz      .done
        inc     bl
        and     bl, 7
        push    ax
        push    dx
        mov     ax, [cs:0x3093]
        add     di, ax
        cmp     di, [cs:PITCH]
        jae     .go
        cmp     byte [cs:advd], 0
        jne     .go
        mov     dx, [cs:CURBANK]
        inc     dx
        call    SETVESABANK
.go:    mov     byte [cs:advd], 0
        pop     dx
        pop     ax
        add     sp, 2
        jmp     0x3095
.done:  mov     byte [cs:advd], 0
        ret

; ---- Weitere y*100-Stellen (im Original, bisher ungepatcht) ----
; pitch 80: Shift-Template; pitch>=128: Call auf Mul-Stub mit Bank.
InstallMul2:
        cmp     ax, 100
        je      .ret
        push    ax
        push    bx
        push    cx
        push    si
        push    di
        mov     si, mul2Tab
.lp:    mov     di, [cs:si]
        or      di, di
        jz      .out
        cmp     ax, 80
        jne     .call
        push    si
        add     si, 4
        mov     cx, 18
.c:     mov     bl, [cs:si]
        mov     [cs:di], bl
        inc     si
        inc     di
        loop    .c
        pop     si
        jmp     .nx
.call:  mov     bx, [cs:si+2]
        call    WriteCall3
        add     di, 3
        mov     cx, 15
.n:     mov     byte [cs:di], 0x90
        inc     di
        loop    .n
.nx:    add     si, 22
        jmp     .lp
.out:   pop     di
        pop     si
        pop     cx
        pop     bx
        pop     ax
.ret:   ret

%include "gen_mul2.inc"

MulBXAX:
        push    ax
        push    dx
        push    ax
        mov     ax, bx
        imul    word [cs:PITCH]
        pop     bx
        add     ax, bx
        adc     dx, 0
        mov     bx, ax
        call    SETVESABANK
        pop     dx
        pop     ax
        ret
MulBX0:
        push    ax
        push    dx
        mov     ax, bx
        imul    word [cs:PITCH]
        mov     bx, ax
        call    SETVESABANK
        pop     dx
        pop     ax
        ret
MulDX0:
        push    ax
        mov     ax, dx
        imul    word [cs:PITCH]
        push    ax
        call    SETVESABANK
        pop     dx
        pop     ax
        ret
MulSI0:
        push    ax
        push    dx
        mov     ax, si
        imul    word [cs:PITCH]
        mov     si, ax
        call    SETVESABANK
        pop     dx
        pop     ax
        ret
MulSIAX:
        push    ax
        push    dx
        push    ax
        mov     ax, si
        imul    word [cs:PITCH]
        pop     si
        add     ax, si
        adc     dx, 0
        mov     si, ax
        call    SETVESABANK
        pop     dx
        pop     ax
        ret

; ---- Imm8-Stellen pitch-N / cmp / sub: bei pitch>=128 passt imm8 nicht (sign-ext) ----
InstallImm8:
        cmp     ax, 128
        jb      .ret
        push    bx
        push    si
        push    di
        mov     si, imm8Tab
.lp:    mov     di, [cs:si]
        or      di, di
        jz      .out
        mov     bx, [cs:si+2]
        call    WriteCall3
        add     si, 4
        jmp     .lp
.out:   pop     di
        pop     si
        pop     bx
.ret:   ret

imm8Tab:
        dw 0x3101, AddDI1, 0x311E, AddDI1, 0x313F, AddDI1, 0x315A, AddDI1
        dw 0x3179, AddDI2, 0x31AC, AddDI2
        dw 0x31E8, AddDI3, 0x322D, AddDI3, 0x341B, AddDI3
        dw 0x34C0, AddSI3
        dw 0x3020, AddDX1, 0x307B, AddDX2
        dw 0x0B92, CmpBXP, 0x0C47, CmpBXP, 0x0E4E, SubCXP
        dw 0

AddDI1: push    ax
        mov     ax, 1
        jmp     AddDIn
AddDI2: push    ax
        mov     ax, 2
        jmp     AddDIn
AddDI3: push    ax
        mov     ax, 3
AddDIn: neg     ax
        add     ax, [cs:PITCH]
        add     di, ax
        cmp     di, [cs:PITCH]
        jae     .ok
        push    dx
        mov     dx, [cs:CURBANK]
        inc     dx
        call    SETVESABANK
        pop     dx
.ok:    pop     ax
        ret
AddSI3: push    ax
        mov     ax, [cs:PITCH]
        sub     ax, 3
        add     si, ax
        cmp     si, [cs:PITCH]
        jae     .ok
        push    dx
        mov     dx, [cs:CURBANK]
        inc     dx
        call    SETVESABANK
        pop     dx
.ok:    pop     ax
        ret
AddDX1: add     dx, [cs:PITCH]
        dec     dx
        ret
AddDX2: add     dx, [cs:PITCH]
        sub     dx, 2
        ret
CmpBXP: cmp     bx, [cs:PITCH]
        ret
SubCXP: sub     cx, [cs:PITCH]
        ret

; =====================================================================
; Save-Under-Puffer liegt im Original bei Segment 0xAEAA (= A000:EAA0).
; Bei 800x600 ist das Offscreen hinter y=600; bei 1024/1280 sichtbar
; (y=469 bzw. y=375 in Bank 0, y=785 in Bank 1). Menue-SaveUnder
; schreibt dort linear und erzeugt die Schmierspur.
; Pitch>=128: Allokation ablehnen, Hide/Show dieser Tabelle no-op.
; (Mauszeiger bleibt auf InstallPtr / CS-RAM, nicht auf diesem Puffer.)
; =====================================================================
InstallSU:
        cmp     ax, 128
        jb      .ret
        push    ax
        mov     byte [cs:0x1EE6], 0xF9   ; stc
        mov     byte [cs:0x1EE7], 0xC3   ; ret  (Save/Set: Carry=kein Platz)
        mov     byte [cs:0x1EE8], 0x90
        mov     byte [cs:0x1F9D], 0xF8   ; clc
        mov     byte [cs:0x1F9E], 0xC3   ; ret  (Hide)
        mov     byte [cs:0x1F9F], 0x90
        mov     byte [cs:0x1FA7], 0xF8   ; clc
        mov     byte [cs:0x1FA8], 0xC3   ; ret  (Show)
        mov     byte [cs:0x1FA9], 0x90
        pop     ax
.ret:   ret

; =====================================================================
; Mauszeiger (Save-Under / Restore / Maske) bankfest neu, pitch>=128.
; Original: Save-Under-Puffer im VRAM bei A000:EA70 (bei 800x600 offscreen).
; Bei 1024/1280 liegt EA70 IM SICHTBAREN Bild (Zeile ~468 bzw. ~375) und
; teilt sich das Fenster nicht mit der Zeigerbank -> Geisterzeiger + Striche.
; Neu: Puffer im CS-RAM (16 Zeilen x 3 Byte x 4 Planes), jedes Byte mit
; eigener Bankwahl, alte Bank wird danach wiederhergestellt.
; =====================================================================
PTR_X   equ 0x4575
PTR_Y   equ 0x4577
VDI_H   equ 0x0E

InstallPtr:
        cmp     ax, 128
        jb      .ret
        push    bx
        push    di
        mov     di, 0x33E4
        mov     bx, PtrRestore
        call    WriteJmp3
        mov     di, 0x3489
        mov     bx, PtrSave
        call    WriteJmp3
        mov     di, 0x3503
        mov     bx, PtrMask
        call    WriteJmp3
        ; 3662 bleibt CalcOffsetBP (multi) — kein PtrCalc-Override
        pop     di
        pop     bx
.ret:   ret

WriteJmp3:
        call    WriteCall3
        mov     byte [cs:di], 0xE9
        ret

; Offset y*pitch+BP: CalcOffsetBP @3662 in multi.asm (mul+adc+SetBank).
; BX=y, CX=Bytespalte (signed) -> CF=1 ausserhalb; sonst DI=Offset, Bank gesetzt (nur bei Wechsel)
PtrAddr:
        cmp     bx, 0
        jl      .bad
        cmp     bx, [cs:VDI_H]
        jge     .bad
        cmp     cx, 0
        jl      .bad
        cmp     cx, [cs:PITCH]
        jge     .bad
        mov     ax, bx
        imul    word [cs:PITCH]
        add     ax, cx
        adc     dx, 0
        mov     di, ax
        cmp     dx, [cs:CURBANK]
        je      .ok
        call    SETVESABANK
.ok:    clc
        ret
.bad:   stc
        ret

PtrRestoreBank:                         ; DX = alte Bank
        cmp     dx, [cs:CURBANK]
        je      .r
        call    SETVESABANK
.r:     ret

PtrCol:                                 ; CX = sar(PTR_X,3)
        mov     cx, [cs:PTR_X]
        sar     cx, 1
        sar     cx, 1
        sar     cx, 1
        ret

; ---- Save-Under: Bildschirm -> ptrBuf (ersetzt 3489) ----
PtrSave:
        TR 'p'
        mov     ax, 0xA000
        mov     es, ax
        pushf
        cli
        push    word [cs:CURBANK]
        mov     ax, [cs:PTR_Y]
        mov     [cs:savY], ax
        call    PtrCol
        mov     [cs:savCX], cx
        mov     byte [cs:savValid], 1
        mov     dx, 0x3CE
        mov     ax, 0x0005
        out     dx, ax
        mov     si, ptrBuf
        xor     bp, bp
.row:   mov     bx, [cs:savY]
        add     bx, bp
        mov     cx, [cs:savCX]
        mov     byte [cs:kcnt], 3
.col:   call    PtrAddr
        jc      .skip
        mov     dx, 0x3CE
        mov     ax, 0x0004
.pl:    out     dx, ax
        push    ax
        mov     al, [es:di]
        mov     [cs:si], al
        pop     ax
        inc     si
        inc     ah
        cmp     ah, 4
        jb      .pl
        jmp     .nk
.skip:  add     si, 4
.nk:    inc     cx
        dec     byte [cs:kcnt]
        jnz     .col
        inc     bp
        cmp     bp, 16
        jb      .row
        pop     dx
        call    PtrRestoreBank
        mov     dx, 0x3CE
        mov     ax, 0x0F01
        out     dx, ax
        mov     ax, 0x0008
        out     dx, ax
        mov     ax, 0x0003
        out     dx, ax
        popf
        ret

; ---- Restore: ptrBuf -> Bildschirm (ersetzt 33E4, Ende wie Original: jmp 32C7) ----
PtrRestore:
        TR 'r'
        cmp     byte [cs:savValid], 0
        je      .out
        mov     ax, 0xA000
        mov     es, ax
        pushf
        cli
        push    word [cs:CURBANK]
        mov     dx, 0x3CE
        mov     ax, 0x0001
        out     dx, ax
        mov     ax, 0x0003
        out     dx, ax
        mov     ax, 0xFF08
        out     dx, ax
        mov     ax, 0x0005
        out     dx, ax
        mov     si, ptrBuf
        xor     bp, bp
.row:   mov     bx, [cs:savY]
        add     bx, bp
        mov     cx, [cs:savCX]
        mov     byte [cs:kcnt], 3
.col:   call    PtrAddr
        jc      .skip
        mov     dx, 0x3C4
        mov     ax, 0x0102
.pl:    out     dx, ax
        push    ax
        mov     al, [cs:si]
        mov     [es:di], al
        pop     ax
        inc     si
        shl     ah, 1
        cmp     ah, 0x10
        jb      .pl
        jmp     .nk
.skip:  add     si, 4
.nk:    inc     cx
        dec     byte [cs:kcnt]
        jnz     .col
        inc     bp
        cmp     bp, 16
        jb      .row
        mov     dx, 0x3C4
        mov     ax, 0x0F02
        out     dx, ax
        pop     dx
        call    PtrRestoreBank
        mov     dx, 0x3CE
        mov     ax, 0x0F01
        out     dx, ax
        mov     ax, 0x0008
        out     dx, ax
        mov     ax, 0x0003
        out     dx, ax
        popf
.out:   jmp     0x32C7

; ---- Maske zeichnen (ersetzt 3503): SI = 16x2 Byte Maske, Set/Reset+Funktion vom Aufrufer ----
PtrMask:
        TR 'm'
        mov     ax, 0xA000
        mov     es, ax
        pushf
        cli
        push    word [cs:CURBANK]
        xor     bp, bp
.row:   mov     ah, [cs:si]
        mov     al, [cs:si+1]
        xor     dl, dl
        mov     cl, [cs:PTR_X]
        and     cl, 7
        jz      .ns
.sh:    shr     ah, 1
        rcr     al, 1
        rcr     dl, 1
        dec     cl
        jnz     .sh
.ns:    mov     [cs:msk], ah
        mov     [cs:msk+1], al
        mov     [cs:msk+2], dl
        add     si, 2
        push    si
        mov     si, msk
        mov     bx, [cs:PTR_Y]
        add     bx, bp
        call    PtrCol
        mov     byte [cs:kcnt], 3
.col:   cmp     byte [cs:si], 0
        je      .sk
        call    PtrAddr
        jc      .sk
        mov     dx, 0x3CE
        mov     al, 8
        mov     ah, [cs:si]
        out     dx, ax
        or      [es:di], al
.sk:    inc     si
        inc     cx
        dec     byte [cs:kcnt]
        jnz     .col
        pop     si
        inc     bp
        cmp     bp, 16
        jb      .row
        pop     dx
        call    PtrRestoreBank
        mov     dx, 0x3CE
        mov     ax, 0xFF08
        out     dx, ax
        popf
        ret

savY:     dw 0
savCX:    dw 0
savValid: db 0
kcnt:     db 0
msk:      db 0, 0, 0, 0
ptrBuf:   times 192 db 0

; =====================================================================
; Bankgrenze MITTEN in der Zeile (1280: 65536/160 nicht ganzzahlig).
; advd=1: in dieser Zeile wurde die Bank schon weitergeschaltet
; (LoopEnd/LoopEnd2 schalten dann nicht nochmal).
; =====================================================================
InstallSplit:
        cmp     ax, 128
        jb      .ret
        push    bx
        push    di
        mov     di, 0x303D              ; mov ah,0FFh / out / rep stosb
        mov     bx, StosSplit
        call    WriteCall3
        mov     word [cs:0x3040], 0x9090
        mov     di, 0x30A3              ; inc di / mov cx,si
        mov     bx, IncDiMovCx
        call    WriteCall3
        mov     di, 0x30B1              ; inc di / loop 30AE
        mov     bx, IncDiLoop
        call    WriteCall3
        ; Bitmap/AND-Schleifen: inc di / loop ohne Bank (1280 Mid-Line, 38E6/3926)
        mov     di, 0x38EA              ; inc di / loop 38E6
        mov     bx, IncDiLoop38
        call    WriteCall3
        mov     di, 0x3930              ; inc di / loop 3926
        mov     bx, IncDiLoop39
        call    WriteCall3
        pop     di
        pop     bx
.ret:   ret

BankUp:                                 ; Bank++ , advd=1
        push    dx
        mov     dx, [cs:CURBANK]
        inc     dx
        call    SETVESABANK
        pop     dx
        mov     byte [cs:advd], 1
        ret

StosSplit:
        mov     ah, 0xFF
        out     dx, ax
        or      di, di                  ; linker Rand lag bei FFFF -> inc di wrappte
        jnz     .nw
        call    BankUp
.nw:    jcxz    .done
        push    bx
        mov     bx, di
        add     bx, cx
        jnc     .one                    ; passt ins Fenster
        mov     bx, cx
        mov     cx, di
        neg     cx                      ; Bytes bis Fensterende
        sub     bx, cx
        rep     stosb
        call    BankUp
        mov     cx, bx
.one:   rep     stosb
        pop     bx
.done:  ret

IncDiMovCx:
        inc     di
        jnz     .ok
        call    BankUp
.ok:    mov     cx, si
        ret

IncDiLoop:
        inc     di
        jnz     .ok
        call    BankUp
.ok:    dec     cx
        jz      .end
        add     sp, 2
        jmp     0x30AE
.end:   ret

IncDiLoop38:
        inc     di
        jnz     .ok
        call    BankUp
.ok:    dec     cx
        jz      .end
        add     sp, 2
        jmp     0x38E6
.end:   ret

IncDiLoop39:
        inc     di
        jnz     .ok
        call    BankUp
.ok:    dec     cx
        jz      .end
        add     sp, 2
        jmp     0x3926
.end:   ret

advd:   db 0

; =====================================================================
; Screen-to-Screen-Kopie (Fenster verschieben / Scrollen), Zeilenschleife
; 1794..17E2, pro Zeile "call 36DA" (17D6, 1818, 185E). Original rechnet
; si/di nur 16-bit und ohne Bank -> Quelle/Ziel in verschiedenen Banks
; falsch. Neu: RowCopy berechnet Quell-/Zielzeile absolut aus BP
; (Zielzeile) und [4466]-[4468] (Quell-/Ziel-Top). Liegen beide Zeilen
; komplett in EINER Bank -> Original 36DA. Sonst Software-Kopie
; (planeweise ueber RAM-Puffer, bit-genau mit Masken, overlap-sicher).
; =====================================================================
InstallRowCopy:
        cmp     ax, 128
        jb      .ret
        push    bx
        push    di
        mov     di, 0x17D6
        mov     bx, RowCopy
        call    WriteCall3
        mov     di, 0x1818
        call    WriteCall3
        mov     di, 0x185E
        call    WriteCall3
        pop     di
        pop     bx
.ret:   ret

RowCopy:
        TR 'C'
        push    ax
        push    bx
        push    cx
        push    dx
        mov     ax, bp
        imul    word [cs:PITCH]
        mov     [cs:rcDLo], ax
        mov     [cs:rcDHi], dx
        mov     ax, bp
        add     ax, [cs:0x4466]
        sub     ax, [cs:0x4468]
        imul    word [cs:PITCH]
        mov     [cs:rcSLo], ax
        mov     [cs:rcSHi], dx
%ifdef FORCESW
        jmp     .sw
%endif
        cmp     dx, [cs:rcDHi]
        jne     .sw
        mov     cx, [cs:PITCH]
        dec     cx
        mov     ax, [cs:rcSLo]
        add     ax, cx
        jc      .sw
        mov     ax, [cs:rcDLo]
        add     ax, cx
        jc      .sw
        ; gleiche Bank, keine Zeile ueber Grenze -> Original
        cmp     dx, [cs:CURBANK]
        je      .b
        call    SETVESABANK
.b:     pop     dx
        pop     cx
        pop     bx
        pop     ax
        mov     si, [cs:rcSLo]
        mov     di, [cs:rcDLo]
        jmp     0x36DA
.sw:    pop     dx
        pop     cx
        pop     bx
        pop     ax
        push    es
        push    bp
        call    RowSW
        pop     bp
        pop     es
        ret

; DX:AX = Basis, BX = Bytespalte -> DI = Offset, Bank gesetzt (nur bei Wechsel)
AbsAddr:
        add     ax, bx
        adc     dx, 0
        mov     di, ax
        cmp     dx, [cs:CURBANK]
        je      .ok
        call    SETVESABANK
.ok:    ret

RowSW:
        TR 'W'
        mov     cx, [cs:0x4462]
        cmp     bx, cx
        jge     .c1
        mov     bx, cx
.c1:    mov     cx, [cs:0x4464]
        cmp     ax, cx
        jle     .c2
        mov     ax, cx
.c2:    cmp     bx, ax
        jle     .go
        ret
.go:    mov     [cs:rcX0], bx
        mov     [cs:rcX1], ax
        mov     cx, [cs:0x44AC]
        sub     cx, [cs:0x4462]
        mov     [cs:rcOff], cx
        mov     ax, bx
        add     ax, cx
        sar     ax, 1
        sar     ax, 1
        sar     ax, 1
        mov     [cs:rcSB0], ax          ; erste Quellbyte-Spalte
        mov     ax, [cs:rcX1]
        add     ax, cx
        sar     ax, 1
        sar     ax, 1
        sar     ax, 1
        sub     ax, [cs:rcSB0]
        inc     ax
        mov     [cs:rcN], ax            ; Anzahl Quellbytes
        mov     ax, 0xA000
        mov     es, ax
        mov     dx, 0x3CE
        mov     ax, 0x0005
        out     dx, ax
        mov     byte [cs:rcPl], 0
.plane:
        ; ---- Quelle lesen (Plane rcPl) ----
        mov     dx, 0x3CE
        mov     al, 4
        mov     ah, [cs:rcPl]
        out     dx, ax
        mov     byte [cs:rcBuf], 0
        xor     cx, cx
.rd:    cmp     cx, [cs:rcN]
        jae     .rdd
        mov     bx, [cs:rcSB0]
        add     bx, cx
        mov     ax, [cs:rcSLo]
        mov     dx, [cs:rcSHi]
        call    AbsAddr
        mov     al, [es:di]
        mov     bx, cx
        mov     [cs:rcBuf+1+bx], al
        inc     cx
        jmp     .rd
.rdd:   mov     bx, cx
        mov     byte [cs:rcBuf+1+bx], 0
        ; ---- Ziel schreiben ----
        mov     dx, 0x3CE
        mov     ax, 0x0001
        out     dx, ax
        mov     ax, 0x0003
        out     dx, ax
        mov     dx, 0x3C4
        mov     cl, [cs:rcPl]
        mov     ah, 1
        shl     ah, cl
        mov     al, 2
        out     dx, ax
        mov     ax, [cs:rcX0]
        sar     ax, 1
        sar     ax, 1
        sar     ax, 1
        mov     [cs:rcJ], ax
.wr:    mov     ax, [cs:rcX1]
        sar     ax, 1
        sar     ax, 1
        sar     ax, 1
        cmp     [cs:rcJ], ax
        jg      .wrd
        ; p0 = j*8
        mov     si, [cs:rcJ]
        shl     si, 1
        shl     si, 1
        shl     si, 1
        ; Maske
        mov     ax, [cs:rcX0]
        sub     ax, si                  ; lm
        jge     .l1
        xor     ax, ax
.l1:    mov     cl, al
        mov     bl, 0xFF
        shr     bl, cl
        mov     ax, [cs:rcX1]
        sub     ax, si                  ; rm
        cmp     ax, 7
        jle     .r1
        mov     ax, 7
.r1:    mov     cl, 7
        sub     cl, al
        mov     bh, 0xFF
        shl     bh, cl
        and     bl, bh
        mov     [cs:rcMask], bl
        ; Quellbits: r = p0 + off - sb0*8
        mov     ax, si
        add     ax, [cs:rcOff]
        mov     cx, [cs:rcSB0]
        shl     cx, 1
        shl     cx, 1
        shl     cx, 1
        sub     ax, cx
        mov     cl, al
        and     cl, 7
        sar     ax, 1
        sar     ax, 1
        sar     ax, 1
        inc     ax
        mov     bx, ax
        mov     ah, [cs:rcBuf+bx]
        mov     al, [cs:rcBuf+1+bx]
        shl     ax, cl
        mov     [cs:rcVal], ah
        ; GC8 = Maske, Latch laden, schreiben
        mov     dx, 0x3CE
        mov     al, 8
        mov     ah, [cs:rcMask]
        out     dx, ax
        mov     bx, [cs:rcJ]
        mov     ax, [cs:rcDLo]
        mov     dx, [cs:rcDHi]
        call    AbsAddr
        mov     al, [es:di]
        mov     al, [cs:rcVal]
        mov     [es:di], al
        inc     word [cs:rcJ]
        jmp     .wr
.wrd:   inc     byte [cs:rcPl]
        cmp     byte [cs:rcPl], 4
        jb      .plane
        ; Registerzustand wie am Ende von 36DA
        mov     dx, 0x3C4
        mov     ax, 0x0F02
        out     dx, ax
        mov     dx, 0x3CE
        mov     ax, 0x0004
        out     dx, ax
        mov     ax, 0x0005
        out     dx, ax
        mov     ax, 0x0F01
        out     dx, ax
        mov     ax, 0x1003
        out     dx, ax
        mov     ax, 0xFF08
        out     dx, ax
        cld
        ret

rcSLo:  dw 0
rcSHi:  dw 0
rcDLo:  dw 0
rcDHi:  dw 0
rcX0:   dw 0
rcX1:   dw 0
rcOff:  dw 0
rcSB0:  dw 0
rcN:    dw 0
rcJ:    dw 0
rcPl:   db 0
rcMask: db 0
rcVal:  db 0
        db 0
rcBuf:  times 200 db 0

; =====================================================================
; VBE-Fensterumschaltung robuster: Granularitaet beachten (nicht nur 64K),
; WinFuncPtr (far call) statt INT 10h (kein BIOS-Reentry aus dem
; Maus-Kontext), Window B nur wenn vorhanden, Umschalten nur bei Bedarf.
; Blob-SetVESABank bekommt einen jmp hierher.  DI = Modusindex*2.
; =====================================================================
InstallVbe:
        cmp     ax, 128
        jb      .ret
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    es
        mov     bx, di
        mov     cx, [cs:MODETABLE+bx]
        push    cs
        pop     es
        mov     di, vbeBuf
        mov     ax, 0x4F01
        int     0x10
        cmp     ax, 0x004F
        jne     .noinfo
        mov     ax, [cs:vbeBuf+4]       ; WinGranularity (KB)
        or      ax, ax
        jz      .noinfo
        cmp     ax, 64
        ja      .noinfo
        mov     cx, ax
        mov     ax, 64
        xor     dx, dx
        div     cx
        mov     [cs:vbeMul], ax
        mov     ax, [cs:vbeBuf+0x0C]
        mov     [cs:vbeFunc], ax
        mov     ax, [cs:vbeBuf+0x0E]
        mov     [cs:vbeFunc+2], ax
        mov     al, [cs:vbeBuf+3]       ; WinB-Attribute
        and     al, 1
        mov     [cs:vbeWinB], al
.noinfo:
        mov     di, SETVESABANK
        mov     bx, NewSetBank
        call    WriteJmp3
        pop     es
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
.ret:   ret

NewSetBank:
%ifdef TRACE
        pushf
        push    ax
        cmp     dx, [cs:CURBANK]
        je      .tq
        mov     al, dl
        add     al, '0'
        out     0xE9, al
        mov     al, 10
        out     0xE9, al
.tq:    pop     ax
        popf
%endif
        mov     [cs:CURBANK], dx
        cmp     byte [cs:USEBANKING], 0
        je      .r
        test    dh, 0x80                ; negative Bank (Zeile y<0): nur merken,
        jnz     .r                      ; HW nicht umschalten (VBE wuerde ablehnen)
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    bp
        mov     ax, dx
        mul     word [cs:vbeMul]
        mov     dx, ax
        xor     bx, bx
        call    VbeWin
        cmp     byte [cs:vbeWinB], 0
        je      .d
        mov     bx, 1
        call    VbeWin
.d:     pop     bp
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
.r:     ret

VbeWin:                                 ; BX=Fenster, DX=Position
        push    dx
%ifdef NOFUNC
        jmp     .int
%endif
        mov     ax, [cs:vbeFunc]
        or      ax, [cs:vbeFunc+2]
        jz      .int
        call    far [cs:vbeFunc]
        pop     dx
        ret
.int:   mov     ax, 0x4F05
        int     0x10
        pop     dx
        ret

vbeMul:  dw 1
vbeFunc: dd 0
vbeWinB: db 1
         db 0
vbeBuf:  times 256 db 0

; =====================================================================
; Zeilenschleifen ohne Banking (Bitmap/Icons 1AF7, Muster-Zeilen 1592,
; GetBits 18D2): am Zeilenanfang DI (bzw. SI) aus der Zeilennummer
; absolut neu berechnen und Bank setzen.
; 1AF7/1592: "cmp bx,[0BFh]" (4 Byte, nicht SMC) -> call + nop.
; 18D2: "call 3E99" -> call GetRow (Zeile = [4466]+[44A4]-DX).
; =====================================================================
InstallRowTop:
        cmp     ax, 128
        jb      .ret
        push    bx
        push    di
        mov     di, 0x1AF7
        mov     bx, RowTopBX
        call    WriteCall3
        mov     byte [cs:0x1AFA], 0x90
        mov     di, 0x1592
        call    WriteCall3
        mov     byte [cs:0x1595], 0x90
        mov     di, 0x18D2
        mov     bx, GetRow
        call    WriteCall3
        pop     di
        pop     bx
.ret:   ret

; DI hat bereits den richtigen 16-Bit-Offset (y*pitch+x_off, ggf. gewrappt
; nach add di,pitch). Frueher wurde DI = y*pitch gesetzt und der X-Offset
; verworfen: Muster-/Bitmap-Zeilen starteten bei x=0 mit zu grosser Breite
; -> horizontale Schmierspuren rechts von Menues/Fenstern (1024/1280).
; Bank aus 32-Bit-Adresse y*pitch + x_off (auch Mid-Line-Bank bei 1280).
RowTopBX:
        TR 'R'
        push    ax
        push    dx
        mov     ax, bx
        imul    word [cs:PITCH]         ; DX:AX = y * pitch
        push    si
        mov     si, di                  ; SI = bisheriger Offset (x_off enthalten)
        cmp     si, ax
        jae     .nob                    ; DI < y*pitch-lo => 64K-Wrap, Bank+1
        inc     dx
.nob:   mov     di, si                  ; X-Offset behalten
        pop     si
        cmp     dx, [cs:CURBANK]
        je      .s
        call    SETVESABANK
.s:     pop     dx
        pop     ax
        cmp     bx, [0xBF]
        ret

GetRow:
        TR 'G'
        push    ax
        push    dx
        mov     ax, [cs:0x4466]
        add     ax, [cs:0x44A4]
        sub     ax, dx
        imul    word [cs:PITCH]
        mov     si, ax
        cmp     dx, [cs:CURBANK]
        je      .s
        call    SETVESABANK
.s:     pop     dx
        pop     ax
        jmp     0x3E99

; =====================================================================
; Zeichen-/Glyph-Zeilen und restliche add-di,pitch-Stellen ohne Banking.
; 0BAD/0C70/0CC3/0D21: nach Glyph-Scan add di,pitch (4 Byte) -> call NextScanDI+nop.
; 232C: aehnlich in BitBlt-Schleife.
; Inneres inc di (Mid-Line-Bank bei 1280 Zeile 409/819):
;   0BA7/0C6A: inc di; inc bx; dec ch
;   0CBE:      inc di; dec ch
;   0D1C:      inc di; dec bl
;   2327:      inc si; inc di; inc bx  (vor loop)
; =====================================================================
InstallCharScan:
        cmp     ax, 128
        jb      .ret
        push    bx
        push    cx
        push    si
        push    di
        ; add di,imm16 (SMC-Delta = pitch - Glyphbreite) -> call CharAddN + nop.
        ; Die SMC-Schreiber (0B53/0C06/0C8A/0CF4/229A) schrieben das Delta in
        ; den Befehl und zerstoerten so den Call (wilder Sprung!) -> Schreiber
        ; auf eigene Variablen charDelta+2N umbiegen.
        mov     si, charPitchTab
.lp:    mov     di, [cs:si]
        or      di, di
        jz      .inner
        mov     bx, [cs:si+2]
        call    WriteCall3
        mov     byte [cs:di+3], 0x90    ; 4. Byte der add-imm16 -> nop
        mov     di, [cs:si+4]           ; Operand-Adresse des SMC-Schreibers
        mov     bx, [cs:si+6]           ; neue Zielvariable
        mov     [cs:di], bx
        add     si, 8
        jmp     .lp
.inner: mov     di, 0x0BA7
        mov     bx, IncDiIncBXDecCH
        call    WriteCall3
        mov     byte [cs:0x0BAA], 0x90
        mov     di, 0x0C6A
        call    WriteCall3
        mov     byte [cs:0x0C6D], 0x90
        mov     di, 0x0CBE
        mov     bx, IncDiDecCH
        call    WriteCall3
        mov     di, 0x0D1C
        mov     bx, IncDiDecBL
        call    WriteCall3
        mov     di, 0x2327
        mov     bx, IncSiDiBX
        call    WriteCall3
        pop     di
        pop     si
        pop     cx
        pop     bx
.ret:   ret

charPitchTab:   ; Site, Stub, SMC-Schreiber-Operand, Variable
        dw 0x0BAD, CharAdd0, 0x0B56, charDelta+0
        dw 0x0C70, CharAdd1, 0x0C09, charDelta+2
        dw 0x0CC3, CharAdd2, 0x0C8D, charDelta+4
        dw 0x0D21, CharAdd3, 0x0CF6, charDelta+6
        dw 0x232C, CharAdd4, 0x229B, charDelta+8
        dw 0
charDelta:
        dw 0, 0, 0, 0, 0
CharAdd0: push  ax
        mov     ax, [cs:charDelta+0]
        jmp     CharAddC
CharAdd1: push  ax
        mov     ax, [cs:charDelta+2]
        jmp     CharAddC
CharAdd2: push  ax
        mov     ax, [cs:charDelta+4]
        jmp     CharAddC
CharAdd3: push  ax
        mov     ax, [cs:charDelta+6]
        jmp     CharAddC
CharAdd4: push  ax
        mov     ax, [cs:charDelta+8]
CharAddC:                               ; DI += AX (signed), Bank bei Ueberlauf +/-1
        add     di, ax
        jc      .cy
        test    ax, ax
        jns     .ok                     ; positiv, kein Ueberlauf
        push    dx                      ; negativ ohne Carry -> unter 0 -> Bank-1
        mov     dx, [cs:CURBANK]
        dec     dx
        jmp     .set
.cy:    test    ax, ax
        js      .ok                     ; negativ mit Carry = normal
        push    dx                      ; positiv mit Carry -> Bank+1
        mov     dx, [cs:CURBANK]
        inc     dx
.set:   call    SETVESABANK
        pop     dx
.ok:    pop     ax
        ret

IncDiIncBXDecCH:
        inc     di
        jnz     .ok
        call    BankUp
.ok:    inc     bx
        dec     ch
        ret

IncDiDecCH:
        inc     di
        jnz     .ok
        call    BankUp
.ok:    dec     ch
        ret

IncDiDecBL:
        inc     di
        jnz     .ok
        call    BankUp
.ok:    dec     bl
        ret

IncSiDiBX:
        inc     si
        inc     di
        jnz     .ok
        call    BankUp
.ok:    inc     bx
        ret

; ---- Zeilen-Clipmaske (Kernel 0x1C4 schreibt width/8 Bytes): Original-Puffer
; 0x44D8 hat nur 100 Byte (800 px); bei 1024/1280 (128/160 Byte) wurden die
; Treiber-Variablen ab 0x453C (Zeiger-Position etc.) ueberschrieben.
; build_svga16.py biegt alle 4 Referenzen (0B99, 0C56, 22A9, 2493) hierher.
maskBuf:
        times 192 db 0

%ifdef TRACE
; ---- Debug: Port-E9-Trace der Test/Set-Einspruenge (nur TRACE-Build) ----
TraceTest:
        push    ax
        mov     al, 'T'
        out     0xE9, al
        mov     ax, di
        add     al, '0'
        out     0xE9, al
        pop     ax
        call    MULTITEST
        push    ax
        mov     al, 't'
        out     0xE9, al
        pop     ax
        ret
TraceSet:
        push    ax
        mov     al, 'S'
        out     0xE9, al
        mov     ax, di
        add     al, '0'
        out     0xE9, al
        pop     ax
        call    MULTISET
        push    ax
        mov     al, 's'
        out     0xE9, al
        mov     al, 10
        out     0xE9, al
        pop     ax
        ret
%endif

%ifdef SAMPLE
; ---- Debug: INT-08-Sampler -> COM1 (nur SAMPLE-Build): "CCCC:IIII B\n" ca. 2x/s ----
SampleSet:
        call    MULTISET
        cmp     byte [cs:smpOn], 0
        jne     .r
        mov     byte [cs:smpOn], 1
        push    ax
        push    dx
        push    es
        mov     dx, 0x3FB
        mov     al, 0x80
        out     dx, al
        mov     dx, 0x3F8
        mov     al, 1
        out     dx, al
        inc     dx
        xor     al, al
        out     dx, al
        mov     dx, 0x3FB
        mov     al, 3
        out     dx, al
        mov     al, '#'
        call    SmpCh
        mov     ax, cs
        call    SmpHex
        mov     al, 10
        call    SmpCh
        xor     ax, ax
        mov     es, ax
        pushf
        cli
        mov     ax, [es:0x20]
        mov     [cs:smpOld], ax
        mov     ax, [es:0x22]
        mov     [cs:smpOld+2], ax
        mov     word [es:0x20], SampleInt
        mov     [es:0x22], cs
        popf
        mov     byte [cs:0x1BF], 0xE8           ; call [cs:di+27] -> call StratLog
        mov     word [cs:0x1C0], StratLog - 0x1C2
        mov     word [cs:0x1C2], 0x9090
        pop     es
        pop     dx
        pop     ax
.r:     ret
SampleInt:
        push    bp
        mov     bp, sp
        push    ax
        push    dx
        inc     byte [cs:smpCnt]
        cmp     byte [cs:smpCnt], 1
        jb      .out
        mov     byte [cs:smpCnt], 0
        mov     ax, [bp+4]
        call    SmpHex
        mov     al, ':'
        call    SmpCh
        mov     ax, [bp+2]
        call    SmpHex
        mov     al, ' '
        call    SmpCh
        mov     al, [cs:CURBANK]
        add     al, '0'
        call    SmpCh
        mov     al, 10
        call    SmpCh
.out:   pop     dx
        pop     ax
        pop     bp
        jmp     far [cs:smpOld]
SmpHex: push    cx
        mov     cx, 4
.l:     rol     ax, 4
        push    ax
        and     al, 15
        add     al, '0'
        cmp     al, '9'
        jbe     .d
        add     al, 7
.d:     call    SmpCh
        pop     ax
        loop    .l
        pop     cx
        ret
SmpCh:  push    cx
        push    ax
        mov     dx, 0x3FD
        mov     cx, 2000
.w:     in      al, dx
        test    al, 0x20
        jnz     .s
        loop    .w
.s:     pop     ax
        mov     dx, 0x3F8
        out     dx, al
        pop     cx
        ret
StratLog:
        push    ax
        push    dx
        mov     al, 'F'
        call    SmpCh
        mov     ax, di
        call    SmpHex
        mov     al, 10
        call    SmpCh
        pop     dx
        pop     ax
        jmp     [cs:di+0x27]
smpOld: dd 0
smpOn:  db 0
smpCnt: db 0
%endif
