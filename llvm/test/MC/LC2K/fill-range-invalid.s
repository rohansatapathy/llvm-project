# RUN: not llvm-mc --arch=lc2k --filetype=obj %s -o /dev/null 2>&1 \
# RUN:  | FileCheck %s

# .fill rejects values that fit in neither a signed nor an unsigned 32-bit
# integer.

# CHECK: [[@LINE+1]]:15: error: .fill value '4294967296' does not fit in a 32-bit integer
        .fill 4294967296
# CHECK: [[@LINE+1]]:15: error: .fill value '4294967296' does not fit in a 32-bit integer
        .fill 0x100000000
# CHECK: [[@LINE+1]]:15: error: .fill value '-2147483649' does not fit in a 32-bit integer
        .fill -2147483649
# CHECK: [[@LINE+1]]:15: error: .fill value '-4294967295' does not fit in a 32-bit integer
        .fill -0xFFFFFFFF
