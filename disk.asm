%ifndef _DISK_ASM
%define _DISK_ASM

%include "stdio.asm"
SECTORS_PER_TRACK equ 12h

disk_info:
	push bp
	mov bp, sp
	pusha

	mov ax, 0
	mov es, ax
	mov di, 0

	mov ah, 08h
	mov si, disk_info_fmt
	mov dx, [bp + 4]	; load drive number
				; {diskette=00h..03h, hdd=80h-81h}
	cmp dx, 80h
	jge .is_disk

	.is_diskette:
	mov si, diskette_info_fmt

	.is_disk:
	int 13h
	jc .error

	and word [bp + 4], 07fh	; mask off bit 7

	push cx
	push dx
	push ax
	push word [bp + 4]	; drive number
	push si			; format string
	call printf
	add sp, 2 * 5

	jmp .return

	.error:
		stc
	.return:
		popa
		mov sp, bp
		pop bp
		ret

disk_info_ext:
	push bp
	mov bp, sp
	pusha

	sub sp, 2		; bit-field temp storage

	xor dx, dx
	mov ah, 41h
	mov bx, 55aah
	mov dl, [bp + 4]	; drive number {80h..ffh}
	int 13h
	jc .return		; carry is set on failure
	mov word [bp - 2], cx	; store bit-field

	and dx, 07fh		; mask off bit 7

	xchg ah, al		; extension version
	and ax, 00ffh		; mask off high byte

	push cx
	push ax
	push dx
	push disk_info_ext_fmt
	call printf
	add sp, 2 * 4

	mov dx, word [bp - 2]	; load bit-field
	mov cx, 0000h		; set counter

	.do_flag:
		mov bx, dx	; load BX with bit-field
		shr bx, cl	; shift bit-field by count
		and bx, 01h	; Is the bit set?
		je .no_flag	; non-zero = YES

		push cx		; push count
		call disk_info_ext_print_flag	; display flag
		add sp, 2	; clean up
	.no_flag:
		inc cx		; next bit
		cmp cx, 0fh	; 16 bits in bit field
		jne .do_flag
.return:
	add sp, 2
	popa
	mov sp, bp
	pop bp
	ret


disk_info_ext_print_flag:
	push bp
	mov bp, sp
	pusha

	mov cx, [bp + 4]

	imul cx, cx, 2			; compute WORD offset
	lea bx, [disk_info_ext_table]	; load array address
	add bx, cx			; compute string pointer offset

	push word [bx]			; load address of string pointer
	push .fmt			; load format string
	call printf
	add sp, 2 * 2
.return:
	popa
	mov sp, bp
	pop bp
	ret
	.fmt db "           - %s", ASCII_LF, 0


disk_last_status:
	push bp
	mov bp, sp

	clc				; clear carry flag
					; DL = drive number
	mov ah, 01h			; BIOS get status of last drive operation
	int 13h				; BIOS disk service
					; carry set on error
	mov sp, bp
	pop bp
	ret


disk_convert_status:
	push bp
	mov bp, sp
	pusha

	cmp ah, 00h			; Avoid writing "success" message
	je .return

	xor cx, cx
	mov cx, ax			; AL contains the sector count
	and cx, 00ffh			; store in CX
	shr ax, 8			; shift error code into AL

					; This block handles AL when not 00h..11h
					; The extended error values have no real order
	cmp al, 20h
	je .status_20

	cmp al, 40h
	je .status_40

	cmp al, 80h
	je .status_80

	cmp al, 0AAh
	je .status_AA

	cmp al, 0BBh
	je .status_BB

	cmp al, 0CCh
	je .status_CC

	cmp al, 0E0h
	je .status_E0

	cmp al, 0FFh
	je .status_FF

	jmp .convert				; No match, convert AL as-is

						; Adjust error code so that it can be indexed
						; easily by error_msg_disk_table
	.status_20:
		mov al, 12h
		jmp .convert

	.status_40:
		mov al, 13h
		jmp .convert

	.status_80:
		mov al, 14h
		jmp .convert

	.status_AA:
		mov al, 15h
		jmp .convert

	.status_BB:
		mov al, 16h
		jmp .convert

	.status_CC:
		mov al, 17h
		jmp .convert

	.status_E0:
		mov al, 18h
		jmp .convert

	.status_FF:
		mov al, 19h
		jmp .convert

	.convert:
		mov bx, ax			; Get array index
		imul bx, bx, 2			; Calculate index offset
						; in human speak: idx * (idx * WORD)

		lea si, [error_msg_disk_table]	; Load address of table into source index
		add si, bx			; Add calculated index offset

	and dx, 00ffh				; get drive number

	push word [si]				; error message
	push dx					; drive number
	push ax					; error code
	push error_msg_disk_status_fmt
	call printf				; Print error message
	add sp, 2 * 4				; Clean up stack

