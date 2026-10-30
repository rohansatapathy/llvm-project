# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 1 0
        lw      0       1       five    load reg1 with 5 (symbolic address)
# CHECK: lw 1 2 3
        lw      1       2       3       load reg2 with -1 (numeric address)
# CHECK: add 1 2 1
start   add     1       2       1       decrement reg1
# CHECK: beq 0 1 2
        beq     0       1       2       goto end of program when reg1==0
# CHECK: beq 0 0 -3
        beq     0       0       start   go back to the beginning of the loop
# CHECK: noop
        noop
# CHECK: halt
done    halt                            end of program

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 5
five    .fill   5
# CHECK: <unknown>
neg1    .fill   -1
# CHECK: add 0 0 0
stAddr  .fill   start                   will contain the address of start (2)
