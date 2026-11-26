# phobos widens the ADDI/LW/SW/BEQ offset field to 21 bits, so the assembler
# emits R_LC2K_21 and R_LC2K_21_PCPLUS1REL instead of the 20-bit relocations.
# Check that lld applies them and diagnoses overflow at the 21-bit limits
# (word addresses in [-1048576, 1048575], i.e. byte addresses up to 4194300).

# RUN: llvm-mc -filetype=obj -triple=lc2k -mcpu=phobos %s -o %t.o
# RUN: llvm-readelf -r %t.o | FileCheck %s --check-prefix=RELOCS

# RELOCS: R_LC2K_21              {{.*}} big + 0
# RELOCS: R_LC2K_21_PCPLUS1REL   {{.*}} far + 0

## Both ends of the 21-bit absolute range link.
# RUN: ld.lld %t.o --defsym big=4194300 --defsym far=4194300 -o %t.max
# RUN: llvm-objdump -d %t.max | FileCheck %s --check-prefix=MAX
# RUN: ld.lld %t.o --defsym big=-4194304 --defsym far=4194300 -o %t.min
# RUN: llvm-objdump -d %t.min | FileCheck %s --check-prefix=MIN

# MAX:      addi 0 1 1048575
# MIN:      addi 0 1 -1048576

## One word past either end of the field is an error.
# RUN: not ld.lld %t.o --defsym big=4194304 --defsym far=0 2>&1 | FileCheck %s --check-prefix=ABS --implicit-check-not=error:
# ABS: error: {{.*}}: relocation R_LC2K_21 out of range: 1048576 is not in [-1048576, 1048575]; references 'big'

# RUN: not ld.lld %t.o --defsym big=-4194308 --defsym far=0 2>&1 | FileCheck %s --check-prefix=ABS-NEG --implicit-check-not=error:
# ABS-NEG: error: {{.*}}: relocation R_LC2K_21 out of range: -1048577 is not in [-1048576, 1048575]; references 'big'

## The beq is at byte address 0x110b8 (word 17454), so its offset is
## far/4 - 17455. The last reachable target is word 17455 + 1048575.
# RUN: ld.lld %t.o --defsym big=0 --defsym far=4264120 -o %t.pcmax
# RUN: llvm-objdump -d %t.pcmax | FileCheck %s --check-prefix=PCMAX
# PCMAX: 110b8: {{.*}} beq 0 1 1048575

# RUN: not ld.lld %t.o --defsym big=0 --defsym far=4264124 2>&1 | FileCheck %s --check-prefix=PCREL --implicit-check-not=error:
# PCREL: error: {{.*}}: relocation R_LC2K_21_PCPLUS1REL out of range: 1048576 is not in [-1048576, 1048575]; references 'far'

_start  addi    0 1 big
        beq     0 1 far
        jalr    15 2