.return:
	popa
	mov sp, bp
	pop bp
	ret



disk_reset:
	push bp
	mov bp, sp
	pusha

	mov ah, 00h		; reset disk
	mov dl, byte [bp + 4]	; disk number
	int 13h			; BIOS disk service
	jnc .success
	stc
.success:
	popa
	mov sp, bp
	pop bp
	ret


disk_lba_chs:
	push bp
	mov bp, sp
	push ax
	push bx
	push dx
	sub sp, 2 * 3		; -2 = HEAD
				; -4 = TRACK
				; -6 = SECTOR

	mov si, [bp + 4] ; Linear Block Address

	; compute HEAD
	mov cx, SECTORS_PER_TRACK
	shl cx, 1			; SPT * 2
	xor dx, dx			; initialize quotient
	mov ax, si			; LBA %
	mov bx, cx			; (SPT * 2)
	div bx

	mov ax, dx			; use quotient as next dividend
	xor dx, dx
	mov bx, SECTORS_PER_TRACK	; / SPT
	div bx
	mov [bp - 2], ax		; store HEAD (remainder)

	; compute TRACK
	xor dx, dx   			; initialize quotient
	mov ax, si			; LBA %
	mov bx, cx			; (SPT * 2)
	div bx
	mov [bp - 4], ax		; store TRACK (remainder)

	; compute SECTOR
	xor dx, dx
	mov ax, si
	mov bx, SECTORS_PER_TRACK
	div bx
	add dx, 1
	mov [bp - 6], dx		; store SECTOR (quotient)

	pop dx
	pop bx
	pop ax

	; assemble return values
	mov dh, byte [bp - 2]		; load HEAD
	mov ch, byte [bp - 4]		; load TRACK
	mov cl, byte [bp - 6]		; load SECTOR

	add sp, 2 * 3
	mov sp, bp
	pop bp
	ret


disk_read:
	push bp
	mov bp, sp

	mov si, [bp + 4]	; LBA

	push si
	call disk_lba_chs		; convert LBA to CHS
	add sp, 2

	mov ah, 02h
	mov dl, byte [bp + 6]	; drive number
	mov al, byte [bp + 8]	; number of sectors to read
	mov bx, [bp + 10]	; data destination address [es:bx]
	int 13h
	jnc .success

	call disk_convert_status

	push dx
	call disk_reset
	add sp, 2
	stc
.success:
	mov sp, bp
	pop bp
	ret


disk_write:
	push bp
	mov bp, sp

	mov si, [bp + 4]	; LBA

	push si
	call disk_lba_chs		; convert LBA to CHS
	add sp, 2

	mov ah, 03h
	mov dl, byte [bp + 6]	; drive number
	mov al, byte [bp + 8]	; number of sectors to read
	mov bx, [bp + 10]	; data destination address [es:bx]
	int 13h
	jnc .success

	call disk_convert_status

	push dx
	call disk_reset
	add sp, 2
	stc
.success:
	mov sp, bp
	pop bp
	ret


; data
align 2
drive0: dw 0

msg_disk_reset: db "Drive reset successful.", ASCII_LF, 0
msg_disk_read: db "Sector read successful.", ASCII_LF, 0

