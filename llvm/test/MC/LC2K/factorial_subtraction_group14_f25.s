# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: addi 0 10 0
		addi 0 10 0		// ans = 0
# CHECK: addi 0 2 12
		addi 0 2 12		// n = 12 (start value)		INPUT
# CHECK: addi 0 12 12
		addi 0 12 12	// constant 12
# CHECK: addi 0 13 7
		addi 0 13 7		// constant 7 (end value)	INPUT
# CHECK: addi 0 6 1
		addi 0 6 1
# CHECK: addi 0 7 0
		addi 0 7 0
# CHECK: addi 0 1 1
mainL	addi 0 1 1		// factorial accumulator = 1
# CHECK: addi 0 3 1
		addi 0 3 1		// increm = 1
# CHECK: addi 0 4 0
		addi 0 4 0		// partial product = 0
# CHECK: addi 0 5 1
		addi 0 5 1		// inner loop counter = 1
# CHECK: addi 2 8 1
outL	addi 2 8 1		// n + 1 for comparison
# CHECK: beq 3 8 10
		beq 3 8 fDone	// if increm == n+1 . factorial done
# CHECK: addi 0 4 0
		addi 0 4 0
# CHECK: addi 0 5 1
		addi 0 5 1
# CHECK: addi 3 9 1
inL		addi 3 9 1		// increm + 1 for comparison
# CHECK: beq 5 9 3
		beq 5 9 endI	// end inner loop if done
# CHECK: add 4 1 4
		add 4 1 4		// multiply using repeated addition
# CHECK: addi 5 5 1
		addi 5 5 1
# CHECK: beq 0 0 -5
		beq 0 0 inL
# CHECK: add 4 0 1
endI	add 4 0 1		// update factorial result
# CHECK: addi 3 3 1
		addi 3 3 1		// increm++
# CHECK: beq 0 0 -12
		beq 0 0 outL
# CHECK: beq 2 12 4
fDone	beq 2 12 aCase	// if n == 12 . add case
# CHECK: nor 1 1 11
		nor 1 1 11		// get -a using two's complement
# CHECK: addi 11 11 1
		addi 11 11 1
# CHECK: add 10 11 10
		add 10 11 10	// ans = ans - a
# CHECK: beq 0 0 1
		beq 0 0 aftU
# CHECK: add 10 1 10
aCase	add 10 1 10		// ans = ans + a (for first factorial)
# CHECK: beq 2 13 2
aftU	beq 2 13 doneA	// stop when n == 7
# CHECK: addi 2 2 -1
		addi 2 2 -1		// n--
# CHECK: beq 0 0 -25
		beq 0 0 mainL	// repeat for next n
# CHECK: sw 0 10 0
doneA	sw 0 10 rOut	// store final result in memory
# CHECK: halt
		halt

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
rOut	.fill 0			OUTPUT
