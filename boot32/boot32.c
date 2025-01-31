#include <stdint.h>

// Link section is important here, because we need this function's code to be
// located at the beggining of a sector.
__attribute__((section(".start"))) void _start(uint8_t drive) {
    char *video = (char *)0xb8000;
    for (int idx = 0; idx < 6; idx++) {
        video[2 * idx] = "BOOT32"[idx];
        video[2 * idx + 1] = 0x07;
    }   

    asm("cli");
    for (;;) {
        asm("hlt");
    }

    return;
}
