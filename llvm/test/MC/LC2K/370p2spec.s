# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in different section than instruction/directive are unresolved 
# until link-time, so fixup should emit 0 for I-type offsets or .fills that 
# reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 1 0
        lw	0	1	five
# CHECK: lw 0 4 0
        lw	0	4	SubAdr
# CHECK: jalr 4 7
start	jalr	4	7
# CHECK: beq 0 1 1
        beq	0	1	done
# CHECK: beq 0 0 -3
        beq	0	0	start
# CHECK: halt
done	halt
# CHECK: lw 0 2 0
subOne	lw	0	2	neg1
# CHECK: add 1 2 3
        add	1	2	3
# CHECK: jalr 7 6
        jalr	7	6

# CHECK: Disassembly of section .data:
# NOTE: Assembler should automatically switch to .data upon first .fill

# NOTE: .fill values in .data section are disassembled as instructions by objdump.
# CHECK: add 0 0 5
five	.fill	5
# CHECK: <unknown>
neg1	.fill	-1
# CHECK: add 0 0 0
SubAdr	.fill	subOne
