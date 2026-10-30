# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 12 0 0
start	lw 12 0 input1
# CHECK: lw 12 1 0
		lw 12 1 input2
# CHECK: lw 12 2 0
		lw 12 2 modAdr	// Set r2 to mod function address
# CHECK: beq 1 12 8
loop	beq 1 12 done	// if b == 0 then halt
# CHECK: sw 14 1 0
		sw 14 1 Stack	// Store r1 on the Stack (Not storing r0 because we don't care about it anymore)
# CHECK: addi 14 14 1
		addi 14 14 1	// Increment sp
# CHECK: jalr 2 15
		jalr 2 15		// Run a%b
# CHECK: addi 0 1 0
		addi 0 1 0		// Set b = result
# CHECK: addi 14 14 -1
		addi 14 14 -1	// Decrement sp
# CHECK: lw 14 0 0
		lw 14 0 Stack	// Set a=b (pulling the value off the Stack)
# CHECK: noop
		noop
# CHECK: beq 0 0 -9
		beq 0 0 loop	// Loop again
# CHECK: halt
done	halt			// end of program
# CHECK: sw 14 2 0
mod		sw 14 2 Stack	// Store r2 on the Stack
# CHECK: addi 14 14 1
		addi 14 14 1	// Increment sp
# CHECK: sw 14 3 0
		sw 14 3 Stack	// Store r3 on the Stack
# CHECK: addi 14 14 1
		addi 14 14 1	// Increment sp
# CHECK: sw 14 4 0
		sw 14 4 Stack	// Store r4 on the Stack
# CHECK: addi 14 14 1
		addi 14 14 1	// Increment sp
# CHECK: lw 12 4 0
		lw 12 4 mask	// Set r4 to bitmask
# CHECK: nand 4 4 4
		nand 4 4 4		// Set r4 to ~(bitmask)
# CHECK: nand 1 1 2
mloop	nand 1 1 2		// Set r2 to ~b
# CHECK: addi 2 2 1
		addi 2 2 1		// Set r2 to -b
# CHECK: add 0 2 2
		add 0 2 2		// Set r2 to a-b
# CHECK: nand 2 2 3
		nand 2 2 3		// Set r3 to ~(a-b)
# CHECK: nor 3 4 3
		nor 3 4 3		// Set r3 to AND(a-b, bitmask)
# CHECK: beq 3 12 7
		beq 3 12 mcont	// Keep running mod if a >= b
# CHECK: addi 14 14 -1
mend	addi 14 14 -1	// Decrement sp
# CHECK: lw 14 4 0
		lw 14 4 Stack	// Restore r4
# CHECK: addi 14 14 -1
		addi 14 14 -1	// Decrement sp
# CHECK: lw 14 3 0
		lw 14 3 Stack	// Restore r3
# CHECK: addi 14 14 -1
		addi 14 14 -1	// Decrement sp
# CHECK: lw 14 2 0
		lw 14 2 Stack	// Restore r2
# CHECK: jalr 15 11
		jalr 15 11		// Return. Just using 11 as garbage reg
# CHECK: addi 2 0 0
mcont	addi 2 0 0		// Set a = (a-b)
# CHECK: beq 0 0 -15
		beq 0 0 mloop	// Run again

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 5
input1	.fill 40133		INPUT
# CHECK: add 0 0 11
input2	.fill 40267		INPUT
# CHECK: addi 0 0 0
mask	.fill -2147483648
# CHECK: add 0 0 0
modAdr	.fill mod
# CHECK: add 0 0 0
Stack	.fill 0			OUTPUT
