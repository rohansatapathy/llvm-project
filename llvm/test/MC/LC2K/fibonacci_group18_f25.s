# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 1 0
		lw 0 1 input	*output is reg 7* load reg1 with 5 (symbolic address) - note that this instruction is at address 0
# CHECK: lw 0 2 0
		lw 0 2 hpos		load reg2 with 'b01111..
# CHECK: nor 1 2 3
		nor 1 2 3		nor(n, -1) output to reg3, should output 0 if n is negative, 1 if positive
# CHECK: beq 1 4 15
		beq 1 4 done	if n == 0
# CHECK: beq 0 3 14
		beq 0 3 done	if n < 0
# CHECK: lw 0 6 0
		lw 0 6 one		a is reg(5) = 0, b is reg(6) = 1 (do it here to reuse the value)
# CHECK: beq 1 6 1
		beq 1 6 re1		n == 1
# CHECK: beq 0 0 2
		beq 0 0 cont	continue
# CHECK: add 0 6 7
re1		add 0 6 7		set the output (reg 7) to 1
# CHECK: beq 0 0 9
		beq 0 0 done
# CHECK: lw 0 2 0
cont	lw 0 2 neg1		load -1 into reg(2)
# CHECK: add 1 2 1
		add 1 2 1		n = n-1
# CHECK: beq 0 1 5
start	beq 0 1 fin
# CHECK: add 5 6 3
		add 5 6 3		reg(3) = a + b
# CHECK: add 0 6 5
		add 0 6 5		a = b
# CHECK: add 0 3 6
		add 0 3 6		b = a + b
# CHECK: add 1 2 1
		add 1 2 1		n = n - 1
# CHECK: beq 0 0 -6
		beq 0 0 start	go back to the beginning of the loop
# CHECK: add 0 6 7
fin		add 0 6 7		set output to reg(b)
# CHECK: sw 0 7 0
done	sw 0 7 res		store output
# CHECK: halt
		halt			end of program

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
stAddr	.fill start		will contain the address of start (2)
# CHECK: add 0 0 0
res		.fill 0			return OUTPUT
# CHECK: add 0 0 14
input	.fill 46		INPUT
# CHECK: add 0 0 1
one		.fill 1
# CHECK: <unknown>
neg1	.fill -1
# CHECK: <unknown>
neg2	.fill -2
# CHECK: noop
hpos	.fill 2147483647 Contains the highest positive number (011..)
