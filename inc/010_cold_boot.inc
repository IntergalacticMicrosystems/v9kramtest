; code: language=nasm tabSize=8
%include "defines.inc"

; ---------------------------------------------------------------------------
section_save
section .romdata
; ---------------------------------------------------------------------------
title_rdy:	db "V9KRAMTEST READY", 0
; ---------------------------------------------------------------------------
section_restore
; ---------------------------------------------------------------------------

cold_boot:

; 	Adapted from Victor 9000 ROM
	mov ax, cs					; set data segment to boot rom
	mov ds, ax
	mov ax, Seg6500				; access CRT controller
	mov es, ax
	mov byte [es:CrtRg0], 1
	mov byte [es:CrtRg1], 0		; shut down CRT

init_pic:					; initialize Intel 8259 PIC
	mov ax, SegPic
	mov es, ax				; address the memory-mapped I/O

	mov byte [es:PicPort0], 17h		; edge triggered mode
	mov byte [es:PicPort1], 20h 	; ICW2
	mov byte [es:PicPort1], 01h 	; ICW4 = 8086 mode

	mov cx, 8				; all interrupts are masked
	mov al, 60h				; set up to clear all pending interrupts

.cl1:
	mov [es:PicPort0], al 	; issue SEOI
	inc al
	loop .cl1				; clear all ISR bits

;
;	Initialize serial port
;
ser_init:
	mov ax, SegSerial			; address the serial controller
	mov es, ax
	mov byte al, [es:SerACtl]
	mov byte al, [es:SerBCtl]	; dummy read in case 7201 is confused

	mov byte [es:SerACtl], 18h	; reset channel A
	mov byte [es:SerBCtl], 18h	; reset channel B

	mov byte [es:SerACtl], 2
	mov byte [es:SerACtl], 10h	; disable DMA and IRQ

	mov byte [es:SerBCtl], 2
	mov byte [es:SerBCtl], 0	; clear interrupt vector

	mov byte [es:SerACtl], 3
	mov byte [es:SerACtl], 0c1h	; rx enable, 8 bits

	mov byte [es:SerACtl], 4
	mov byte [es:SerACtl], 44h	; clock rate 16, 1 stop bit, no parity

	mov byte [es:SerACtl], 5
	mov byte [es:SerACtl], 0eah ; tx enable, 8 bits, DTR low		68h is alternative

	mov byte [es:SerACtl], 1
	mov byte [es:SerACtl], 4	; disable interrupts

	mov ax, SegKeyb6522			; address clock selection
	mov es, ax
	or  byte [es:3], 3
	and byte [es:3], 0c3h
	and byte [es:1], 0fch

	mov ax, SegBrt				; 8253 baud rate controller
	mov es, ax
	mov byte [es:3], 36h
	mov byte [es:0], 4			; 19200 Bd
	mov byte [es:0], 0

	mov ax, SegSerial
	mov es, ax
	mov byte [es:SerACtl], 10h	; reset status
	mov byte [es:SerACtl], 30h	; reset error

;
;	print title on serial
;
print_title:
	mov si, title_rdy
.L10:
	mov al, [cs:si]
	and al, al					; end of text?
	jz .S10
	mov [es:SerAData], al
.L20:
%ifndef MAME
	test byte [es:SerACtl], 4	; wait for byte to transmit
	jz .L20
%endif
	inc si
	jmp .L10
.S10:
	
