QEMU=qemu-system-i386

all: system.img

system.img: boot.bin kernel.bin
	cat $^ > $@

boot.bin: boot.asm
	nasm -f bin -l $@.lst -o $@ $<

kernel.bin: kernel.asm
	nasm -f bin -l $@.lst -o $@ $<

run: system.img
	$(QEMU) -d guest_errors -m 16 -hda $<

.PHONY: clean
clean:
	rm *.bin
	rm *.img
	rm *.lst
