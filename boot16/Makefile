CC=clang
LD=x86_64-elf-ld

all: boot16.bin

boot16.o: boot16.c
	clang -c -O2 -fno-builtin --target=i386-unknown-none-code16 -I ../submodules $< -o $@

boot16S.o: boot16.nasm
	nasm $< -f elf32 -o $@

boot16.bin: boot16.ld boot16.o boot16S.o
	$(LD) -m elf_i386 -o $@ -T$^ --oformat binary
