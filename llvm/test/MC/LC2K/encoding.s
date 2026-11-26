# Instruction encodings for each encoding family. eecs470 and phobos share
# the assembly syntax but select different encodings through HwModes (see
# LC2KFeatures.td / LC2KInstrFormats.td).
#
#            31     28 27   24 23   20 19                    4 3       0
#   eecs470  [opcode ] [regA ] [regB ] [ offset (20, I-type)  ] [destReg]
#
#            31   29 28   25 24   21 20                      4 3       0
#   phobos   [opc  ] [regA ] [regB ] [  offset (21, I-type)   ] [destReg]

# RUN: llvm-mc --arch=lc2k --filetype=obj -mcpu=eecs470 %s -o %t.eecs470.o
# RUN: llvm-objdump -d --mcpu=eecs470 %t.eecs470.o \
# RUN:   | FileCheck %s --check-prefix=EECS470
# RUN: llvm-mc --arch=lc2k --filetype=obj -mcpu=phobos %s -o %t.phobos.o
# RUN: llvm-objdump -d --mcpu=phobos %t.phobos.o \
# RUN:   | FileCheck %s --check-prefix=PHOBOS

# The two encodings really are different: decoding a phobos object with the
# eecs470 decoder must not reproduce the source.
# RUN: llvm-objdump -d --mcpu=eecs470 %t.phobos.o \
# RUN:   | FileCheck %s --check-prefix=MISMATCH
# MISMATCH-NOT: add 1 2 3

# Opcodes: eecs470 add=0000 nand=1001 lw=0010 sw=0011 beq=0100 jalr=0101
#                  halt=0110 addi=1000
#          phobos  add=000 nand=001 lw=010 sw=011 beq=100 jalr=101 halt=110
#                  addi=111

# EECS470:      03 00 20 01 add 1 2 3
# PHOBOS:       03 00 40 02 add 1 2 3
        add     1 2 3
# EECS470-NEXT: 03 00 20 91 nand 1 2 3
# PHOBOS-NEXT:  03 00 40 22 nand 1 2 3
        nand    1 2 3
# EECS470-NEXT: 0f 00 e0 0f add 15 14 15
# PHOBOS-NEXT:  0f 00 c0 1f add 15 14 15
        add     15 14 15

# I-type offsets are sign-extended from 20 bits on eecs470 and 21 on phobos.
# EECS470-NEXT: ff ff 2f 21 lw 1 2 -1
# PHOBOS-NEXT:  ff ff 5f 42 lw 1 2 -1
        lw      1 2 -1
# EECS470-NEXT: 05 00 20 31 sw 1 2 5
# PHOBOS-NEXT:  05 00 40 62 sw 1 2 5
        sw      1 2 5
# EECS470-NEXT: fe ff 2f 41 beq 1 2 -2
# PHOBOS-NEXT:  fe ff 5f 82 beq 1 2 -2
        beq     1 2 -2
# EECS470-NEXT: fd ff ef 8f addi 15 14 -3
# PHOBOS-NEXT:  fd ff df ff addi 15 14 -3
        addi    15 14 -3
# EECS470-NEXT: ff ff 07 80 addi 0 0 524287
# PHOBOS-NEXT:  ff ff 07 e0 addi 0 0 524287
        addi    0 0 524287
# EECS470-NEXT: 00 00 08 80 addi 0 0 -524288
# PHOBOS-NEXT:  00 00 18 e0 addi 0 0 -524288
        addi    0 0 -524288

# EECS470-NEXT: 00 00 20 51 jalr 1 2
# PHOBOS-NEXT:  00 00 40 a2 jalr 1 2
        jalr    1 2
# EECS470-NEXT: 00 00 00 60 halt
# PHOBOS-NEXT:  00 00 00 c0 halt
        halt
