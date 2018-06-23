QEMU=qemu-system-i386
MEM=16

all: system.img

system.img: boot.bin kernel.bin
	cat $^ > $@

boot.bin: boot.asm
	nasm -g -f bin -l $@.lst -o $@ $<

kernel.bin: kernel.asm
	nasm -g -f bin -l $@.lst -o $@ $<

run: system.img
	$(QEMU) -d guest_errors -m $(MEM) -hda $<

.PHONY: clean
clean:
	rm *.bin
	rm *.img
	rm *.lst
