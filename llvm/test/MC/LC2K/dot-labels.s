# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# Any dot-prefixed word other than .fill and .globl is a label. That includes
# the compiler's .L private symbols and the names of conditional directives,
# which LC2K doesn't support.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 1 0
        lw 0 1 .Ldata
# CHECK: beq 0 0 1
.LBB0_1 beq 0 0 .if
# CHECK: noop
.else   noop
# CHECK: add 1 1 1
.if     add 1 1 1
# CHECK: beq 0 0 -3
.endif  beq 0 0 .else
# CHECK: halt
.ifdef  halt
.ifeq   noop
.ifge   noop
.ifgt   noop
.ifle   noop
.iflt   noop
.ifne   noop
.ifb    noop
.ifnb   noop
.ifc    noop
.ifeqs  noop
.ifnc   noop
.ifnes  noop
.ifndef noop
.ifnotdef noop
.elseif noop
.IF     noop

# CHECK: Disassembly of section .data:
# CHECK: 39 30 00 00
.Ldata  .fill 12345
