# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: addi 0 7 0
		addi 0 7 Stack	// Set up stack pointer
# CHECK: addi 0 1 8
		addi 0 1 8		// Set up first argument (n = 9)	INPUT
# CHECK: addi 0 2 4
		addi 0 2 4		// Set up second argument (k = 5)	INPUT
# CHECK: addi 0 5 0
		addi 0 5 Comb	// Store address of function
# CHECK: jalr 5 6
		jalr 5 6		// Call
# CHECK: sw 0 3 0
		sw 0 3 result
# CHECK: halt
		halt
# CHECK: beq 2 0 22
Comb	beq 2 0 base
# CHECK: beq 2 1 21
		beq 2 1 base
# CHECK: sw 7 1 1
		sw 7 1 1		// Push n onto stack
# CHECK: sw 7 2 2
		sw 7 2 2		// Push k onto stack
# CHECK: sw 7 6 3
		sw 7 6 3		// Push ret addr onto stack
# CHECK: addi 1 1 -1
		addi 1 1 -1		// Prep args for 1st recursive call
# CHECK: addi 7 7 3
		addi 7 7 3		// Prep sp for 1st recursive call
# CHECK: addi 0 5 0
		addi 0 5 Comb	// Store address of function
# CHECK: jalr 5 6
		jalr 5 6		// First recursive call
# CHECK: addi 7 7 -3
		addi 7 7 -3
# CHECK: sw 7 3 4
		sw 7 3 4		// Store call result to stack
# CHECK: lw 7 1 1
		lw 7 1 1		// Prep args of 2nd recursive call
# CHECK: addi 1 1 -1
		addi 1 1 -1
# CHECK: lw 7 2 2
		lw 7 2 2
# CHECK: addi 2 2 -1
		addi 2 2 -1
# CHECK: addi 7 7 4
		addi 7 7 4		// Prep sp for 2nd recursive call
# CHECK: addi 0 5 0
		addi 0 5 Comb	// Store address of function
# CHECK: jalr 5 6
		jalr 5 6		// Second recursive call
# CHECK: addi 7 7 -4
		addi 7 7 -4
# CHECK: lw 7 5 4
		lw 7 5 4
# CHECK: add 3 5 3
		add 3 5 3		// Calculate return value
# CHECK: lw 7 6 3
		lw 7 6 3		// Pop return address off of stack
# CHECK: jalr 6 5
		jalr 6 5		// Return
# CHECK: addi 0 3 1
base	addi 0 3 1		// Calculate return value
# CHECK: jalr 6 5
		jalr 6 5		// Return

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
result	.fill 0			OUTPUT
# CHECK: add 0 0 0
Stack	.fill 0
