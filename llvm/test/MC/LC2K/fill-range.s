# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --full-contents --section=.data - \
# RUN:  | FileCheck %s

# .fill accepts any value that fits in either a signed or an unsigned 32-bit
# integer. Values are emitted little-endian.

# CHECK:      Contents of section .data:
# CHECK-NEXT: 0000 00000000 01000000 ffffffff ffffffff
# CHECK-NEXT: 0010 ffffffff ffffff7f 00000080 00000080
        .fill 0
        .fill 1
        .fill -1
        .fill 4294967295
        .fill 0xFFFFFFFF
        .fill 2147483647
        .fill -2147483648
        .fill 2147483648
