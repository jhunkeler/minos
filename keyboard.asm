%ifndef _KEYBOARD_ASM
%define _KEYBOARD_ASM

; REFERENCE(s):
;	http://stanislavs.org/helppc/int_16-3.html

kbd_read:
	mov ah, 00h		; BIOS - read key (blocking)
	int 16h			; BIOS keyboard service
	mov [kbd_last_key], ax	; Record keypress
				; ah = scancode
				; al = ascii code
	ret


kbd_read_async:
	mov ah, 01h		; BIOS - read key (non-blocking)
	int 16h			; BIOS keyboard service
	mov [kbd_last_key], ax	; Record keypress
				; ah = scancode
				; al = ascii code
	ret


kbd_status_shift:
	mov ah, 02h		; BIOS - keyboard status
				; al = flags
				;
				; bit fields:
				;	7 = insert active
				;	6 = caps-lock active
				;	5 = num-lock active
				;	4 = scroll-lock active
				;	3 = ALT depresssed
				;	2 = CTRL depressed
				;	1 = left shift depressed
				;	0 = right shift depressed
	mov [kbd_status_flags], byte al
	int 16h			; BIOS keyboard service

	ret


kbd_set_rate:
	push bp
	mov bp, sp

	mov ah, 03h		; BIOS - keyboard service rate/delay
	mov al, 05h		; CONTROL
				; 00 - set typematic rate
				; 01 - increase delay
				; 02 - decrease rate by 0.5
				; 04 - disable typematic characters
				; 05 - set typematic rate & delay (used here)

	mov bh, byte [bp + 4]	; REPEAT (per second)
				; 00 - 30.0	01 - 26.7	02 - 24.0	  03 - 21.8
				; 04 - 20.0	05 - 18.5	06 - 17.1	  07 - 16.0
				; 08 - 15.0	09 - 13.3	0A - 12.0	  0B - 10.9
				; 0C - 10.0	0D - 9.2	0E - 8.6	  0F - 8.0
				; 10 - 7.5	11 - 6.7	12 - 6.0	  13 - 5.5
				; 14 - 5.0	15 - 4.6	16 - 4.3	  17 - 4.0
				; 18 - 3.7	19 - 3.3	1A - 3.0	  1B - 2.7
				; 1C - 2.5	1D - 2.3	1E - 2.1	  1F - 2.0

	mov bl, byte [bp + 6]	; DELAY
				; 00 - 250ms
				; 01 - 500ms
				; 02 - 750ms
				; 03 - 1000ms

	int 16h			; BIOS keyboard service

	mov sp, bp
	pop bp
	ret


; data
kbd_last_key: dw 0
kbd_status_flags: db 0
%endif
