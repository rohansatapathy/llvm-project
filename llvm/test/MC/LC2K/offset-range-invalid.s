# Offsets one past the signed 21-bit range are rejected on phobos.

# RUN: not llvm-mc --arch=lc2k -mcpu=phobos %s -o /dev/null 2>&1 \
# RUN:   | FileCheck %s --implicit-check-not=error:

# CHECK: [[#@LINE+1]]:21: error: value '1048576' too large for 21-bit offset field
        lw      0 1 1048576
# CHECK: [[#@LINE+1]]:21: error: value '-1048577' too large for 21-bit offset field
        addi    0 1 -1048577
