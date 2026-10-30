# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 1 0
		lw 0 1 one		; r1=1
# CHECK: lw 0 2 0
		lw 0 2 two		; r2=2
# CHECK: lw 0 3 0
		lw 0 3 limit	; r3=loop counter
# CHECK: lw 0 4 0
		lw 0 4 neg1		; r4=-1
# CHECK: lw 0 6 0
		lw 0 6 l11adr
# CHECK: lw 0 7 0
		lw 0 7 decAdr
# CHECK: lw 0 8 0
		lw 0 8 l2adr
# CHECK: beq 3 2 30
loop	beq 3 2 done	; if counter==0 -> done
# CHECK: beq 1 9 2
storm	beq 1 9 l1		; if r1==r9 -> l1
# CHECK: beq 1 2 2
		beq 1 2 l2		; not taken
# CHECK: beq 0 0 4
l0		beq 0 0 l5		; taken
# CHECK: beq 2 2 4
l1		beq 2 2 l6		; taken
# CHECK: beq 1 2 4
l2		beq 1 2 l7		; not taken
# CHECK: beq 0 0 4
l3		beq 0 0 l8		; taken
# CHECK: beq 2 11 -5
l4		beq 2 11 l0		; if r2 == r11 -> l0
# CHECK: beq 5 5 9
l5		beq 5 5 l15		; taken
# CHECK: jalr 6 5
l6		jalr 6 5		; jump
# CHECK: beq 3 3 4
l7		beq 3 3 l12		; taken
# CHECK: beq 1 2 4
l8		beq 1 2 l13		; not taken
# CHECK: beq 0 1 4
l9		beq 0 1 l14		; not taken
# CHECK: beq 2 2 -4
l10		beq 2 2 l7		; taken
# CHECK: jalr 8 5
l11		jalr 8 5		; jump
# CHECK: beq 0 1 4
l12		beq 0 1 dec		; not taken
# CHECK: beq 1 2 -13
l13		beq 1 2 l1		; backward, not taken
# CHECK: beq 0 0 -11
l14		beq 0 0 l4		; backward, taken
# CHECK: beq 2 1 -12
l15		beq 2 1 l4		; backward, not taken
# CHECK: jalr 7 5
l16		jalr 7 5		; jump
# CHECK: add 3 4 3
dec		add 3 4 3		; r3 = r3 - 1
# CHECK: nand 1 3 9
		nand 1 3 9		; r9 = ~(r1 & r3)
# CHECK: nand 9 9 9
		nand 9 9 9		; r9 = ~r9
# CHECK: nand 2 3 11
		nand 2 3 11		; r11 = ~(r2 & r3)
# CHECK: nand 11 11 11
		nand 11 11 11	; r11 = ~r11
# CHECK: add 9 3 10
		add 9 3 10		; r10 = r9 + r3
# CHECK: add 10 11 10
		add 10 11 10	; r10 = r11 + r10
# CHECK: add 10 11 10
		add 10 11 10	; r10 = r11 + r10
# CHECK: add 10 9 10
		add 10 9 10		; r10 = r9 + r10
# CHECK: sw 3 10 48
		sw 3 10 48		; store r10 for checking
# CHECK: beq 0 0 -31
		beq 0 0 loop	; repeat until counter == 0
# CHECK: halt
done	halt

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
l2adr	.fill l2
# CHECK: add 0 0 0
l11adr	.fill l11
# CHECK: add 0 0 0
decAdr	.fill dec
# CHECK: add 0 0 1
one		.fill 1
# CHECK: add 0 0 2
two		.fill 2
# CHECK: <unknown>
neg1	.fill -1
# CHECK: add 0 0 14
limit	.fill 110		OUTPUT after here until 0x30
