void _start()
{
    // Just print "BOOT16".
    asm volatile (
        ".intel_syntax noprefix\n"
        "mov ah, 0x0e\n"
        "mov al, 0x42\n"
        "int 0x10\n"
        "mov ah, 0x0e\n"
        "mov al, 0x4f\n"
        "int 0x10\n"
        "mov ah, 0x0e\n"
        "mov al, 0x4f\n"
        "int 0x10\n"
        "mov ah, 0x0e\n"
        "mov al, 0x54\n"
        "int 0x10\n"
        "mov ah, 0x0e\n"
        "mov al, 0x31\n"
        "int 0x10\n"
        "mov ah, 0x0e\n"
        "mov al, 0x36\n"
        "int 0x10\n"
        :::
    );
}
