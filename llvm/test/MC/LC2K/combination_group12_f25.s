# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 1 0
		lw 0 1 n		r1 = n
# CHECK: lw 0 2 0
		lw 0 2 r		r2 = r
# CHECK: lw 0 4 0
		lw 0 4 Faddr	load func address
# CHECK: jalr 4 7
		jalr 4 7		call function
# CHECK: sw 0 3 0
		sw 0 3 result	store result
# CHECK: halt
		halt
# CHECK: lw 0 6 0
Comb	lw 0 6 pos1
# CHECK: sw 5 2 0
		sw 5 2 Stack	store r to stack (callee)
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: sw 5 1 0
		sw 5 1 Stack	store n to stack (callee)
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: sw 5 7 0
		sw 5 7 Stack	store n to stack (callee)
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: beq 0 2 23
		beq 0 2 end
# CHECK: beq 1 2 22
		beq 1 2 end
# CHECK: lw 0 6 0
		lw 0 6 neg1		r6 = -1
# CHECK: add 1 6 1
		add 1 6 1		n -= 1
# CHECK: lw 0 4 0
		lw 0 4 Faddr	overwrite r4 with Faddr
# CHECK: jalr 4 7
		jalr 4 7
# CHECK: add 2 6 2
		add 2 6 2		r -= 1
# CHECK: lw 0 6 0
		lw 0 6 pos1
# CHECK: sw 5 3 0
		sw 5 3 Stack	store return value to stack
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: lw 0 4 0
		lw 0 4 Faddr	overwrite r4 with Faddr
# CHECK: jalr 4 7
		jalr 4 7
# CHECK: lw 0 6 0
		lw 0 6 neg1
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: lw 5 6 0
		lw 5 6 Stack	load return value from stack to add
# CHECK: add 3 6 3
		add 3 6 3
# CHECK: lw 0 6 0
		lw 0 6 neg1
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: lw 5 7 0
		lw 5 7 Stack	load return address from stack
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: lw 5 1 0
		lw 5 1 Stack	load n from stack
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: lw 5 2 0
		lw 5 2 Stack	load r from stack
# CHECK: jalr 7 4
		jalr 7 4
# CHECK: lw 0 3 0
end		lw 0 3 pos1		r3 = 1
# CHECK: lw 0 6 0
		lw 0 6 neg1
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: lw 5 7 0
		lw 5 7 Stack	load return address from stack
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: lw 5 1 0
		lw 5 1 Stack	load n from stack
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: lw 5 2 0
		lw 5 2 Stack	load r from stack
# CHECK: jalr 7 4
		jalr 7 4

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
Faddr	.fill Comb
# CHECK: add 0 0 0
result	.fill 0			OUTPUT
# CHECK: add 0 0 8
n		.fill 8			INPUT
# CHECK: add 0 0 4
r		.fill 4			INPUT
# CHECK: add 0 0 1
pos1	.fill 1
# CHECK: <unknown>
neg1	.fill -1
# CHECK: add 0 0 0
Stack	.fill 0
