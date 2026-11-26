# The ELF header flags record the CPU, and llvm-objdump uses them to pick the
# disassembler without --mcpu. eecs470 is 0 so that older objects keep their
# meaning.

# RUN: llvm-mc --arch=lc2k --filetype=obj %s -o %t.default.o
# RUN: llvm-readobj -h %t.default.o | FileCheck %s --check-prefix=EECS470
# RUN: llvm-mc --arch=lc2k --filetype=obj -mcpu=eecs470 %s -o %t.eecs470.o
# RUN: llvm-readobj -h %t.eecs470.o | FileCheck %s --check-prefix=EECS470
# RUN: llvm-mc --arch=lc2k --filetype=obj -mcpu=phobos %s -o %t.phobos.o
# RUN: llvm-readobj -h %t.phobos.o | FileCheck %s --check-prefix=PHOBOS
# RUN: llvm-readelf -h %t.phobos.o | FileCheck %s --check-prefix=PHOBOS-GNU

# EECS470:      Flags [ (0x0)
# EECS470-NEXT: ]

# PHOBOS:      Flags [ (0x1)
# PHOBOS-NEXT:   EF_LC2K_MACH_PHOBOS (0x1)
# PHOBOS-NEXT: ]

# PHOBOS-GNU: Flags: 0x1, phobos

# RUN: llvm-objdump -d %t.eecs470.o | FileCheck %s --check-prefix=DIS-EECS470
# RUN: llvm-objdump -d %t.phobos.o | FileCheck %s --check-prefix=DIS-PHOBOS

# DIS-EECS470:      03 00 20 01 add 1 2 3
# DIS-EECS470-NEXT: 00 00 00 60 halt
# DIS-PHOBOS:       03 00 40 02 add 1 2 3
# DIS-PHOBOS-NEXT:  00 00 00 c0 halt

        add     1 2 3
        halt
