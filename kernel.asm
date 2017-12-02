bits 16

jmp kmain

%include "constants.asm"
%include "string.asm"
%include "disk.asm"
%include "console.asm"
%include "stdio.asm"
%include "terminal.asm"		; eventually will become its own "program"


kmain:
	cli			; disable interrupts
	mov ax, cs		; get code segment
	mov ds, ax		; set data segment
	mov es, ax		; set extra segment
	mov ax, 8000h
	mov ss, ax		; set stack segment
	mov sp, 0ffffh		; set stack pointer (~64k)
	sti			; enable interrupts

	mov [drive0], dx	; store bootloader's drive number

	; reset general purpose registers
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
	xor di, di
	xor si, si
	xor bp, bp

	call cls		; clear console
	push 0			; home the cursor
	call setcursor

	push banner
	call puts
	add sp, 2

	push sp
	push ss
	push sp
	push ss
	push kmain
	push cs
	push kmain
	push cs
	push msg_test
	call printf
	add sp, 12

.mainloop:
	call terminal

	jmp .mainloop

	cli
	jmp $


panic:
	; Hang system with supplied error message
	push bp
	mov bp, sp

	push error_msg_panic	; i.e. 'PANIC:'
	call puts
	add sp, 2

	push word [bp + 4]	; address of error string buffer
	call puts		; print error
	add sp, 2

	cli			; disable interrupts
	jmp $			; hang (no return)
				; stack is dead


; data
msg_entry_point: db 'Loaded at ', 0
msg_entry_point_stack: db 'Stack at ', 0
banner: db "+========================+", CR
	db "| Welcome to MINOS 0.0.1 |", CR
	db "+========================+", CR
	db CR, 0

msg_test: db 'Kernel address:	%x:%x (%d:%d)', CR
          db 'Stack address :	%x:%x (%d:%d)', CR, CR, 0

; Error messages
error_msg_panic: db "PANIC: ", 0

times 512 * 20h db 0
dw 0xefbe
