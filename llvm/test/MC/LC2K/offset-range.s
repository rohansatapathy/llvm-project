# I-type offsets are signed 20-bit on eecs470 and signed 21-bit on phobos.

# RUN: llvm-mc --arch=lc2k --filetype=obj -mcpu=phobos %s -o %t.o
# RUN: llvm-objdump -d --mcpu=phobos %t.o | FileCheck %s
# RUN: not llvm-mc --arch=lc2k -mcpu=eecs470 %s -o /dev/null 2>&1 \
# RUN:   | FileCheck %s --check-prefix=EECS470 --implicit-check-not=error:

# CHECK:      lw 0 1 1048575
# EECS470:    [[#@LINE+1]]:21: error: value '1048575' too large for 20-bit offset field
        lw      0 1 1048575
# CHECK-NEXT: sw 0 1 -1048576
# EECS470:    [[#@LINE+1]]:21: error: value '-1048576' too large for 20-bit offset field
        sw      0 1 -1048576
# CHECK-NEXT: addi 0 1 524288
# EECS470:    [[#@LINE+1]]:21: error: value '524288' too large for 20-bit offset field
        addi    0 1 524288
# CHECK-NEXT: beq 0 1 -524289
# EECS470:    [[#@LINE+1]]:21: error: value '-524289' too large for 20-bit offset field
        beq     0 1 -524289
