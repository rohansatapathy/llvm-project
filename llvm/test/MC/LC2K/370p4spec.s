# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: sw 0 1 6
	sw	0	1	6
# CHECK: lw 0 1 23
	lw	0	1	23
# CHECK: lw 0 1 30
	lw	0	1	30
# CHECK: halt
	halt
