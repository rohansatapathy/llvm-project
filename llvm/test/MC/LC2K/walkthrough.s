# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 1 0
	lw	0	1	label1		// r1 = mem[label1]
# CHECK: add 1 1 2
	add 1	1	2			// r2 = r1 * 2
# CHECK: lw 0 3 0
	lw	0	3	label2		// r3 = mem[label2]
# CHECK: lw 0 4 0
	lw 	0	4	label3		// r4 = mem[label3]
# CHECK: add 2 3 5
	add	2	3	5			// r5 = r2 + r3
# CHECK: sw 0 5 0
	sw	0	5	label4		// mem[label4] = r5
# CHECK: halt
	halt

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 1
label1 .fill 0x1111
# CHECK: add 0 0 2
label2 .fill 0x2222
# CHECK: add 0 0 3
label3 .fill 0x3333
# CHECK: add 0 0 4
label4 .fill 0x4444
