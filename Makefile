# Makefile syntax:
#
# <target>: <prerequisites>
# 	<recipe>
#
# Then in out shell just execute "make <target>", for example "make run".

# $@ - name of the target of the rule.
# $< - name of the first prerequisite.
# $^ - names of all the prerequisites, with spaces between them.

# Treat the following targets as non-file targets.
.PHONY: run dbg

# Linker variable.
LD=x86_64-elf-ld
# Our debugger.
GDB=x86_64-elf-gdb
# Object dump binary.
OBJDUMP=x86_64-elf-objdump

bootsector.o: bootsector.nasm
	nasm bootsector.nasm -f elf32 -o $@

bootsector.bin: bootsector.o bootsector.ld
	$(LD) -m elf_i386 -o $@ -Tbootsector.ld bootsector.o --oformat binary

boot16.o: boot16.c
	clang -c -Oz --target=i386-unknown-none-code16 $< -o $@

boot16.bin: boot16.o boot16.ld
	$(LD) -m elf_i386 -o $@ -Tboot16.ld boot16.o --oformat binary

image.bin: bootsector.bin boot16.bin
	cat $^ > $@
	./partition.py $@ $^

run: image.bin
	qemu-system-x86_64 -nographic -drive format=raw,file=$< -serial mon:stdio

objdump/bootsector.bin: bootsector.bin
	$(OBJDUMP) -D -b binary -mi386 -Maddr16,data16,intel $<

dbg: image.bin
	qemu-system-i386 -nographic -drive format=raw,file=$< -s -S &
	$(GDB) kernel.bin \
		-ex "set architecture i8086" \
		-ex "target remote localhost:1234" \
		-ex "break *0x7c00" \
		-ex "continue"

clean:
	rm -rf *.o *.bin *.img *.elf target
