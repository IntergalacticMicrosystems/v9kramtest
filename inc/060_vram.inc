; code: language=nasm tabSize=8
%include "defines.inc"


; ****************************************************************************
; From here on, we need RAM for variables and for the stack.
;
; If any of those found, set ES to it.
; If none found, send checkpoint 8A then halt the CPU.

test_vram:
	__CHECKPOINT__NOSTACK__ 0x0B

	mov	si, 4096		; size of VRAM to test
	mov	ax, cs
	mov	ss, ax			; SS := CS
	mov	ax, ScreenRam
	mov	es, ax

test_vram_march:
	romcall	marchu_nostack

	or	dh, dh			; did the RAM pass?
	jz	.pass			; --> if yes, we have video RAM

	__CHECKPOINT__NOSTACK__ 0x0C ;++++++++++++++++++++++++++++++++++++++++

	; Halt the CPU.
	cli
	hlt


	;------------------------
	; Test successful.
	; -----------------------
	; MDA/CGA: Set the stack top to near the top of video RAM.
	;   A0000: Set the stack top at 4094 bytes into RAM.
.pass:
	mov	ax, es
	mov	ss, ax				; SS = ES = segment address of video RAM (either MDA or CGA or A0000).
	mov	sp, rwdata_init_sp	; 4096


; Info:	SS won't change anymore and will serve as a permanent pointer to the video RAM segment.

; Info:	We now have a stack. Therefore, we can now use '__CHECKPOINT__' (uses the stack) instead
;	of '__CHECKPOINT__NOSTACK__' (does not use the stack). This will reduce the amount of code.

	__CHECKPOINT__ 0x0F ;++++++++++++++++++++++++++++++++++++++++

; ****************************************************************************
; Blink the LEDs on the floppies to tell the user we're alive
blink_leds:
	mov ax, Seg6500			; address the floppy
	mov es, ax

	mov byte [es:Via6OraIra], (F_led0+F_led1)	; turn both LEDs on
	mov ax, 5000			; wait half a second
	call Time

	and byte [es:Via6OraIra], ~(F_led0+F_led1)	; trun LEDs off
