%ifndef _CONSTANTS_ASM
%define _CONSTANTS_ASM

LENGTH_ROW equ 0A0h	; NOTE: length in bytes (80 * 2 = 160)

%include "ascii.asm"		; ASCII control codes
%include "scancodes.asm"	; Keyboard scancodes

%endif

