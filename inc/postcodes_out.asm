; code: language=nasm tabSize=8
%include "defines.inc"


; ****************************************************************************
; Subroutine for outputting a byte to:
;     - the three standard LPT ports; and
;     - the RS-232 serial port at I/O port 3F8h ('COM1'); and
;     - IBM's debug port.
;
; For the serial port, send a CRLF sequence BEFORE the byte, and convert the byte to two ASCII bytes.
;
;   INPUTS: AL contains the byte/code to output.
;
;  OUTPUTS: {nothing}
;
; DESTROYS: AX, CL, DI, DX
;
; ****************************************************************************
CheckpointStack:

%ifdef USE_LPT
	;--------------------------------------------
	; Output to the standard parallel/LPT ports.
	;--------------------------------------------
	mov	dx,LPT1
	out	dx,al
	mov	dx,LPT2
	out	dx,al
	mov	dx,LPT3			; I/O port 3BCh. Parallel/LPT port on most MDA cards.
	out	dx,al
%endif

	mov dx, FE_Ioport
	out dx, al				; issue the error for FE scoping
	
	;--------------------------------------------
	; Display the byte in the top-right corner of the screen.
	;--------------------------------------------
	; call	DispAlTopCorner		; ( Destroys: BX, CL, DI )

	;--------------------------------------------
	; Output the byte to the serial port of 3F8h ('COM1').
	; Start with a CRLF sequence, then the byte.
	;
	; The byte needs to be converted to ASCII.
	; For example, 8Ah would be converted to two bytes: 38h for the '8' followed by 42h for the 'A'.
	;--------------------------------------------

%ifdef	USE_SERIAL
	; Save the byte for later.
	mov	bp,ax

	; Send a CRLF sequence.
	call	SendCrlfToCom1	; ( Destroys: AX, DX )

	; Send the byte as two ASCII bytes.
	mov	ax,bp			; Get the byte to send back into AL.
	call	SendAlToCom1Ascii	; ( Destroys: AX, BP, BX, CL, DX )
%endif

	;------------------------
	; Return to caller.
	;------------------------
	ret


; ****************************************************************************
; Send a CR/LF/hash sequence to the RS-232 serial port at I/O port 3F8h ('COM1').
;
;   INPUTS: {nothing}
;
;  OUTPUTS: {nothing}
;
; DESTROYS: AX, DX
;
; ****************************************************************************
SendCrlfToCom1:

	mov	al,0Dh		; Carriage return (CR)
	call	SendAlToCom1Raw	; ( Destroys: AX, DX )
	mov	al,0Ah		; Line feed (LF)
	call	SendAlToCom1Raw	; ( Destroys: AX, DX )
	ret


; ****************************************************************************
; In ASCII form, send the byte in AL to the RS-232 serial port at I/O port 3F8h ('COM1').
; For example, 8Ah would be converted to two bytes: 38h for the '8' followed by 42h for the 'A'.
;
;   INPUTS: AL contains the byte/code to output.
;
; REQUIREMENT: For XLATB, DS is set to the CS (where Tbl_ASCII is). This is normally the case in this program.
;
;  OUTPUTS: {nothing}
;
; DESTROYS: AX, BP, BX, CL, DX
;
; ****************************************************************************
SendAlToCom1Ascii:

	; Save the passed byte for later.
	mov	bp,ax

	; Send the first byte; the high nibble of the passed byte.
	mov	cl,4
	shr	al,cl		; High nibble to low nibble.
	mov	bx,Tbl_ASCII
	xlatb			; Convert AL into ASCII.
	call	SendAlToCom1Raw	; ( Destroys: AX, DX )

	; Send the second byte; the low nibble of the passed byte.
	mov	ax,bp		; Get the passed byte back.
	and	al,0Fh		; AL only has low nibble of passed AL.
	mov	bx,Tbl_ASCII
	xlatb			; Convert AL into ASCII.
	call	SendAlToCom1Raw	; ( Destroys: AX, DX )

	; Return to caller.
.EXIT	ret


; ****************************************************************************
; In RAW form, send the byte in AL to the RS-232 serial port at I/O port 3F8h ('COM1').
;
;   INPUTS: AL contains the byte/code to output.
;
;  OUTPUTS: {nothing}
;
; DESTROYS: AX, BX
;
; ****************************************************************************
SendAlToCom1Raw:

	mov	bl, al					; Save the byte for later.
	push es						; Save ES
	mov	ax, SegSerial
	mov es, ax

	; Wait for the COM1 UART to indicate that it is ready for a TX byte.
.L10:	
%ifndef MAME
	test byte [es:SerACtl], 4	; wait for byte empty
	jz	.L10					; --> if UART is not ready.
%endif

	; Send the byte.
	mov	al, bl					; Get the byte to send, back into AL.
	mov [es:SerAData], al

	; Return to caller.
	pop es						; restore ES
.EXIT	ret
