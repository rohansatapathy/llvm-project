# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 2 0
		lw 0 2 runTot	// running factorial product
# CHECK: lw 0 3 0
		lw 0 3 mulTot	// holds multiplication total
# CHECK: lw 0 4 0
		lw 0 4 mask		// starting mask = 1
# CHECK: lw 0 5 0
		lw 0 5 index	// bit index
# CHECK: lw 0 6 0
		lw 0 6 max		// max bits (31)
# CHECK: lw 0 7 0
		lw 0 7 one		// constant 1
# CHECK: lw 0 1 0
		lw 0 1 in		// load n (input)
# CHECK: addi 0 0 0
		addi 0 0 0		// no-op
# CHECK: beq 1 7 18
factL	beq 1 7 done	// if n == 1 . done
# CHECK: add 1 0 8
		add 1 0 8		// copy n into reg8 (multiplier)
# CHECK: add 2 0 9
		add 2 0 9		// copy running total into reg9 (multiplicand)
# CHECK: lw 0 4 0
		lw 0 4 mask		// reset mask = 1
# CHECK: lw 0 5 0
		lw 0 5 index	// reset index = 0
# CHECK: lw 0 3 0
		lw 0 3 mulTot	// reset mulTot = 0
# CHECK: nand 8 8 8
		nand 8 8 8		// nor the multiplier before multiply
# CHECK: beq 5 6 8
formul	beq 5 6 endmul	// if index == max bits, end multiply
# CHECK: nor 4 4 10
		nor 4 4 10		// invert mask
# CHECK: nor 8 10 10
		nor 8 10 10		// isolate current bit
# CHECK: beq 10 0 1
		beq 10 0 else	// if bit == 1
# CHECK: add 9 3 3
		add 9 3 3		// add multiplicand to total
# CHECK: add 4 4 4
else	add 4 4 4		// shift mask left
# CHECK: add 9 9 9
		add 9 9 9		// shift multiplicand left
# CHECK: addi 5 5 1
		addi 5 5 1		// increment bit index
# CHECK: beq 0 0 -9
		beq 0 0 formul	// jump back to formul loop
# CHECK: add 3 0 2
endmul	add 3 0 2		// save mulTot . runTot
# CHECK: addi 1 1 -1
		addi 1 1 -1		// n = n - 1
# CHECK: beq 0 0 -19
		beq 0 0 factL	// loop for next n
# CHECK: sw 0 3 0
done	sw 0 3 out
# CHECK: halt
		halt

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
out		.fill 0			OUTPUT
# CHECK: add 0 0 12
in		.fill 12		INPUT
# CHECK: add 0 0 1
one		.fill 1
# CHECK: add 0 0 1
runTot	.fill 1
# CHECK: add 0 0 1
mask	.fill 1
# CHECK: add 0 0 0
index	.fill 0
# CHECK: add 0 0 0
max		.fill 32
# CHECK: add 0 0 0
mulTot	.fill 0
