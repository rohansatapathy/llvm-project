# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 1 0
		lw 0 1 n
# CHECK: lw 0 2 0
		lw 0 2 r
# CHECK: lw 0 4 0
		lw 0 4 Caddr	load combination function address
# CHECK: jalr 4 7
		jalr 4 7		call function
# CHECK: sw 0 3 0
		sw 0 3 result
# CHECK: halt
		halt
# CHECK: beq 1 2 40
Comb	beq 1 2 case1
# CHECK: beq 2 0 39
		beq 2 0 case1
# CHECK: lw 0 6 0
		lw 0 6 negOne
# CHECK: add 1 6 1
		add 1 6 1
# CHECK: lw 0 6 0
		lw 0 6 one
# CHECK: sw 5 1 0
		sw 5 1 Stack
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: sw 5 2 0
		sw 5 2 Stack
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: sw 5 7 0
		sw 5 7 Stack
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: sw 5 4 0
		sw 5 4 Stack
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: jalr 4 7
		jalr 4 7
# CHECK: lw 0 6 0
		lw 0 6 negOne
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: lw 5 4 0
		lw 5 4 Stack
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: lw 5 7 0
		lw 5 7 Stack
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: lw 5 2 0
		lw 5 2 Stack
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: lw 5 1 0
		lw 5 1 Stack
# CHECK: add 2 6 2
		add 2 6 2
# CHECK: lw 0 6 0
		lw 0 6 one
# CHECK: sw 5 3 0
		sw 5 3 Stack
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: sw 5 7 0
		sw 5 7 Stack
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: sw 5 4 0
		sw 5 4 Stack
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: jalr 4 7
		jalr 4 7
# CHECK: lw 0 6 0
		lw 0 6 negOne
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: lw 5 4 0
		lw 5 4 Stack
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: lw 5 7 0
		lw 5 7 Stack
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: lw 5 6 0
		lw 5 6 Stack
# CHECK: add 3 6 3
		add 3 6 3
# CHECK: jalr 7 4
		jalr 7 4
# CHECK: lw 0 3 0
case1	lw 0 3 one
# CHECK: jalr 7 4
		jalr 7 4

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
Caddr	.fill Comb
# CHECK: add 0 0 0
result	.fill 0			OUTPUT
# CHECK: add 0 0 8
n		.fill 8			INPUT
# CHECK: add 0 0 4
r		.fill 4			INPUT
# CHECK: add 0 0 1
one		.fill 1
# CHECK: <unknown>
negOne	.fill -1
# CHECK: add 0 0 0
Stack	.fill 0
