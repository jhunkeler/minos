%ifndef _ASCII_ASM
%define _ASCII_ASM

ASCII_NUL equ 00h	; null
ASCII_SOH equ 01h	; start of heading
ASCII_STX equ 02h	; start of text
ASCII_ETX equ 03h	; end of text
ASCII_EOT equ 04h	; end of transmission
ASCII_ENQ equ 05h	; enquiry
ASCII_ACK equ 06h	; acknowledge
ASCII_BEL equ 07h	; bell (audible)
ASCII_BS  equ 08h	; backspace
ASCII_TAB equ 09h	; horizontal tab
ASCII_LF equ 0Ah	; line feed
ASCII_VT equ 0Bh	; vertical tab
ASCII_FF equ 0Ch	; form feed
ASCII_CR equ 0Dh	; carriage return
ASCII_SHO equ 0Eh	; shift out
ASCII_SHI equ 0Fh	; shift in
ASCII_DLE equ 10h	; data link escape
ASCII_DC1 equ 11h	; device control 1
ASCII_DC2 equ 12h	; device control 2
ASCII_DC3 equ 13h	; device control 3
ASCII_DC4 equ 14h	; device control 4
ASCII_NAK equ 15h	; negative acknowledge
ASCII_SYN equ 16h	; synchronous idle
ASCII_ETB equ 17h	; end of transmission block
ASCII_CAN equ 18h	; cancel
ASCII_EM equ 19h	; end of medium
ASCII_SUBST equ 1Ah	; substitute
ASCII_ESC equ 1Bh	; escape
ASCII_FSEP equ 1Ch	; file separator
ASCII_GSEP equ 1Dh	; group separator
ASCII_RSEP equ 1Eh	; record separator
ASCII_USEP equ 1Fh	; unit separator
ASCII_SPC equ 20h	; space

%endif
