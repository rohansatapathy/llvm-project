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
		jalr 4 7		call function
# CHECK: sw 0 3 0
		sw 0 3 result
# CHECK: halt
		halt
# CHECK: lw 0 6 0
stFib	lw 0 6 pos1		load +1 to r6
# CHECK: sw 5 7 0
		sw 5 7 Stack	push r7 (return addr) to stack
# CHECK: add 5 6 5
		add 5 6 5		SP++ (now points to where N will go)
# CHECK: beq 0 1 28
		beq 0 1 retN	if n == 0 goto retN
# CHECK: beq 6 1 27
		beq 6 1 retN	if n == 1 goto retN
# CHECK: sw 5 1 0
		sw 5 1 Stack	push n (r1) to stack
# CHECK: add 5 6 5
		add 5 6 5		SP++ (now points to one after N)
# CHECK: lw 0 6 0
		lw 0 6 neg1		load -1 to r6
# CHECK: add 1 6 1
		add 1 6 1		r1--
# CHECK: lw 0 4 0
		lw 0 4 Faddr	set up recursive call
# CHECK: jalr 4 7
		jalr 4 7		recursively call Fib, now r3=fib(n-1)
# CHECK: add 0 3 2
		add 0 3 2		r2 = r3
# CHECK: lw 0 6 0
		lw 0 6 neg1		r6 = -1
# CHECK: add 5 6 5
		add 5 6 5		SP-- (now points to show to n)
# CHECK: lw 5 1 0
		lw 5 1 Stack	read n from stack
# CHECK: lw 0 6 0
		lw 0 6 pos1		r6=1
# CHECK: add 5 6 5
		add 5 6 5		SP++ (now back to one after n)
# CHECK: sw 5 2 0
		sw 5 2 Stack	store r2 on the stack
# CHECK: add 5 6 5
		add 5 6 5		SP++ (now back to one after n)
# CHECK: lw 0 6 0
		lw 0 6 neg2		load -2 to r6
# CHECK: add 1 6 1
		add 1 6 1		r1 -= 2
# CHECK: lw 0 4 0
		lw 0 4 Faddr	set up recursive call
# CHECK: jalr 4 7
		jalr 4 7		recursively call Fib, now r3=fib(n-1)
# CHECK: lw 0 6 0
		lw 0 6 neg1		load -1 to r6
# CHECK: add 5 6 5
		add 5 6 5		SP-- (now points to return addr)
# CHECK: lw 5 2 0
		lw 5 2 Stack	pop r2 back from the stack
# CHECK: add 0 3 4
		add 0 3 4		r4 = r3
# CHECK: add 4 2 3
		add 4 2 3		r3 = r4 + r2 (return fib(n-1) + fib(n-2))
# CHECK: lw 0 6 0
		lw 0 6 neg2		load -2 to r6
# CHECK: add 5 6 5
		add 5 6 5		SP -= 2 (now points to return addr)
# CHECK: lw 5 7 0
		lw 5 7 Stack	r1 = return address from stack
# CHECK: jalr 7 4
		jalr 7 4		return
# CHECK: add 1 0 3
retN	add 1 0 3		n is still in r1, r3 = r1
# CHECK: lw 0 6 0
		lw 0 6 neg1		load -1 to r6
# CHECK: add 5 6 5
		add 5 6 5		SP-- (now points to return addr)
# CHECK: lw 5 7 0
		lw 5 7 Stack	r1 = return address from stack
# CHECK: jalr 7 4
		jalr 7 4		return

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
Faddr	.fill stFib
# CHECK: add 0 0 0
result	.fill 0			OUTPUT
# CHECK: add 0 0 12
n		.fill 12		INPUT
# CHECK: add 0 0 1
pos1	.fill 1
# CHECK: add 0 0 2
pos2	.fill 2
# CHECK: <unknown>
neg1	.fill -1
# CHECK: <unknown>
neg2	.fill -2
# CHECK: add 0 0 0
Stack	.fill 0
