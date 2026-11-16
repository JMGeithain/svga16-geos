; svga16_multi.asm — Multi-Mode Pitch + VESA-Banking (GeoWorks 1.x)
; DS-sicheres InstallMulTemplate + Pitch−N
bits 16
org 0x2C40

; von build_svga16.py per -D gesetzt (Cave-Start)
%ifndef INSTALL_ADD_PITCH
 %define INSTALL_ADD_PITCH 0x4460
%endif

VDI_pageH  equ 0x0E
VDI_pageW  equ 0x10
VDI_vRes   equ 0x12
VDI_hRes   equ 0x14
VDI_bpScan equ 0x16
NUM_MODES  equ 4

MultiTest:
        push    bp
        mov     bp, sp
        sub     sp, 0x102
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    es
        mov     bx, di
        mov     ax, [cs:modeTable+bx]
        test    ah, ah
        jz      .bios_ok
        mov     di, ss
        mov     es, di
        lea     di, [bp-0x102]
        push    ax
        mov     ax, 0x4F00
        int     0x10
        cmp     ax, 0x004F
        pop     ax
        jne     .no
        cmp     byte [bp-0x102], 'V'
        jne     .no
        cmp     byte [bp-0x101], 'E'
        jne     .no
        cmp     byte [bp-0x100], 'S'
        jne     .no
        cmp     byte [bp-0x0FF], 'A'
        jne     .no
        les     di, [bp-0xF4]
.loop:  cmp     word [es:di], 0xFFFF
        je      .no
        scasw
        jne     .loop
.bios_ok:
        mov     ax, 1
        jmp     .done
.no:    xor     ax, ax
.done:  pop     es
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        mov     sp, bp
        pop     bp
        ret

SetVESABank:
        push    ax
        push    bx
        mov     [cs:curBank], dx
        cmp     byte [cs:useBanking], 0
        je      .skip
        mov     ax, 0x4F05
        xor     bx, bx                  ; Window A (write)
        int     0x10
        mov     ax, 0x4F05
        mov     bx, 1                   ; Window B (read), gleicher Bank
        int     0x10
.skip:  pop     bx
        pop     ax
        ret

CalcOffsetBP:
        push    ax
        push    dx
        mov     ax, di
        imul    word [cs:pitch]
        add     ax, bp
        adc     dx, 0
        mov     di, ax
        mov     [cs:lastDI], di
        call    SetVESABank
        pop     dx
        pop     ax
        ret

CalcOffset0:
        push    ax
        push    dx
        mov     ax, di
        imul    word [cs:pitch]
        mov     di, ax
        mov     [cs:lastDI], di
        call    SetVESABank
        pop     dx
        pop     ax
        ret

InstallMulTemplate:
        push    ax
        push    cx
        push    si
        push    di
        cld
        mov     di, 0x0978
        call    .copy18
        mov     di, 0x0E31
        call    .copy18
        mov     di, 0x3662
        call    .copy18
        add     si, 18
        mov     di, 0x1439
        call    .copy18
        mov     di, 0x156F
        call    .copy18
        add     si, 18
        mov     di, 0x1AD3
        call    .copy18
        pop     di
        pop     si
        pop     cx
        pop     ax
        ret
.copy18:
        push    si
        push    di
        mov     cx, 18
.c:     mov     al, [cs:si]
        mov     [cs:di], al
        inc     si
        inc     di
        loop    .c
        pop     di
        pop     si
        ret

InstallMulCalls:
        push    ax
        push    bx
        push    cx
        push    si
        push    di
        mov     bx, mulSitesBP
        mov     ax, CalcOffsetBP
.b:     mov     di, [cs:bx]
        or      di, di
        jz      .z
        mov     byte [cs:di], 0xE8
        mov     cx, ax
        sub     cx, di
        sub     cx, 3
        mov     [cs:di+1], cx
        mov     cx, 15
        lea     si, [di+3]
.n1:    mov     byte [cs:si], 0x90
        inc     si
        loop    .n1
        add     bx, 2
        jmp     .b
.z:     mov     bx, mulSites0
        mov     ax, CalcOffset0
.z1:    mov     di, [cs:bx]
        or      di, di
        jz      .o
        mov     byte [cs:di], 0xE8
        mov     cx, ax
        sub     cx, di
        sub     cx, 3
        mov     [cs:di+1], cx
        mov     cx, 15
        lea     si, [di+3]
.n2:    mov     byte [cs:si], 0x90
        inc     si
        loop    .n2
        add     bx, 2
        jmp     .z1
.o:     pop     di
        pop     si
        pop     cx
        pop     bx
        pop     ax
        ret

mulSitesBP: dw 0x0978, 0x0E31, 0x3662, 0
mulSites0:  dw 0x1439, 0x156F, 0x1AD3, 0

MultiSet:
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        mov     bx, di
        shr     bx, 1
        cmp     bx, NUM_MODES
        jb      .okidx
        xor     bx, bx
.okidx: mov     ax, bx
        shl     ax, 1
        shl     ax, 1
        add     ax, bx
        shl     ax, 1
        mov     si, ax

        mov     ax, [cs:geoTable+si]
        mov     [cs:VDI_pageH], ax
        mov     cx, ax
        mov     ax, [cs:geoTable+si+2]
        mov     [cs:VDI_pageW], ax
        mov     dx, ax
        mov     ax, [cs:geoTable+si+4]
        mov     [cs:VDI_vRes], ax
        mov     ax, [cs:geoTable+si+6]
        mov     [cs:VDI_hRes], ax
        mov     ax, [cs:geoTable+si+8]
        mov     [cs:VDI_bpScan], ax

        mov     ax, dx
        shr     ax, 3
        mov     [cs:pitch], ax

        cmp     ax, 80
        je      .do80
        cmp     ax, 100
        je      .muldone
        call    InstallMulCalls
        jmp     .muldone
