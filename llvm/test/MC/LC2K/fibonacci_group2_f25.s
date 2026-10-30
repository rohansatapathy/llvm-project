# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 1 0
		lw 0 1 n
# CHECK: lw 0 4 0
		lw 0 4 Faddr	load function address
# CHECK: jalr 4 7
		jalr 4 7 		call function
# CHECK: sw 0 3 0
		sw 0 3 res
# CHECK: halt
end		halt
# CHECK: sw 5 7 0
rec		sw 5 7 Stack
# CHECK: lw 0 6 0
		lw 0 6 one
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: beq 1 0 21
		beq 1 0 base
# CHECK: beq 6 1 20
		beq 6 1 base
# CHECK: sw 5 1 0
		sw 5 1 Stack
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: lw 0 6 0
		lw 0 6 neg1
# CHECK: add 1 6 1
		add 1 6 1
# CHECK: lw 0 4 0
		lw 0 4 Faddr
# CHECK: jalr 4 7
		jalr 4 7
# CHECK: sw 5 3 0
		sw 5 3 Stack
# CHECK: lw 0 6 0
		lw 0 6 one
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: lw 0 6 0
		lw 0 6 neg1
# CHECK: add 1 6 1
		add 1 6 1
# CHECK: lw 0 4 0
		lw 0 4 Faddr
# CHECK: jalr 4 7
		jalr 4 7
# CHECK: lw 0 6 0
		lw 0 6 neg1
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: lw 5 2 0
		lw 5 2 Stack
# CHECK: add 2 3 3
		add 2 3 3
# CHECK: add 6 5 5
		add 6 5 5
# CHECK: lw 5 1 0
		lw 5 1 Stack
# CHECK: beq 0 0 1
		beq 0 0 return
# CHECK: add 0 1 3
base	add 0 1 3
# CHECK: lw 0 6 0
return	lw 0 6 neg1
# CHECK: add 6 5 5
		add 6 5 5
# CHECK: lw 5 7 0
		lw 5 7 Stack
# CHECK: jalr 7 4
		jalr 7 4
# CHECK: beq 0 0 -32
		beq 0 0 end

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
Faddr	.fill rec
# CHECK: add 0 0 0
res		.fill 0			OUTPUT
# CHECK: add 0 0 9
n		.fill 9			INPUT
# CHECK: add 0 0 1
one		.fill 1
# CHECK: <unknown>
neg1	.fill -1
# CHECK: add 0 0 0
Stack	.fill 0
