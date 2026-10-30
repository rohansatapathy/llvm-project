# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 1 0
		lw 0 1 count
# CHECK: lw 0 2 0
		lw 0 2 one
# CHECK: add 0 0 3
		add 0 0 3
# CHECK: add 0 2 4
		add 0 2 4
# CHECK: sw 0 3 0
		sw 0 3 num1
# CHECK: sw 0 4 0
		sw 0 4 num2
# CHECK: addi 0 5 2
		addi 0 5 2
# CHECK: beq 5 1 17
loop	beq 5 1 verify
# CHECK: add 3 4 6
		add 3 4 6
# CHECK: add 0 4 3
		add 0 4 3
# CHECK: add 0 6 4
		add 0 6 4
# CHECK: sw 0 6 0
		sw 0 6 result
# CHECK: addi 0 7 20
		addi 0 7 20
# CHECK: add 6 3 8
junk	add 6 3 8
# CHECK: nand 8 4 9
		nand 8 4 9
# CHECK: nor 8 4 10
		nor 8 4 10
# CHECK: add 9 10 11
		add 9 10 11
# CHECK: nand 11 8 12
		nand 11 8 12
# CHECK: add 12 9 13
		add 12 9 13
# CHECK: nor 13 10 14
		nor 13 10 14
# CHECK: addi 7 7 -1
		addi 7 7 -1
# CHECK: beq 7 0 1
		beq 7 0 endj
# CHECK: beq 0 0 -10
		beq 0 0 junk
# CHECK: addi 5 5 1
endj	addi 5 5 1
# CHECK: beq 0 0 -18
		beq 0 0 loop
# CHECK: lw 0 3 0
verify	lw 0 3 result
# CHECK: addi 3 4 -987
		addi 3 4 -987
# CHECK: beq 4 0 2
		beq 4 0 pass
# CHECK: lw 0 3 0
		lw 0 3 fail
# CHECK: halt
		halt
# CHECK: lw 0 3 0
pass	lw 0 3 good
# CHECK: halt
		halt

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
result	.fill 0			OUTPUT
# CHECK: add 0 0 1
count	.fill 17		INPUT
# CHECK: add 0 0 1
one		.fill 1
# CHECK: add 0 0 0
num1	.fill 0
# CHECK: add 0 0 0
num2	.fill 0
# CHECK: <unknown>
fail	.fill -1
# CHECK: add 0 0 7
good	.fill 999
