# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# Any text after a fully parsed instruction is a comment, whether or not it
# starts with the comment character.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 3 0
        lw 0 3 limit    ; r3=loop counter
# CHECK: beq 3 2 2
loop    beq 3 2 done    ; if counter==0 -> done
# CHECK: add 3 4 3
        add 3 4 3       ; r3 = r3 - 1 ; second comment
# CHECK: beq 0 0 -3
        beq 0 0 loop    plain trailing text
# CHECK: halt
done    halt            ;

# CHECK: Disassembly of section .data:
# CHECK: add 0 0 14
limit   .fill 110       OUTPUT after here until 0x30
# CHECK: <unknown>
neg1    .fill -1        ; neg1 = -1
