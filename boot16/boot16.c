#include <stdint.h>

// Disable "long long" support in "printf", because they require long division
// instruction, which is not available in 16-bit mode.
#define PRINTF_DISABLE_SUPPORT_LONG_LONG
// Yes, include ".c" file, because why not.
#include "printf/printf.c"

struct gdt_ptr_t;

extern void start32(struct gdt_ptr_t *gdt, uint8_t drive);

void tty_print_char(char c) {
    uint16_t ax = 0x0e00 | c;

    asm volatile("int $0x10\n\t" : : "a"(ax) :);
}

void tty_print(const char *s) {
    while (*s) {
        tty_print_char(*s);
        s++;
    }
}

// For "printf".
void _putchar(char character) {
    tty_print_char(character);
}

struct gdt_entry_t {
    uint16_t limit_lo;
    uint16_t base_lo;
    uint8_t base_mi;
    uint8_t access;
    uint8_t granularity;
    uint8_t base_hi;
} __attribute__((packed));

struct gdt_ptr_t {
    unsigned short limit;
    unsigned int base;
} __attribute__((packed));

static struct gdt_entry_t gdt[3];
static struct gdt_ptr_t gp;

void gdt_set_gate(
    int idx, uint32_t base, uint32_t limit, uint8_t access, uint8_t gran
) {
    // Base Address.
    gdt[idx].base_lo = (base & 0xffff);
    gdt[idx].base_mi = (base >> 16) & 0xff;
    gdt[idx].base_hi = (base >> 24) & 0xff;
    // Limit.
    gdt[idx].limit_lo = (limit & 0xffff);
    gdt[idx].granularity = (limit >> 16) & 0x0f;
    // Granularity.
    gdt[idx].granularity |= (gran & 0xf0);
    // Access flags.
    gdt[idx].access = access;
}

// Partition table entry.
struct pte_t {
    uint8_t boot_indicator;
    uint8_t __dont_care0;
    uint16_t __dont_care1;
    uint16_t __dont_care2;
    uint16_t __dont_care3;
    uint32_t start_lba;
    uint32_t length;
} __attribute__((packed));

void dump_partition_table() {
    char *pte_ptr = (char *)(0x7c00 + 446);
    for (int idx = 0; idx < 4; idx++) {
        struct pte_t *entry = (struct pte_t *)pte_ptr;
        printf(
            "[     0.000000] BOOT16: MBR PTE[%d] LBA 0x%08x, len 0x%08x\r\n",
            idx,
            entry->start_lba,
            entry->length
        );
        pte_ptr += sizeof(struct pte_t);
    }
}

void init_gdt() {
    gp.limit = 3 * sizeof(struct gdt_entry_t) - 1;
    gp.base = (unsigned int)&gdt;
    // Null segment.
    gdt_set_gate(0, 0, 0, 0, 0);
    // Code segment.
    gdt_set_gate(1, 0, 0xffffffff, 0x9a, 0xcf);
    // Data segment.
    gdt_set_gate(2, 0, 0xffffffff, 0x92, 0xcf);
}

void dump_gdt() {
    for (int idx = 0; idx < 3; idx++) {
        printf(
            "[     0.000000] BOOT16: GDT%d 0x%08x%08x\r\n",
            idx,
            *(uint32_t *)(&gdt[idx]),
            *((uint32_t *)(&gdt[idx]) + 1)
        );
    }
}

void panic(const char *message) {
    printf("[     0.000000] BOOT16: panic - %s\r\n", message);
    for (;;) {
        asm("cli");
        asm("hlt");
    }
}

// Link section is important here, because we need this function's code to be
// located at the beggining of a sector.
__attribute__((section(".start"))) void _start(uint8_t drive) {
    printf("[     0.000000] BOOT16: drive 0x%04x\r\n", drive);

    dump_partition_table();
    init_gdt();
    dump_gdt();
    start32(&gp, drive);

    panic("start32 returned");
}
