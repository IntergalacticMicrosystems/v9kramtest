; code: language=nasm tabSize=8
%include "defines.inc"

; ---------------------------------------------------------------------------
section_save
; ---------------------------------------------------------------------------
section .rwdata ; MARK: __ .rwdata __
; ---------------------------------------------------------------------------


; ---------------------------------------------------------------------------
section .romdata ; MARK: __ .romdata __
; ---------------------------------------------------------------------------


; ---------------------------------------------------------------------------
section .lib ; MARK: __ .lib __
; ---------------------------------------------------------------------------


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
; DESTROYS: {nothing}
;
; ****************************************************************************
SendAlToCom1Ascii:

	push ax
	push bx
	push cx

	; Save the passed byte for later.
	push ax

	; Send the first byte; the high nibble of the passed byte.
	mov	cl,	4
	shr	al,	cl		; High nibble to low nibble.
	mov	bx,	Tbl_ASCII
	xlatb			; Convert AL into ASCII.
	call	SendAlToCom1Raw

	; Send the second byte; the low nibble of the passed byte.
	pop ax			; Get the passed byte back.
	and	al,	0Fh		; AL only has low nibble of passed AL.
	xlatb			; Convert AL into ASCII.
	call	SendAlToCom1Raw

	; Return to caller.
	pop cx
	pop bx
	pop ax
	ret


; ****************************************************************************
; In RAW form, send the byte in AL to the RS-232 serial port at I/O port 3F8h ('COM1').
;
;   INPUTS: AL contains the byte/code to output.
;
;  OUTPUTS: {nothing}
;
; DESTROYS: {nothing}
;
; ****************************************************************************
SendAlToCom1Raw:

	push es						; Save ES
	push ax						; Save the byte for later.
	mov	ax, SegSerial
	mov es, ax

	; Wait for the COM1 UART to indicate that it is ready for a TX byte.
.L10:	
	test byte [es:SerACtl], 4	; wait for byte empty
	jz	.L10					; --> if UART is not ready.

	; Send the byte.
	pop ax						; Get the byte to send, back into AL.
	mov [es:SerAData], al

	; Return to caller.
	pop es						; restore ES
.EXIT	ret


; input: 
;	al = segment
; MARK: scr_goto_seg
scr_goto_seg:
	push	ax
	push	dx

	; calculate y
	mov	ah, al
	and	ah, 1Fh			; mask out the upper bits
	shr	ah, 1
	shr	ah, 1
	
	mov	dh, y_grid_start+1
	add	dh, ah
	test	al, 10h
	jz	.not_upper
	inc	dh
.not_upper:
	; calculate x
	mov 	dl, al
	and	dl, 0xE0		; mask out the lower bits
	shr	dl, 1
	; shr	dl, 1
	add	dl, x_grid_start	; add the base x position
	add	dl, [ss:test_offset]	; move over to the current test

	call	scr_goto
	pop	dx
	pop	ax
	ret


; MARK: scr_putc
scr_putc:
    call 	SendAlToCom1Raw
	inc word [ss:scrPos]	; increment cursor position
	ret


; MARK: scr_get_hex
scr_get_hex: 
; get the byte value of two hex digits from the screen
; inputs:
;	es:di = address of the hex digits
; outputs:
;	ah = value of the hex digits
    mov ah, 0
    ret


; input:
;	ah = value to print
; MARK: scr_put_hex_ah_h
scr_put_hex_ah_h:	; print high nybble of ah as a hex digit
		push	cx
		mov	cx, 1
		jmp	__scr_put_hex


; input:
;	al = value to print
; MARK: scr_put_hex_ah_l
scr_put_hex_al_l:	; print the low nybble of bh as a hex digit
		push 	ax
		call 	__i2h_al
		call 	scr_putc
		pop	ax
		ret

; input:
;	bx = value to print
; MARK: __scr_put_hex_ax
scr_put_hex_ax:
		push	cx
		mov	cx, 4		; 4 nybbles in ax
		jmp	__scr_put_hex

; input:
;	bh = value to print
; MARK: __scr_put_hex_ah
scr_put_hex_ah:
		push 	cx
		mov	cx, 2		; 2 nybbles in ah
		; fall through to __scr_put_hex

; input:
;	bx = value to print (upper nybble)
;       cx = number of nybbles to print
; MARK: __scr_put_hex
__scr_put_hex:
		push 	ax
		push	bx

	.loop:	rol	ax, 1		; rol	bx, 4
		rol	ax, 1
		rol	ax, 1
		rol	ax, 1

	.put:	
		mov	bx, ax		; save the value
		call	__i2h_al	; convert to ASCII
		call	scr_putc
		mov	ax, bx
		loop	.loop

		pop	bx
		pop	ax
		pop	cx
		ret

; input:
;	al = value to convert
; MARK: __i2h_al
__i2h_al:	; convert low nybble of al to ASCII
		and	al,0fh
		add	al,90h
		daa
		adc	al,40h
		daa
		ret


; MARK: scr_send_esc_lbr
scr_send_esc_lbr:
	mov	al, 1Bh		; Escape
	call	SendAlToCom1Raw
	mov	al, '['
	call	SendAlToCom1Raw
	ret


