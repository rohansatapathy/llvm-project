# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 1 0
	lw	0	1	data1	$1= mem[data1]
# CHECK: halt
	halt

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 9
data1	.fill	12345
