del system.img *.bin

nasm -f bin -o boot.bin boot.asm
if %errorlevel% neq 0 exit /b %errorlevel%
nasm -f bin -o kernel.bin kernel.asm
if %errorlevel% neq 0 exit /b %errorlevel%

type boot.bin kernel.bin > system.img
qemu-system-i386 system.img
