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
		jalr 4 7		//call function
# CHECK: sw 0 3 0
		sw 0 3 result
# CHECK: halt
		halt
# CHECK: beq 0 1 27
faddr	beq 0 1 sRBase	//beq if n == 0
# CHECK: sw 5 1 0
		sw 5 1 Stack	//Push X1 to Stack
# CHECK: addi 5 5 1
		addi 5 5 1		// reg5 = reg5 + 1
# CHECK: sw 5 7 0
		sw 5 7 Stack	//Push X7 to Stack
# CHECK: addi 5 5 1
		addi 5 5 1		// reg5 = reg5 + 1
# CHECK: addi 1 1 -1
		addi 1 1 -1		// n = n + -1
# CHECK: lw 0 4 0
		lw 0 4 Faddr	//load function address
# CHECK: jalr 4 7
		jalr 4 7		//call function
# CHECK: addi 5 5 -1
		addi 5 5 -1		// reg5 = reg5 + 1
# CHECK: lw 5 7 0
		lw 5 7 Stack	//Pull X7
# CHECK: addi 5 5 -1
		addi 5 5 -1		// reg5 = reg5 + 1
# CHECK: lw 5 1 0
		lw 5 1 Stack	//Pull X1 from Stack
# CHECK: addi 3 2 0
		addi 3 2 0		//save return to r2 as argument multiplication
# CHECK: sw 5 1 0
		sw 5 1 Stack	//Push X1 to Stack
# CHECK: addi 5 5 1
		addi 5 5 1		// reg5 = reg5 + 1
# CHECK: sw 5 6 0
		sw 5 6 Stack	//Push X6 to Stack
# CHECK: addi 5 5 1
		addi 5 5 1		// reg5 = reg5 + 1
# CHECK: sw 5 7 0
		sw 5 7 Stack	//Push X7 to Stack
# CHECK: addi 5 5 1
		addi 5 5 1		// reg5 = reg5 + 1
# CHECK: lw 0 4 0
		lw 0 4 MULT		//load multiplication f call
# CHECK: jalr 4 7
		jalr 4 7		//call function
# CHECK: addi 5 5 -1
		addi 5 5 -1		// reg5 = reg5 + 1
# CHECK: lw 5 7 0
		lw 5 7 Stack	//Pull X7
# CHECK: addi 5 5 -1
		addi 5 5 -1		// reg5 = reg5 + 1
# CHECK: lw 5 6 0
		lw 5 6 Stack	//Pull X6
# CHECK: addi 5 5 -1
		addi 5 5 -1		// reg5 = reg5 + 1
# CHECK: lw 5 1 0
		lw 5 1 Stack	//Pull X1
# CHECK: jalr 7 4
		jalr 7 4		//Go to whoever called you
# CHECK: addi 0 3 1
sRBase	addi 0 3 1		//Set 3 to one, cus return value
# CHECK: jalr 7 4
		jalr 7 4		//Go to whoever called you
# CHECK: sw 5 7 0
mult	sw 5 7 Stack	//Push X7 to Stack (PC+1)
# CHECK: addi 5 5 1
		addi 5 5 1		// reg5 = reg5 + 1
# CHECK: addi 0 7 0
		addi 0 7 0		//reset the counter so it starts at 0
# CHECK: addi 1 3 0
		addi 1 3 0		//make r1 mcand by placing in r3
# CHECK: addi 2 4 0
		addi 2 4 0		//make r2 mplier by placing in r4
# CHECK: addi 0 1 0
		addi 0 1 0		//reset r1 so it starts at 0
# CHECK: lw 0 2 0
		lw 0 2 mask
# CHECK: lw 0 6 0
mLoop	lw 0 6 loopCt
# CHECK: beq 7 6 9
		beq 7 6 end		//if we have looped through loopCt times
# CHECK: nor 2 2 8
		nor 2 2 8
# CHECK: nor 4 4 6
		nor 4 4 6
# CHECK: nor 8 6 8
		nor 8 6 8
# CHECK: beq 0 8 1
		beq 0 8 iter
# CHECK: add 1 3 1
		add 1 3 1
# CHECK: addi 7 7 1
iter	addi 7 7 1		//increment counter by one
# CHECK: add 2 2 2
		add 2 2 2
# CHECK: add 3 3 3
		add 3 3 3
# CHECK: beq 0 0 -11
		beq 0 0 mLoop
# CHECK: add 1 0 3
end		add 1 0 3
# CHECK: addi 5 5 -1
		addi 5 5 -1		// reg5 = reg5 + 1
# CHECK: lw 5 7 0
		lw 5 7 Stack	//Pull X7
# CHECK: jalr 7 4
		jalr 7 4

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
Faddr	.fill faddr
# CHECK: add 0 0 0
MULT	.fill mult
# CHECK: add 0 0 0
result	.fill 0			OUTPUT
# CHECK: add 0 0 12
n		.fill 12		INPUT
# CHECK: add 0 0 1
mask	.fill 1
# CHECK: add 0 0 15
loopCt	.fill 31
# CHECK: <unknown>
Stack	.fill -1
