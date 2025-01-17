.PHONY: run clean

LD=x86_64-elf-ld

bootsector.o: bootsector.nasm
	nasm bootsector.nasm -f elf32 -o $@

bootsector.bin: bootsector.o
	$(LD) -m elf_i386 -o $@ -T bootsector.ld bootsector.o --oformat binary

run: bootsector.bin
	qemu-system-x86_64 -nographic -drive format=raw,file=bootsector.bin

clean:
	rm -rf *.o *.bin