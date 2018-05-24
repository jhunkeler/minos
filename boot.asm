bits 16

jmp start

CR equ 0Dh
LF equ 0Ah
K_CS_ADDR equ 0050h

; data
drive0: dw 0
banner: db "MINOS Bootloader", CR, LF, 0

; General messages
msg_loading: db "Loading", 0
msg_done: db "done!", CR, LF, 0

; Error messages
error_msg_panic: db "PANIC: ", 0
error_msg_disk_reset: db "Drive reset failed!", CR, LF, 0
error_msg_disk_read: db "Drive read failed!", CR, LF, 0

start:
	cli
	mov ax, 07C0h		; load bootstrap address
	mov ds, ax		; set data segment
	mov es, ax		; set extra segment
	mov ax, stack_end	; load address of temp stack segment
	mov ss, ax		; set stack end
	mov cx, 01FCh
	sub ax, cx
	mov sp, ax		; set stack top before boot signature
	sti

	mov [drive0], dx	; save first detected drive

	push banner		;
	call puts		; print version
	add sp, 2		; clean up

	push word [drive0]
	call disk_reset
	add sp, 2

	push msg_loading
	call puts
	add sp, 2

	; begin disk operations
	xor cx, cx
	mov ax, K_CS_ADDR
	mov es, ax

	mov bx, 0000h		; starting address (es:bx)
	mov di, 2		; start at sector
.loader:
	mov al, 1		; read one sector
	mov cx, di		; track/cyl | sector number
	mov dh, 0		; head number
	mov dl, [drive0]	; drive number
	call disk_read

	push '.'
	call putc
	add sp, 2

	add bx, 0200h		; increment address by 512 bytes
	inc di			; increment track read count
	cmp di, 12h		; transfer 9K (512 * 18)
	jle .loader		; keep reading

	push msg_done
	call puts
	add sp, 2

	mov dx, [drive0]	; the kernel will need the boot drive number
	jmp K_CS_ADDR:0000h	; jump to kernel address

	cli			; disable interrupts
	jmp $			; hang


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


disk_reset:
	mov ah, 00h		; reset disk
				; dl is drive number
	int 13h			; BIOS disk service
	jnc .success

	push error_msg_disk_reset
	call panic

.success:
	ret


disk_read:
	push bp
	mov bp, sp

	push di
	mov di, 3		; retry counter
.readloop:
	push ax
	push bx
	push cx

	mov ah, 02h		; BIOS - read disk sectors
	int 13h			; BIOS disk service

	jnc .success

	call disk_reset

	pop cx
	pop bx
	pop ax

	dec di
	jnz .readloop

	push error_msg_disk_read
	call panic
	add sp, 2

.success:
	pop di
	mov sp, bp
	pop bp
	ret


putc:
	; Write single character at cursor position
	push bp
	mov bp, sp
	pusha

	mov ah, 0eh		; BIOS - teletype
	mov al, [bp + 4]	; character
	mov bx, 0		; video page zero
	int 10h			; BIOS video service

	popa
	mov sp, bp
	pop bp
	ret


puts:
	; Write string buffer at cursor position
	push bp
	mov bp, sp
	pusha

	mov si, [bp + 4]	; address of string buffer
	mov bx, 0000h		;
	mov ah, 0eh		; BIOS - teletype

.loop:
	lodsb			; load byte at [si] into al
	or al, 0		; 0 | 0 = 0 (detect null terminator)
	je .end
	int 10h			; BIOS video service
	jmp .loop
.end:
	popa
	mov sp, bp
	pop bp
	ret

stack_end:	; address of stack end

; boot signature
times 510-($-$$) db 0
dw 0xAA55