.do80:  mov     si, tmpl80
        call    InstallMulTemplate
.muldone:
        mov     si, pitchWordPatch
.pw:    mov     bx, [cs:si]
        or      bx, bx
        jz      .pwd
        mov     [cs:bx], ax
        add     si, 2
        jmp     .pw
.pwd:   mov     si, pitchByteAll
.pb:    mov     bx, [cs:si]
        or      bx, bx
        jz      .pbd
        mov     [cs:bx], al
        add     si, 2
        jmp     .pb
.pbd:
        mov     ah, al
        dec     al
        mov     si, pitchByte1
.p1:    mov     bx, [cs:si]
        or      bx, bx
        jz      .p1d
        mov     [cs:bx], al
        add     si, 2
        jmp     .p1
.p1d:   mov     al, ah
        sub     al, 2
        mov     si, pitchByte2
.p2:    mov     bx, [cs:si]
        or      bx, bx
        jz      .p2d
        mov     [cs:bx], al
        add     si, 2
        jmp     .p2
.p2d:   mov     al, ah
        sub     al, 3
        mov     si, pitchByte3
.p3:    mov     bx, [cs:si]
        or      bx, bx
        jz      .p3d
        mov     [cs:bx], al
        add     si, 2
        jmp     .p3
.p3d:   mov     ax, [cs:pitch]
        call    INSTALL_ADD_PITCH       ; nach den Byte-Patches (Calls ueberschreiben sie)

        push    cx
        mov     si, widthPatch
.wl:    mov     bx, [cs:si]
        or      bx, bx
        jz      .wd
        mov     [cs:bx], dx
        add     si, 2
        jmp     .wl
.wd:    mov     ax, dx
        dec     ax
        mov     si, widthM1Patch
.w1:    mov     bx, [cs:si]
        or      bx, bx
        jz      .w1d
        mov     [cs:bx], ax
        add     si, 2
        jmp     .w1
.w1d:   pop     cx
        mov     si, heightPatch
.hl:    mov     bx, [cs:si]
        or      bx, bx
        jz      .hd
        mov     [cs:bx], cx
        add     si, 2
        jmp     .hl
.hd:    mov     ax, cx
        dec     ax
        mov     si, heightM1Patch
.h1:    mov     bx, [cs:si]
        or      bx, bx
        jz      .h1d
        mov     [cs:bx], ax
        add     si, 2
        jmp     .h1
.h1d:
        ; Maus-Visibility @362f: cmp bp,height-16 (war 0x248) / cmp cl,pitch-3 (war 0x61)
        mov     ax, cx                  ; CX = pageH
        sub     ax, 16
        mov     [cs:0x368B], ax         ; Imm16 von cmp bp,imm
        mov     ax, [cs:pitch]
        sub     ax, 3
        mov     [cs:0x3695], al         ; Imm8 von cmp cl,imm
        mov     bx, di
        mov     bx, [cs:modeTable+bx]
        mov     byte [cs:useBanking], 0
        test    bh, bh
        jnz     .vesa
        mov     ax, bx
        int     0x10
        jmp     .b0
.vesa:  mov     byte [cs:useBanking], 1
        mov     ax, 0x4F02
        int     0x10
.b0:    xor     dx, dx
        call    SetVESABank
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

pitch:
        dw 100
curBank:
        dw 0
lastDI:
        dw 0
useBanking:
        db 0
        db 0

tmpl80:
        db 0xD1,0xE7,0xD1,0xE7,0xD1,0xE7,0xD1,0xE7,0x03,0xEF,0xD1,0xE7,0xD1,0xE7,0x03,0xFD,0x90,0x90
        db 0xD1,0xE7,0xD1,0xE7,0xD1,0xE7,0xD1,0xE7,0x03,0xCF,0xD1,0xE7,0xD1,0xE7,0x03,0xF9,0x90,0x90
        db 0xD1,0xE7,0xD1,0xE7,0xD1,0xE7,0xD1,0xE7,0x03,0xC7,0xD1,0xE7,0xD1,0xE7,0x03,0xF8,0x90,0x90

widthPatch:
        dw 0x101F, 0x2496, 0x29E1, 0x2A91, 0x2AAB, 0x2AC5, 0
widthM1Patch:
        dw 0x1F04, 0x1F09, 0x2ACA, 0
heightPatch:
        dw 0x1022, 0x29EB, 0x2A8C, 0x2AB5, 0x2AD4
        dw 0x342B, 0x34CE, 0x3593, 0x35D2, 0
heightM1Patch:
        dw 0x1F12, 0x1F17, 0x2AD9, 0

pitchWordPatch:
        ; mov-imm Pitch + add dx / sub (nicht add di/si — die macht InstallAddPitch)
        dw 0x1535, 0x172E, 0x18A3, 0x1A92, 0x1B55, 0x2077
        dw 0x08EC, 0x0CF0, 0x11F5, 0x121D, 0x12B5, 0x12E1, 0

pitchByteAll:
        dw 0x0B94, 0x0C49, 0x0E50, 0

pitchByte1:
        dw 0x3022, 0x3103, 0x3120, 0x3141, 0x315C, 0
pitchByte2:
        dw 0x307D, 0x317B, 0x31AE, 0
pitchByte3:
        dw 0x31EA, 0x322F, 0x341D, 0x34C2, 0

modeTable:
        dw 0x0012, 0x006A, 0x0104, 0x0106
geoTable:
        dw 480, 640, 64, 64, 320
        dw 600, 800, 80, 80, 400
        dw 768,1024, 80, 80, 512
        dw 1024,1280, 80, 80, 640
