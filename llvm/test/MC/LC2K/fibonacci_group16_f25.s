# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 1 0
		lw 0 1 n		$1 - load n as function input
# CHECK: lw 0 4 0
		lw 0 4 Faddr	$4 - load function address
# CHECK: jalr 4 7
		jalr 4 7		call function
# CHECK: beq 0 0 28
		beq 0 0 end
# CHECK: lw 0 6 0
fib		lw 0 6 pos1		start of fib/ $6: 1
# CHECK: add 5 6 5
		add 5 6 5		increment stackPtr
# CHECK: sw 5 2 0
		sw 5 2 Stack	callee save $2
# CHECK: add 5 6 5
		add 5 6 5		increment stackPtr
# CHECK: sw 5 1 0
		sw 5 1 Stack	callee save $1
# CHECK: add 5 6 5
		add 5 6 5		increment stackPtr
# CHECK: sw 5 7 0
		sw 5 7 Stack	callee save $7
# CHECK: beq 1 0 2
		beq 1 0 base	check n==0
# CHECK: beq 1 6 1
		beq 1 6 base	check n==1
# CHECK: beq 0 0 2
		beq 0 0 recur
# CHECK: add 0 1 3
base	add 0 1 3		put n from $1 into $3
# CHECK: beq 0 0 8
		beq 0 0 clean
# CHECK: lw 0 6 0
recur	lw 0 6 neg1		$6: -1
# CHECK: add 1 6 1
		add 1 6 1		$1: n-1
# CHECK: jalr 4 7
		jalr 4 7
# CHECK: add 0 3 2
		add 0 3 2		$2: return of n-1
# CHECK: lw 0 6 0
		lw 0 6 neg1		$6: -1, maybe take out
# CHECK: add 1 6 1
		add 1 6 1		$1: n-2
# CHECK: jalr 4 7
		jalr 4 7		call fib recursively
# CHECK: add 2 3 3
		add 2 3 3		$3: return of fib(n-1) + return of fib(n-2)
# CHECK: lw 0 6 0
clean	lw 0 6 neg1		$6: -1, maybe take out
# CHECK: lw 5 7 0
		lw 5 7 Stack	callee load $7
# CHECK: add 5 6 5
		add 5 6 5		decrement stackPt
# CHECK: lw 5 1 0
		lw 5 1 Stack	callee load $1
# CHECK: add 5 6 5
		add 5 6 5		decrement stackPtr
# CHECK: lw 5 2 0
		lw 5 2 Stack	callee load $2
# CHECK: add 5 6 5
		add 5 6 5		decrement stackPtr
# CHECK: jalr 7 6
		jalr 7 6
# CHECK: sw 0 3 0
end		sw 0 3 n
# CHECK: halt
		halt

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
Faddr	.fill fib
# CHECK: add 0 0 10
n		.fill 10		INPUT and OUTPUT
# CHECK: <unknown>
neg1	.fill -1
# CHECK: add 0 0 1
pos1	.fill 1
# CHECK: add 0 0 0
Stack	.fill 0