; MARK: scr_clear
scr_clear:
	call	scr_send_esc_lbr
	mov	al, '2'
	call	SendAlToCom1Raw
	mov	al, 'J'
	call	SendAlToCom1Raw
	mov	[ss:scrPos], word 0


; MARK: scr_goto
scr_goto:
; input:
;	dh = y position
; 	dl = x position
	push	di
	push 	dx
	push	ax
	call	calc_scr_pos
	mov	[ss:scrPos], di
	call 	scr_send_esc_lbr
	mov	al, dh
	call 	__send_al_bcd
	mov	al, ';'
	call	SendAlToCom1Raw
	mov	al, dl
	call 	__send_al_bcd
	mov	al, 'H'
	call	SendAlToCom1Raw
	pop		ax
	pop		dx
	pop		di
	ret


; MARK: scr_getxy
scr_getxy:
; output:
;	dh = y position
; 	dl = x position
	push	ax

	mov	ax, [ss:scrPos]
	mov	dl, 80
	div	dl			; now al = y, ah = x
	mov	dh, al
	mov	dl, ah
	inc dh
	inc dl

	pop	ax
	ret


; MARK: calc_scr_pos
calc_scr_pos:
; input:
;	dh = y position
; 	dl = x position
; output:
;	di = screen position

	push	ax
	push	dx

	cmp dl, 0
	jz		.decx
	dec dl
.decx:
	cmp dh, 0
	jz		.muly
	dec dh
.muly:
	mov	al, 80		; number of columns
	mul	dh			; ax := y * 80
	xor	dh, dh
	add	ax, dx		; add character offset
	mov	di, ax

	pop	dx
	pop	ax
	ret


; MARK: scr_clear_line
scr_clear_line:
	push	ax
	mov	al, ' '
	call	scr_fill_line
	pop	ax
	ret


; MARK: scr_fill_line
scr_fill_line:
		push	cx
		push	dx

		call	scr_getxy
		xor	dl, dl
		call	scr_goto
		mov	cx, 80
		call	scr_fill

		pop	dx
		pop	cx
		ret


; input:
;	cx = number of characters to fill
;	al = character to fill with
; MARK: scr_fill
scr_fill:
		push	di
		push	es
		pushf

		mov	di, ss				; get the video memory segment from SS
		mov	es, di
		mov	di, [ss:scrPos]		; get current cursor position

		cld
		rep	stosw

		popf
		pop	es
		pop	di
		ret


; MARK: scr_test_announce
scr_test_announce:
		push	ax
		push	cx
		push	dx
		push	si
		push	ds

		mov	dx, cs				; we get strings from the ROM in CS
		mov	ds, dx

		mov	dx, scr_ss_xy			; print the stack segment
		call	scr_goto
		mov	ax, ss
		call	scr_put_hex_ax

		mov	dx, scr_pass_xy			; print the pass count
		call	scr_goto
		mov	ax, [ss:pass_count]
		call	scr_put_hex_ax

		mov	dx, scr_test_xy			; print the test label
		call	scr_goto
		mov	cx, scr_test_len
		mov	al, ' '
		call	scr_fill
		mov	dx, scr_test_xy			
		call	scr_goto
		mov	si, [ss:test_label]
		call	scr_puts

		mov	ah, [ss:test_num]		; show the test's number (step for march, value for ganssle)

		call	scr_put_hex_ah

		pop	ds
		pop	si
		pop 	dx
		pop	cx
		pop	ax
		ret


; MARK: __send_al_bcd
__send_al_bcd:
; input:
;	al = binary number
	aam				; convert to BCD
	add ax,	3030h	; convert to ASCII
	push 	ax
	mov al, ah
	call	SendAlToCom1Raw
	pop 	ax
	call	SendAlToCom1Raw
	ret


; input:
;	ds:si = struct: byte x, byte y, string to print (null terminated), [then either more, or attr=0 to end]
; MARK: scr_puts_labels
scr_puts_labels:
		push	ax
		push	di
		push	cs
	pop		ds


.loop:	
	lodsw				; fetch the x,y position
	cmp	al, 0			; check for last string
	je		.done		; if null, we're done
	mov	dx, ax			; ready the x,y pos for the goto call
	call	scr_goto
	call	scr_puts_nosave		; string will now be at [ds:si]
	jmp		.loop		; repeat

.done:	
	pop	di
	pop	ax
	ret	


; input:
;	ds:si = string to print (null terminated)
; output:
;	ds:si = one byte past end of string
; MARK: scr_puts_nosave
scr_puts_nosave:
	push	ax
	push	cx
	pushf
	cld

	xor	cx, cx			; no count limit (well, 64KB)
.loop:	
	lodsb				; al := [ds:si], si += 1
	cmp	al, 0			; check for null terminator
	je	.done			; if null, we're done
	call	SendAlToCom1Raw
	inc word [ss:scrPos]	; increment cursor position
	loop	.loop			; repeat 

.done:
	popf
	pop	cx
	pop	ax
	ret


; MARK: scr_puts
scr_puts:
	push 	si
	push	di
	call 	scr_puts_nosave
	pop	di
	pop	si
	ret	
; ---------------------------------------------------------------------------
section_restore ; MARK: __ restore __
; ---------------------------------------------------------------------------
