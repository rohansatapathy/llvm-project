# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 1 0
		lw 0 1 n		# r1 = n
# CHECK: lw 0 2 0
		lw 0 2 a		# r2 = a = 0
# CHECK: sw 5 2 0
		sw 5 2 Stack
# CHECK: addi 5 5 1
		addi 5 5 1
# CHECK: lw 0 3 0
		lw 0 3 b		# r3 = b = 1
# CHECK: sw 5 3 0
		sw 5 3 Stack
# CHECK: addi 5 5 1
		addi 5 5 1
# CHECK: lw 0 6 0
		lw 0 6 one		# r6 = 1
# CHECK: beq 0 6 26
		beq 0 6 brMiss
# CHECK: beq 1 0 12
fibLp	beq 1 0 doneA	# if n == 0 return a
# CHECK: beq 1 6 14
		beq 1 6 doneB	# if n == 1 return b
# CHECK: add 2 3 4
		add 2 3 4		# r4 = a + b
# CHECK: beq 0 6 22
		beq 0 6 brMiss
# CHECK: sw 5 4 0
		sw 5 4 Stack
# CHECK: beq 0 6 20
		beq 0 6 brMiss
# CHECK: addi 5 5 1
		addi 5 5 1
# CHECK: beq 0 6 18
		beq 0 6 brMiss
# CHECK: add 0 3 2
		add 0 3 2		# a = b
# CHECK: add 0 4 3
		add 0 4 3		# b = a+b
# CHECK: addi 1 1 -1
		addi 1 1 -1		# n = n - 1
# CHECK: beq 0 6 14
		beq 0 6 brMiss
# CHECK: beq 0 0 -13
		beq 0 0 fibLp	# loop again
# CHECK: add 0 2 7
doneA	add 0 2 7		# r7 = a
# CHECK: beq 0 6 11
		beq 0 6 brMiss
# CHECK: beq 0 0 1
		beq 0 0 done
# CHECK: add 0 3 7
doneB	add 0 3 7		# r7 = b
# CHECK: sw 0 7 0
done	sw 0 7 return
# CHECK: beq 0 6 7
		beq 0 6 brMiss
# CHECK: lw 0 4 0
		lw 0 4 count
# CHECK: beq 0 4 4
loop	beq 0 4 doneBr
# CHECK: addi 4 4 -1
		addi 4 4 -1
# CHECK: nand 4 2 3
		nand 4 2 3
# CHECK: nor 4 4 1
		nor 4 4 1
# CHECK: beq 0 0 -5
		beq 0 0 loop
# CHECK: halt
doneBr	halt
# CHECK: noop
brMiss	noop

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
return	.fill 0			OUTPUT
# CHECK: add 0 0 14
n		.fill 46		INPUT
# CHECK: add 0 0 0
zero	.fill 0
# CHECK: add 0 0 1
one		.fill 1
# CHECK: add 0 0 0
a		.fill 0
# CHECK: add 0 0 1
b		.fill 1
# CHECK: add 0 0 7
count	.fill 327
# CHECK: add 0 0 0
Stack	.fill 0			OUTPUT
