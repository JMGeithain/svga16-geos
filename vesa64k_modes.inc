; vesa64k_modes.inc
; GeoWorks 1.x – VBE mode discovery contract for the separate VESA64K driver.
; This file deliberately does not patch SVGA16.GEO.
;
; 16 bpp uses packed RGB pixels (normally 5:6:5), not VGA planar memory.
; Runtime must enumerate VBE mode list and inspect each mode with 4F01h.
;
; Requested geometry targets:
V64K_MODE_COUNT equ 2

V64K_800_WIDTH   equ 800
V64K_800_HEIGHT  equ 480
V64K_800_BPP     equ 16
V64K_800_BYTES   equ 768000

V64K_1024_WIDTH  equ 1024
V64K_1024_HEIGHT equ 600
V64K_1024_BPP    equ 16
V64K_1024_BYTES  equ 1228800

; VBE calls / flags
VBE_AX_INFO      equ 0x4F00
VBE_AX_MODE_INFO equ 0x4F01
VBE_AX_SET_MODE  equ 0x4F02
VBE_AX_SET_BANK  equ 0x4F05
VBE_MODE_LFB     equ 0x4000

; VBE ModeInfoBlock offsets
VBE_MODE_ATTR       equ 0x00
VBE_WIN_A_ATTR      equ 0x02
VBE_WIN_B_ATTR      equ 0x03
VBE_WIN_GRANULARITY equ 0x04
VBE_WIN_SIZE        equ 0x06
VBE_WIN_A_SEG       equ 0x08
VBE_WIN_B_SEG       equ 0x0A
VBE_BYTES_PER_LINE  equ 0x10
VBE_X_RES           equ 0x12
VBE_Y_RES           equ 0x14
VBE_BPP             equ 0x19
VBE_MEMORY_MODEL    equ 0x1B
VBE_RED_MASK_SIZE   equ 0x1F
VBE_RED_FIELD_POS   equ 0x20
VBE_GREEN_MASK_SIZE equ 0x21
VBE_GREEN_FIELD_POS equ 0x22
VBE_BLUE_MASK_SIZE  equ 0x23
VBE_BLUE_FIELD_POS  equ 0x24
VBE_PHYS_BASE_PTR   equ 0x28

; Required validations before accepting a candidate:
; - ModeAttributes bit 0 (supported) = 1
; - ModeAttributes bit 4 (graphics) = 1
; - BitsPerPixel = 16
; - MemoryModel = 6 (Direct Color)
; - geometry equals the selected target
; - RGB masks are compatible with the packed pixel conversion routines
; - LFB path only if ModeAttributes bit 7 is set and PhysBasePtr != 0
; - otherwise require a usable VBE window and nonzero WinSize/Granularity.
;
; Never hardcode the VBE mode number: walk the 4F00h mode list, call 4F01h
; for each candidate, and retain the actual returned mode number.
