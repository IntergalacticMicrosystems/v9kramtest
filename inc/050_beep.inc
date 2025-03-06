InitBeep:
	__CHECKPOINT__NOSTACK__ 0x0A
; ****************************************************************************
; Beep the speaker three times: short-long-short.
;
; >>> Yes, we are taking the chance that the circuitry involved in beeping the speaker is working. <<<
; For those without an MDA/CGA card, and without a parallel/LPT reader, and without a serial reader,
; this beeping indicates that the code has started to execute.

	mov ax, Seg6500
	mov es, ax
	and byte [es:CodecCtl], 3Fh			; disable codec clock

	mov ax, 5E00h					; initialize codec SDA to input mode
	mov word [es:CodecSda], ax
	mov ax, 0D40h					;   to reduce extraneous noise
	mov word [es:CodecSda], ax
	mov ax, 0AA80h
	mov word [es:CodecSda], ax
	mov ax, 00C0h
	mov word [es:CodecSda], ax

	mov al, [es:VolumeCtl]
	and al, 0C3h
	or  al, 10h
	mov [es:VolumeCtl], al			; set SR & T2 volume register modes
	mov ax, 1
	mov word [es:VolumeClk], ax		; Volume clock frequency set beyond perception
	mov ax, 3
	mov word [es:Volume], ax		; set volume level

	mov ax, 0F80h					; set output waveform to 4 up, 4 down triangle
	mov word [es:CodecSda], ax
	mov ax, 5554h					; set audio pitch frequency
	mov [es:CodecClk], ax

	; One short beep
	mov al, [es:CodecCtl]
	or  al, 0C0h					; set codec clock to free run
	mov [es:CodecCtl], al
	mov al, 1						; 1 = short beep
	mov cx, 2000h
.L10: loop .L10
	dec al
	jnz .L10
	mov al, [es:CodecCtl]
	and al, 3Fh						; set codec clock to off
	mov [es:CodecCtl], al

	; Inter-beep delay
	mov cx, 2000h
	loop $

	; One long beep
	mov al, [es:CodecCtl]
	or  al, 0C0h					; set codec clock to free run
	mov [es:CodecCtl], al
	mov al, 2						; 2 = long beep
	mov cx, 2000h
.L30: loop .L30
	dec al
	jnz .L30
	mov al, [es:CodecCtl]
	and al, 3Fh						; set codec clock to off
	mov [es:CodecCtl], al

	; Inter-beep delay
	mov cx, 2000h
	loop $

	; One short beep
	mov al, [es:CodecCtl]
	or  al, 0C0h					; set codec clock to free run
	mov [es:CodecCtl], al
	mov al, 1						; 1 = short beep
	mov cx, 2000h
.L50: loop .L50
	dec al
	jnz .L50
	mov al, [es:CodecCtl]
	and al, 3Fh						; set codec clock to off
	mov [es:CodecCtl], al