error_msg_disk_reset: db "Drive reset failed!", ASCII_LF, 0
error_msg_disk_read: db "Drive read failed!", ASCII_LF, 0

diskette_info_fmt: db 'FDD(%x): status=%x head_max=%x cyl_max=%x', ASCII_LF, 0

disk_info_fmt: db 'HDD(%x): status=%x head_max=%x cyl_max=%x', ASCII_LF, 0
disk_info_ext_fmt: db 'HDD(%x): IBM/MS INT 13 Extensions v%x [%x]', ASCII_LF, 0

disk_info_ext_flags:
	.bit_0: db "Extended disk access support", 0
	.bit_1: db "Removable drive controller support", 0
	.bit_2: db "Enhanced disk drive support", 0
	.reserved: db "Reserved", 0

disk_info_ext_table:
	dw disk_info_ext_flags.bit_0
	dw disk_info_ext_flags.bit_1
	dw disk_info_ext_flags.bit_2
	.reserved: times(15-3) dw disk_info_ext_flags.reserved
	dw 0000h	; END of disk_info_ext_table

error_msg_disk_status_fmt: db 'ERROR %x: Drive %x: %s', ASCII_LF, 0
error_msg_disk:
	eds_success: db "Success", 0					; 00h
	eds_invalid_command: db "Invalid command", 0
	eds_address_mark: db "Cannot find address mark", 0
	eds_write_protected: db "Attempted write on write protected disk", 0
	eds_sector_not_found: db "Sector not found.", 0
	eds_reset_failed: db "Reset failed.", 0
	eds_disk_change_line_active: db "Disk change line active", 0
	eds_drive_parameter_activity_failed: db "Drive parameter activity failed", 0
	eds_dma_overrun: db "DMA overrun", 0
	eds_dma_boundary_64: db "DMA over 64kb boundary", 0
	eds_bad_sector: db "Bad sector detected", 0
	eds_bad_cylinder: db "Bad cylinder detected", 0
	eds_media_type_not_found: db "Media type not found", 0
	eds_invalid_number_of_sectors: db "Invalid number of sectors", 0
	eds_control_data_address_mark: db "Control data address mark detected", 0
	eds_dma_out_of_range: db "DMA out of range", 0
	eds_crc_ecc_data_error: db "CRC/ECC data error", 0	 	; 10h
	eds_ecc_corrected_data_error: db "ECC corrected data error", 0	; 11h
	; Everything was normal until... this...
	eds_controller_failure: db "Controller failure", 0		; 20h
	eds_seek_failure: db "Seek failure", 0				; 40h
	eds_timeout: db "Drive timed out (not ready?)", 0		; 80h
	eds_not_ready: db "Drive not ready", 0				; AAh
	eds_undefined_error: db "Undefined error", 0			; BBh
	eds_write_fault: db "Write fault", 0				; CCh
	eds_status_error: db "Status error", 0				; E0h
	eds_sense_operation_failed: db "Sense operation failed", 0	; FFh

error_msg_disk_table:				; is an array of pointers for each error message
	dw eds_success
	dw eds_invalid_command
	dw eds_address_mark
	dw eds_write_protected
	dw eds_sector_not_found
	dw eds_reset_failed
	dw eds_disk_change_line_active
	dw eds_drive_parameter_activity_failed
	dw eds_dma_overrun
	dw eds_dma_boundary_64
	dw eds_bad_sector
	dw eds_bad_cylinder
	dw eds_media_type_not_found
	dw eds_invalid_number_of_sectors
	dw eds_control_data_address_mark
	dw eds_dma_out_of_range
	dw eds_crc_ecc_data_error
	dw eds_ecc_corrected_data_error
	dw eds_controller_failure
	dw eds_seek_failure
	dw eds_timeout
	dw eds_not_ready
	dw eds_undefined_error
	dw eds_write_fault
	dw eds_status_error
	dw eds_sense_operation_failed
	dw 0000h				; END of error_msg_disk_table

%endif ; _DISK_ASM
