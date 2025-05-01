; code: language=nasm tabSize=8
[list -]
%ifndef DEFINES_INC
%define DEFINES_INC

BITS 16
CPU 8086

%include "macros.inc"

rwdata_base	    equ	4000		; Offset of unused portion of MDA/CGA video RAM
rwdata_init_sp	equ	1000h		; What we will set the stack pointer to.

;-------------------------------------------------------------------------------
; I/O port information
;-------------------------------------------------------------------------------
SegPic          equ 0E000h          ; Programmable Interrupt Controller
PicPort0        equ 00h
PicPort1        equ 01h

SegBrt          equ 0E002h          ; Baud rate controller

SegSerial       equ 0E004h          ; uP D7201 Serial Communications Controller
SerAData        equ 00h
SerBData        equ 01h
SerACtl         equ 02h
SerBCtl         equ 03h

Seg6500         equ 0E800h          ; I/O port for 6500 (CRT and floppy)
CrtRg0          equ 00h
CrtRg1          equ 01h
CodecClk        equ 84h
CodecCtl        equ 8Bh
CodecSda        equ 60h
Volume          equ 2Ah
VolumeCtl       equ 2Bh
VolumeClk       equ 28h
Via6OraIra      equ 0CFh

SegKeyb6522     equ 0E804h          ; Keyboard 6255

SegUser6522     equ 0E808h          ; User port 6522

ScreenRam       equ 0F000h          ; Segment of screen RAM
OurSpAddress	equ	0FFFh		    ; What we will set the stack pointer to.

FE_Ioport       equ 0FFFFh          ; Port to tell field service what's wrong

FE_screen	    equ	01h             ; FE error unreproducable screen ram error
FE_bad_chksum	equ	02h             ; FE error code for bad ROM checksum
FE_16K		    equ	03h             ; FE error unreproducable error in first 16K
FE_bad_screen	equ	10h             ; FE error code for bad screen ram
FE_screen_mult	equ	20h             ; FE error code for bad screen ram, >1 bit error
FE_16K_error	equ	30h             ; FE error code for error in first 16K
FE_16K_mult	    equ	40h             ; FE error code for error in first 16K, >1 bit

F_led0          equ 01h
F_led1          equ 04h

%endif
[list +]