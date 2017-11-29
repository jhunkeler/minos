%ifndef _DISK_ASM
%define _DISK_ASM

disk_lba_chs:
	push bp
	mov bp, sp

	mov ax, word [bp - 2]	; LBA

	mov sp, bp
	pop bp
	ret

disk_reset:
	push bp
	mov bp, sp
	pusha

	mov ah, 00h		; reset disk
	mov dl, [bp + 4]	; disk number
	int 13h			; BIOS disk service
	jnc .success

	push error_msg_disk_reset
	call panic

.success:
	push msg_disk_reset
	call puts
	add sp, 2

	popa
	mov sp, bp
	pop bp
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

	push dx
	call disk_reset
	add sp, 2

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


; data
drive0: dw 0

msg_disk_reset: db "Drive reset successful.", CR, 0
msg_disk_read: db "Sector read successful.", CR, 0

error_msg_disk_reset: db "Drive reset failed!", CR, 0
error_msg_disk_read: db "Drive read failed!", CR, 0

%endif ; _DISK_ASM
