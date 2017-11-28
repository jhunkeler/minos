QEMU=qemu-system-i386

all: system.img

system.img: boot.bin kernel.bin
	cat $^ > $@

boot.bin: boot.asm
	nasm -f bin -o $@ $<

kernel.bin: kernel.asm
	nasm -f bin -o $@ $<

run: system.img
	$(QEMU) -m 16 -fda $<

clean:
	rm *.bin *.img
.PHONY: clean
