#!/usr/bin/env python3

import os
import sys


if __name__ == "__main__":
    """
    Usage: partition.py image.bin bootsector.bin [boot16.bin [boot32.bin [kernel.bin]]]
    """
    if len(sys.argv) < 4:
        print("ERROR: no volumes")
        sys.exit(1)
    if len(sys.argv) > 6:
        print("ERROR: max 4 partitions")
        sys.exit(1)

    partition_table = []
    # Skip bootsector.
    for idx, name in enumerate(sys.argv[3:]):
        s = os.stat(name)
        num_blocks = s.st_size // 512
        partition_table.append(num_blocks)

    # https://wiki.osdev.org/Partition_Table
    with open(sys.argv[1], "r+b") as fh:
        lba = 1
        offset = 462
        for idx, partition in enumerate(partition_table):
            offset += idx * 16
            # Bootable.
            fh.seek(offset)
            fh.write(b"\x80")
            # First CHS.
            fh.seek(offset + 0x01)
            fh.write(b"\x00\x00\x00")
            # FAT32 with LBA.
            fh.seek(offset + 0x04)
            fh.write(b"\x0c")
            # Last CHS.
            fh.seek(offset + 0x05)
            fh.write(b"\x00\x00\x00")
            # Starting LBA.
            fh.seek(offset + 0x08)
            fh.write(lba.to_bytes(length=4, byteorder="little"))
            # Total Sectors in partition
            fh.seek(offset + 0x0C)
            fh.write(partition.to_bytes(length=4, byteorder="little"))
            lba += partition
