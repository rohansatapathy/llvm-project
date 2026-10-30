# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 12 0
		lw 0 12 loopy
# CHECK: beq 0 12 31
beg1	beq 0 12 mend1
# CHECK: addi 12 13 0
		addi 12 13 0
# CHECK: beq 0 13 26
beg		beq 0 13 mend
# CHECK: addi 0 0 0
		addi 0 0 0
# CHECK: addi 0 1 0
		addi 0 1 0
# CHECK: addi 0 2 0
		addi 0 2 0
# CHECK: addi 0 3 0
		addi 0 3 0
# CHECK: addi 0 4 0
		addi 0 4 0
# CHECK: addi 0 5 0
		addi 0 5 0
# CHECK: addi 0 6 0
		addi 0 6 0
# CHECK: addi 0 7 0
		addi 0 7 0
# CHECK: addi 13 1 0
		addi 13 1 0
# CHECK: addi 13 13 -1
		addi 13 13 -1
# CHECK: addi 0 5 0
		addi 0 5 0
# CHECK: lw 0 4 0
		lw 0 4 Faddr
# CHECK: jalr 4 7
		jalr 4 7
# CHECK: sw 0 3 0
		sw 0 3 mplier
# CHECK: addi 0 0 0
		addi 0 0 0
# CHECK: addi 0 1 0
		addi 0 1 0
# CHECK: addi 0 2 0
		addi 0 2 0
# CHECK: addi 0 3 0
		addi 0 3 0
# CHECK: addi 0 4 0
		addi 0 4 0
# CHECK: addi 0 5 0
		addi 0 5 0
# CHECK: addi 0 6 0
		addi 0 6 0
# CHECK: addi 0 7 0
		addi 0 7 0
# CHECK: lw 0 14 0
		lw 0 14 maddr
# CHECK: jalr 14 15
		jalr 14 15
# CHECK: sw 0 3 0
		sw 0 3 mcand
# CHECK: beq 0 0 -27
		beq 0 0 beg
# CHECK: sw 0 3 0
mend	sw 0 3 result
# CHECK: halt
		halt
# CHECK: beq 0 0 -32
		beq 0 0 beg1
# CHECK: halt
mend1	halt
# CHECK: lw 0 4 0
mul		lw 0 4 mcand
# CHECK: lw 0 2 0
		lw 0 2 nloop
# CHECK: lw 0 7 0
		lw 0 7 zero
# CHECK: lw 0 3 0
		lw 0 3 none
# CHECK: beq 0 2 24
begin	beq 0 2 end
# CHECK: add 3 2 2
		add 3 2 2
# CHECK: lw 0 5 0
		lw 0 5 mplier
# CHECK: lw 0 1 0
		lw 0 1 mone
# CHECK: add 0 4 6
		add 0 4 6
# CHECK: nor 6 6 6
		nor 6 6 6
# CHECK: nor 1 1 1
		nor 1 1 1
# CHECK: nor 6 1 6
		nor 6 1 6
# CHECK: lw 0 1 0
		lw 0 1 mone
# CHECK: beq 6 1 7
		beq 6 1 fibadd
# CHECK: add 7 7 7
		add 7 7 7
# CHECK: add 4 4 4
		add 4 4 4
# CHECK: lw 0 6 0
		lw 0 6 pre
# CHECK: nor 6 6 6
		nor 6 6 6
# CHECK: nor 4 4 4
		nor 4 4 4
# CHECK: nor 6 4 4
		nor 6 4 4
# CHECK: beq 0 0 -17
		beq 0 0 begin
# CHECK: add 7 7 7
fibadd	add 7 7 7
# CHECK: add 5 7 7
		add 5 7 7
# CHECK: add 4 4 4
		add 4 4 4
# CHECK: lw 0 6 0
		lw 0 6 pre
# CHECK: nor 6 6 6
		nor 6 6 6
# CHECK: nor 4 4 4
		nor 4 4 4
# CHECK: nor 6 4 4
		nor 6 4 4
# CHECK: beq 0 0 -25
		beq 0 0 begin
# CHECK: add 0 7 3
end		add 0 7 3
# CHECK: jalr 15 14
emem1	jalr 15 14
# CHECK: sw 5 7 0
fib		sw 5 7 Stack
# CHECK: lw 0 2 0
		lw 0 2 one
# CHECK: add 2 5 5
		add 2 5 5
# CHECK: beq 0 1 23
		beq 0 1 exit0
# CHECK: lw 0 2 0
		lw 0 2 one
# CHECK: beq 2 1 23
		beq 2 1 exit1
# CHECK: sw 5 1 0
		sw 5 1 Stack
# CHECK: add 2 5 5
		add 2 5 5
# CHECK: lw 0 4 0
		lw 0 4 negO
# CHECK: add 4 1 1
		add 4 1 1
# CHECK: lw 0 4 0
		lw 0 4 Faddr
# CHECK: jalr 4 7
rec1	jalr 4 7
# CHECK: lw 0 2 0
		lw 0 2 negO
# CHECK: add 5 2 5
		add 5 2 5
# CHECK: lw 5 1 0
		lw 5 1 Stack
# CHECK: sw 5 3 0
		sw 5 3 Stack
# CHECK: lw 0 2 0
		lw 0 2 one
# CHECK: add 2 5 5
		add 2 5 5
# CHECK: lw 0 2 0
		lw 0 2 negT
# CHECK: add 1 2 1
		add 1 2 1
# CHECK: lw 0 4 0
		lw 0 4 Faddr
# CHECK: jalr 4 7
		jalr 4 7
# CHECK: lw 0 2 0
		lw 0 2 negO
# CHECK: add 5 2 5
		add 5 2 5
# CHECK: lw 5 2 0
		lw 5 2 Stack
# CHECK: add 2 3 3
		add 2 3 3
# CHECK: beq 0 0 4
		beq 0 0 exit
# CHECK: lw 0 3 0
exit0	lw 0 3 zero
# CHECK: beq 0 0 2
		beq 0 0 exit
# CHECK: lw 0 3 0
exit1	lw 0 3 one
# CHECK: beq 0 0 0
		beq 0 0 exit
# CHECK: lw 0 2 0
exit	lw 0 2 negO
# CHECK: add 2 5 5
		add 2 5 5
# CHECK: lw 5 4 0
		lw 5 4 Stack
# CHECK: jalr 4 2
		jalr 4 2

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
Faddr	.fill fib
# CHECK: add 0 0 0
maddr	.fill mul
# CHECK: add 0 0 0
result	.fill 0			OUTPUT: the product of the first n fibonacci numbers (except 0).
# CHECK: add 0 0 7
loopy	.fill 7			INPUT
# CHECK: add 0 0 0
zero	.fill 0
# CHECK: add 0 0 1
one		.fill 1
# CHECK: <unknown>
none	.fill -1
# CHECK: add 0 0 0
mone	.fill 16384
# CHECK: add 0 0 15
pre		.fill 32767
# CHECK: add 0 0 15
nloop	.fill 15
# CHECK: add 0 0 1
mcand	.fill 1
# CHECK: add 0 0 11
mplier	.fill 6203
# CHECK: <unknown>
negO	.fill -1
# CHECK: <unknown>
negT	.fill -2
# CHECK: add 0 0 0
Stack	.fill 0
