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
		lw 0 4 Faddr	load function address
# CHECK: jalr 4 7
		jalr 4 7		call function
# CHECK: sw 0 3 0
		sw 0 3 result
# CHECK: halt
		halt
# CHECK: sw 5 7 0
func	sw 5 7 Stack	store return address
# CHECK: lw 0 6 0
		lw 0 6 pos1
# CHECK: add 5 6 5
		add 5 6 5		increment SP
# CHECK: beq 0 2 29
		beq 0 2 equal
# CHECK: beq 1 2 28
		beq 1 2 equal
# CHECK: lw 0 6 0
		lw 0 6 neg1
# CHECK: add 1 6 1
		add 1 6 1		n--
# CHECK: lw 0 6 0
		lw 0 6 pos1
# CHECK: sw 5 1 0
		sw 5 1 Stack	store n-1 onto the Stack
# CHECK: add 5 6 5
		add 5 6 5		increment Stack pointer
# CHECK: sw 5 2 0
		sw 5 2 Stack	store r onto the Stack
# CHECK: add 5 6 5
		add 5 6 5		increment Stack pointer
# CHECK: lw 0 6 0
		lw 0 6 Faddr
# CHECK: jalr 6 7
		jalr 6 7		first recursive call
# CHECK: lw 0 6 0
		lw 0 6 neg1
# CHECK: add 5 6 5
		add 5 6 5		decrement Stack pointer
# CHECK: lw 5 2 0
		lw 5 2 Stack	get r off the Stack
# CHECK: add 5 6 5
		add 5 6 5		decrement Stack pointer
# CHECK: lw 5 1 0
		lw 5 1 Stack	get n - 1 off the Stack
# CHECK: add 2 6 2
		add 2 6 2		r--
# CHECK: lw 0 6 0
		lw 0 6 pos1
# CHECK: sw 5 3 0
		sw 5 3 Stack	store first return value onto the Stack
# CHECK: add 5 6 5
		add 5 6 5		increment Stack pointer
# CHECK: lw 0 6 0
		lw 0 6 Faddr
# CHECK: jalr 6 7
		jalr 6 7		second recursive call
# CHECK: lw 0 6 0
		lw 0 6 neg1
# CHECK: add 5 6 5
		add 5 6 5		decrement Stack pointer
# CHECK: lw 5 6 0
		lw 5 6 Stack	get first return value
# CHECK: add 3 6 3
		add 3 6 3		add both return values
# CHECK: lw 0 6 0
		lw 0 6 neg1
# CHECK: add 5 6 5
		add 5 6 5		decrement Stack pointer
# CHECK: lw 5 7 0
		lw 5 7 Stack	get old return address
# CHECK: jalr 7 6
		jalr 7 6		return
# CHECK: lw 0 3 0
equal	lw 0 3 pos1		return 1
# CHECK: lw 0 6 0
		lw 0 6 neg1
# CHECK: add 5 6 5
		add 5 6 5		decrement Stack pointer
# CHECK: lw 5 7 0
		lw 5 7 Stack	get old return address
# CHECK: jalr 7 6
		jalr 7 6
# CHECK: halt
		halt

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
Faddr	.fill func
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
