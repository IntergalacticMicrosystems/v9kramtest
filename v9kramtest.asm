; --- refresh time delay ---
%define REFRESH_DELAY 5

; ************************************************************************************************
%include "defines.inc"

[map all v9kramtest.map]

; START		equ	0E000h
; RESET		equ	0FFF0h
; BASESEG		equ	0F000h

; section .romdata	start=START align=1
; section .lib		follows=.romdata align=1
; section .text		follows=.lib align=1
; section .resetvec 	start=RESET align=1

START		equ	00000h
RESET		equ	01FF0h
BASESEG		equ	0FE00h

section .text		start=START align=1
section .lib		follows=.text align=1
section .romdata	follows=.lib align=1
section .resetvec 	start=RESET align=1

; .rwdata section in the unused portion of MDA/CGA video RAM, starting at 4000 DECIMAL - 96 bytes.
; variables at the bottom, stack at the top.
section .rwdata		start=rwdata_base align=1 nobits
rwdata_start:

; %define num_segments 8
%define first_segment 0
%define num_segments 56   ; 40 = 640K, 56 = 896K
%define bytes_per_segment 0x4000   ; 0x4000
%define USE_SERIAL 1

; ---------------------------------------------------------------------------
section .rwdata ; MARK: __ .rwdata __
; ---------------------------------------------------------------------------
;Variables stored in unused MDA/CGA video RAM, or 4 KB at A0000.
; ---------------------------------------------------------------------------
	pass_count	dw	?			; The number of passes completed. Incremented by 1 each time a pass is completed.

	do_not_use	equ	rwdata_base+38		; Do not use this location. It caused a problem if a Mini G7 video card was used.

; ---------------------------------------------------------------------------
section .romdata ; MARK: __ .romdata __

%defstr VERSION_STRING VERSION

title_text: ; x, y, text, 0 (terminate with 0 for attr)
			db 	1,  1, "V9KRAMTEST ", 0
			;db	12, 1, VERSION_STRING, " (", __DATE__, ")", 0
			db	46,  1, "github.com/freitz85/v9kramtest.git", 0
			db	4,  3, "by Florian Reitz - based on XTRAMTEST by Dave Giller", 0
			db	0
Tbl_ASCII:
			db '0123456789ABCDEF'
			db  0
; ---------------------------------------------------------------------------
section .lib ; MARK: __ .lib __
; ---------------------------------------------------------------------------

; procedures to include in the ROM
%include "delay.asm"
%include "postcodes_out.asm"
%include "serial.asm"
%include "screen.asm"
%include "ram_common.asm" 
%include "ram_marchu_nostack.asm" 

; ---------------------------------------------------------------------------
section .text ; MARK: __ .text __
; ---------------------------------------------------------------------------

; ************************************************************************************************
; Initialization modules
%include "010_cold_boot.inc"
;%include "030_video.inc"

v9kramtest_start: 
	;%include "050_beep.inc"
	%include "060_vram.inc"

	__CHECKPOINT__ 0x10 ;++++++++++++++++++++++++++++++++++++++++

	; Disable maskable interrupts, and set the direction flag to increment.
	cli
	cld

v9kramtest_loop: 
	add	word [ss:pass_count], 1		; Increment the pass count.

	call	scr_clear
	call 	draw_screen

	%include "ram_marchu.asm" 
	%include "ram_ganssle.asm" 
 
	jmp	v9kramtest_loop 
	hlt


;------------------------------------------------------------------------------
; Power-On Entry Point
;------------------------------------------------------------------------------
; ---------------------------------------------------------------------------
section .resetvec ; MARK: __ .resetvec __
; ---------------------------------------------------------------------------
PowerOn:	
	jmp	BASESEG:cold_boot	; CS will be 0F000h


S_FFF5:
	db __DATE__		; Assembled date (YYYY-MM-DD)
	db 0			; space for checksum byte


section .rwdata
	rwdata_end: