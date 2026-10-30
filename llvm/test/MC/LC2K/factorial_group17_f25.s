# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 15 0
		lw 0 15 n		load r1 with n (input value)
# CHECK: lw 0 2 0
		lw 0 2 one		load r2 with 1 (constant)
# CHECK: add 15 0 1
fact	add 15 0 1
# CHECK: lw 0 4 0
		lw 0 4 one		load r4 with 1 (result accumulator)
# CHECK: lw 0 5 0
		lw 0 5 zero		load r5 with 0 (constant)
# CHECK: lw 0 8 0
		lw 0 8 mask32	load r8 with 32-bit mask (permanent)
# CHECK: beq 1 5 15
		beq 1 5 done	if n == 0, factorial is 1, done
# CHECK: beq 1 2 14
		beq 1 2 done	if n == 1, factorial is 1, done
# CHECK: beq 1 2 13
loop	beq 1 2 done	if n == 1, we're done
# CHECK: add 5 4 6
		add 5 4 6		r6 = result (copy for multiplication)
# CHECK: add 5 1 7
		add 5 1 7		r7 = n (counter for multiplication)
# CHECK: add 5 5 4
		add 5 5 4		r4 = 0 (reset accumulator)
# CHECK: beq 7 5 6
mLoop	beq 7 5 mDone	if counter == 0, multiplication done
# CHECK: add 4 6 4
		add 4 6 4		r4 = r4 + r6
# CHECK: nand 4 8 9
		nand 4 8 9		r9 = ~(r4 & mask32) use r9 as temp
# CHECK: nand 9 9 4
		nand 9 9 4		r4 = ~r9 = r4 & mask (keep lower 32 bits)
# CHECK: lw 0 3 0
		lw 0 3 neg1		load -1 into r3
# CHECK: add 7 3 7
		add 7 3 7		r7 = r7 - 1
# CHECK: beq 0 0 -7
		beq 0 0 mLoop	repeat multiplication loop
# CHECK: lw 0 3 0
mDone	lw 0 3 neg1		load -1 into r3
# CHECK: add 1 3 1
		add 1 3 1		r1 = n - 1 (decrement n)
# CHECK: beq 0 0 -14
		beq 0 0 loop	repeat factorial loop
# CHECK: lw 0 10 0
done	lw 0 10 resAdr	load result address into r10
# CHECK: add 10 15 10
		add 10 15 10
# CHECK: sw 10 4 0
		sw 10 4 0		store result to memory
# CHECK: addi 15 15 -1
		addi 15 15 -1
# CHECK: beq 15 0 1
		beq 15 0 1
# CHECK: beq 0 0 -26
		beq 0 0 fact
# CHECK: halt
		halt

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 12
n		.fill 12		INPUT
# CHECK: add 0 0 0
zero	.fill 0
# CHECK: add 0 0 1
one		.fill 1
# CHECK: <unknown>
neg1	.fill -1
# CHECK: <unknown>
mask32	.fill -1
# CHECK: add 0 0 0
resAdr	.fill result
# CHECK: add 0 0 0
result	.fill 0			OUTPUT array
