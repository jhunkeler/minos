%ifndef _BUILTINS_ASM
%define _BUILTINS_ASM

%include "builtin_clear.asm"
%include "builtin_echo.asm"
%include "builtin_exit.asm"
%include "builtin_free.asm"
%include "builtin_reboot.asm"
%include "builtin_vga_demo.asm"
%include "builtin_video_mode.asm"

t_builtins_fn:
	dw builtin_clear
	dw builtin_echo
	dw builtin_exit
	dw builtin_free
	dw builtin_reboot
	dw builtin_vga_demo
	dw builtin_video_mode
	dw 0

t_builtins_str:
	.clear: db 'clear', 0
	.echo: db 'echo', 0
	.exit: db 'exit', 0
	.free: db 'free', 0
	.reboot: db 'reboot', 0
	.vga_demo: db 'vga_demo', 0
	.video_mode: db 'video_mode', 0
	dw 0
%endif
