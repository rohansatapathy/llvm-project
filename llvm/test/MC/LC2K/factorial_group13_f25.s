# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 2 0
		lw 0 2 inputN	; R2 = N (loop counter)
# CHECK: lw 0 1 0
		lw 0 1 one		; R1 = result = 1
# CHECK: lw 0 3 0
		lw 0 3 one		; R3 = i = 1
# CHECK: lw 0 4 0
		lw 0 4 neg1		; R4 = -1
# CHECK: beq 2 0 19
main	beq 2 0 done	; if N == 0, halt
# CHECK: add 1 0 6
		add 1 0 6		; R6 = multiplicand = result
# CHECK: add 0 0 7
		add 0 0 7		; R7 = product = 0
# CHECK: add 3 0 5
		add 3 0 5		; R5 = multiplier = i
# CHECK: beq 5 0 3
mult	beq 5 0 mDone	; if multiplier == 0, done
# CHECK: add 7 6 7
		add 7 6 7		; product += multiplicand
# CHECK: add 5 4 5
		add 5 4 5		; multiplier--
# CHECK: beq 0 0 -4
		beq 0 0 mult
# CHECK: add 7 0 1
mDone	add 7 0 1		; result = product
# CHECK: lw 0 5 0
		lw 0 5 limit	; R5 = 5040
# CHECK: beq 1 5 4
		beq 1 5 reset	; if result == 5040, reset
# CHECK: lw 0 5 0
		lw 0 5 one		; R5 = 1
# CHECK: add 3 5 3
		add 3 5 3		; i++
# CHECK: add 2 4 2
		add 2 4 2		; N--
# CHECK: beq 0 0 -15
		beq 0 0 main
# CHECK: add 2 4 2
reset	add 2 4 2		; N--
# CHECK: beq 2 0 3
		beq 2 0 done
# CHECK: lw 0 1 0
		lw 0 1 one		; result = 1
# CHECK: lw 0 3 0
		lw 0 3 one		; i = 1
# CHECK: beq 0 0 -20
		beq 0 0 main
# CHECK: sw 0 1 0
done	sw 0 1 result	; store final result
# CHECK: halt
		halt

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
result	.fill 0			OUTPUT
# CHECK: add 0 0 12
inputN	.fill 60		INPUT
# CHECK: add 0 0 1
one		.fill 1
# CHECK: <unknown>
neg1	.fill -1
# CHECK: nor 12 8 0
limit	.fill 479001600
