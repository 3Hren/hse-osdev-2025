CC=clang
LD=x86_64-elf-ld

all: boot32.bin

boot32.o: boot32.c
	$(CC) -c -O2 -fno-builtin --target=i386-unknown-none-code32 -I ../submodules $< -o $@

boot32.bin: boot32.ld boot32.o
	$(LD) -m elf_i386 -o $@ -Tboot32.ld boot32.o --oformat binary
