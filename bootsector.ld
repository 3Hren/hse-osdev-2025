ENTRY(_start);

SECTIONS {
    . = 0x7c00;

    .text : {
        *(.text)
    }

    .rodata : {
        *(.rodata)
    }

    .data : {
        *(.data)
    }

    . = 0x7c00 + 446;
    _partition_table = .;
    .partition_table : {
        /* partition table entry 0 */
        QUAD(0)
        QUAD(0)
        /* partition table entry 1 */
        QUAD(0)
        QUAD(0)
        /* partition table entry 2 */
        QUAD(0)
        QUAD(0)
        /* partition table entry 3 */
        QUAD(0)
        QUAD(0)
    }

    . = 0x7c00 + 510;

    .signature : {
        SHORT(0xaa55);
    }

    _boot16 = .;
}
