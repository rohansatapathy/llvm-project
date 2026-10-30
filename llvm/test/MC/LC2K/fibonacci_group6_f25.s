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
		lw 0 4 Faddr	//load function address
# CHECK: jalr 4 7
		jalr 4 7 		//call function
# CHECK: sw 0 3 0
		sw 0 3 ans
# CHECK: halt
		halt
# CHECK: sw 5 7 0
fib		sw 5 7 Stack	//save return address
# CHECK: lw 0 2 0
		lw 0 2 one		//load value 1 into reg 2
# CHECK: add 5 2 5
		add 5 2 5		//increment stack pointer
# CHECK: sw 5 1 0
		sw 5 1 Stack	//save current n to stack.
# CHECK: add 5 2 5
		add 5 2 5		//increment stack pointer
# CHECK: beq 1 0 21
		beq 1 0 base	//base case n ==0		//save register 7 on stack first
# CHECK: beq 1 2 20
		beq 1 2 base	//base case n == 1
# CHECK: lw 0 2 0
		lw 0 2 neg1		// load -1 into reg2
# CHECK: add 1 2 1
		add 1 2 1		// decrement n - 1
# CHECK: lw 0 4 0
		lw 0 4 Faddr	// load address fib (n-1)
# CHECK: jalr 4 7
		jalr 4 7 		// call fib(n-1)
# CHECK: lw 0 2 0
		lw 0 2 neg1		//load 1 into reg 2
# CHECK: add 1 2 1
		add 1 2 1		//n-1 = n-2
# CHECK: sw 5 3 0
		sw 5 3 Stack	// push "running sum" into stack (n-1)
# CHECK: lw 0 2 0
		lw 0 2 one		//load one to reg2
# CHECK: add 5 2 5
		add 5 2 5		//increment stack pointer
# CHECK: lw 0 4 0
		lw 0 4 Faddr	// load address fib
# CHECK: jalr 4 7
		jalr 4 7 		// call fib(n-2)
# CHECK: lw 0 2 0
		lw 0 2 neg1		//load 1 into reg2
# CHECK: add 5 2 5
		add 5 2 5		//Stack-- //stack always points one beyond
# CHECK: lw 5 6 0
		lw 5 6 Stack	//load (n-2) reg3?
# CHECK: add 3 6 3
		add 3 6 3
# CHECK: add 5 2 5
		add 5 2 5		//decrement pointer
# CHECK: lw 5 1 0
		lw 5 1 Stack	//loading r1
# CHECK: add 5 2 5
		add 5 2 5		// Stack--
# CHECK: lw 5 7 0
		lw 5 7 Stack	//load return address
# CHECK: jalr 7 4
		jalr 7 4 		// jump back to main
# CHECK: lw 0 2 0
base	lw 0 2 neg1		//load -1 into reg2
# CHECK: add 2 5 5
		add 2 5 5		//decrement stack
# CHECK: add 0 1 3
		add 0 1 3		// reg 1 into 3
# CHECK: lw 5 1 0
		lw 5 1 Stack	//load n back into reg 1
# CHECK: add 2 5 5
		add 2 5 5		// decrement stack again
# CHECK: lw 5 7 0
		lw 5 7 Stack	//load return address
# CHECK: jalr 7 4
		jalr 7 4 		// jump back to function

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
Faddr	.fill fib
# CHECK: add 0 0 0
ans		.fill 0			OUTPUT
# CHECK: add 0 0 9
n		.fill 9			INPUT
# CHECK: add 0 0 1
one		.fill 1
# CHECK: <unknown>
neg1	.fill -1
# CHECK: add 0 0 0
Stack	.fill 0
