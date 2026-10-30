# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 1 0
		lw 0 1 num
# CHECK: lw 0 2 0
		lw 0 2 two
# CHECK: lw 0 3 0
		lw 0 3 three
# CHECK: lw 0 4 0
		lw 0 4 four
# CHECK: lw 0 5 0
		lw 0 5 five
# CHECK: lw 0 6 0
		lw 0 6 six
# CHECK: lw 0 7 0
		lw 0 7 seven
# CHECK: lw 0 8 0
		lw 0 8 eight
# CHECK: lw 0 9 0
		lw 0 9 nine
# CHECK: lw 0 10 0
		lw 0 10 one
# CHECK: lw 0 11 0
		lw 0 11 two
# CHECK: lw 0 12 0
		lw 0 12 three
# CHECK: lw 0 13 0
		lw 0 13 four
# CHECK: lw 0 14 0
		lw 0 14 five
# CHECK: lw 0 15 0
		lw 0 15 six
# CHECK: nand 1 1 1
		nand 1 1 1
# CHECK: addi 1 1 1
start	addi 1 1 1
# CHECK: beq 0 1 574
		beq 0 1 done
# CHECK: addi 3 3 1
		addi 3 3 1
# CHECK: addi 3 3 -1
		addi 3 3 -1
# CHECK: add 3 4 3
		add 3 4 3
# CHECK: add 4 3 4
		add 4 3 4
# CHECK: nor 3 4 3
		nor 3 4 3
# CHECK: nor 4 3 4
		nor 4 3 4
# CHECK: nand 3 4 3
		nand 3 4 3
# CHECK: nand 4 3 4
		nand 4 3 4
# CHECK: lw 0 3 0
		lw 0 3 two
# CHECK: sw 0 3 0
		sw 0 3 three
# CHECK: addi 3 4 1
		addi 3 4 1
# CHECK: add 4 3 5
		add 4 3 5
# CHECK: nor 5 4 6
		nor 5 4 6
# CHECK: nand 6 5 7
		nand 6 5 7
# CHECK: lw 0 4 0
		lw 0 4 four
# CHECK: add 3 4 5
		add 3 4 5
# CHECK: lw 0 5 0
		lw 0 5 six
# CHECK: nor 3 5 6
		nor 3 5 6
# CHECK: lw 0 6 0
		lw 0 6 seven
# CHECK: nand 3 6 7
		nand 3 6 7
# CHECK: sw 0 5 0
		sw 0 5 eight
# CHECK: sw 0 6 0
		sw 0 6 nine
# CHECK: sw 0 4 0
		sw 0 4 num
# CHECK: addi 4 4 1
		addi 4 4 1
# CHECK: addi 4 4 -1
		addi 4 4 -1
# CHECK: add 4 5 4
		add 4 5 4
# CHECK: add 5 4 5
		add 5 4 5
# CHECK: nor 4 5 4
		nor 4 5 4
# CHECK: nor 5 4 5
		nor 5 4 5
# CHECK: nand 4 5 4
		nand 4 5 4
# CHECK: nand 5 4 5
		nand 5 4 5
# CHECK: lw 0 4 0
		lw 0 4 one
# CHECK: sw 0 4 0
		sw 0 4 five
# CHECK: addi 4 5 1
		addi 4 5 1
# CHECK: add 5 4 6
		add 5 4 6
# CHECK: nor 6 5 7
		nor 6 5 7
# CHECK: nand 7 6 8
		nand 7 6 8
# CHECK: lw 0 5 0
		lw 0 5 one
# CHECK: add 4 5 6
		add 4 5 6
# CHECK: lw 0 6 0
		lw 0 6 two
# CHECK: nor 4 6 7
		nor 4 6 7
# CHECK: lw 0 7 0
		lw 0 7 three
# CHECK: nand 4 7 8
		nand 4 7 8
# CHECK: sw 0 6 0
		sw 0 6 four
# CHECK: sw 0 7 0
		sw 0 7 six
# CHECK: sw 0 5 0
		sw 0 5 seven
# CHECK: addi 5 5 1
		addi 5 5 1
# CHECK: addi 5 5 -1
		addi 5 5 -1
# CHECK: add 5 6 5
		add 5 6 5
# CHECK: add 6 5 6
		add 6 5 6
# CHECK: nor 5 6 5
		nor 5 6 5
# CHECK: nor 6 5 6
		nor 6 5 6
# CHECK: nand 5 6 5
		nand 5 6 5
# CHECK: nand 6 5 6
		nand 6 5 6
# CHECK: lw 0 5 0
		lw 0 5 eight
# CHECK: sw 0 5 0
		sw 0 5 nine
# CHECK: addi 5 6 1
		addi 5 6 1
# CHECK: add 6 5 7
		add 6 5 7
# CHECK: nor 7 6 8
		nor 7 6 8
# CHECK: nand 8 7 9
		nand 8 7 9
# CHECK: lw 0 6 0
		lw 0 6 num
# CHECK: add 5 6 7
		add 5 6 7
# CHECK: lw 0 7 0
		lw 0 7 one
# CHECK: nor 5 7 8
		nor 5 7 8
# CHECK: lw 0 8 0
		lw 0 8 five
# CHECK: nand 5 8 9
		nand 5 8 9
# CHECK: sw 0 7 0
		sw 0 7 one
# CHECK: sw 0 8 0
		sw 0 8 two
# CHECK: sw 0 6 0
		sw 0 6 three
# CHECK: addi 6 6 1
		addi 6 6 1
# CHECK: addi 6 6 -1
		addi 6 6 -1
# CHECK: add 6 7 6
		add 6 7 6
# CHECK: add 7 6 7
		add 7 6 7
# CHECK: nor 6 7 6
		nor 6 7 6
# CHECK: nor 7 6 7
		nor 7 6 7
# CHECK: nand 6 7 6
		nand 6 7 6
# CHECK: nand 7 6 7
		nand 7 6 7
# CHECK: lw 0 6 0
		lw 0 6 four
# CHECK: sw 0 6 0
		sw 0 6 six
# CHECK: addi 6 7 1
		addi 6 7 1
# CHECK: add 7 6 8
		add 7 6 8
# CHECK: nor 8 7 9
		nor 8 7 9
# CHECK: nand 9 8 10
		nand 9 8 10
# CHECK: lw 0 7 0
		lw 0 7 seven
# CHECK: add 6 7 8
		add 6 7 8
# CHECK: lw 0 8 0
		lw 0 8 eight
# CHECK: nor 6 8 9
		nor 6 8 9
# CHECK: lw 0 9 0
		lw 0 9 nine
# CHECK: nand 6 9 10
		nand 6 9 10
# CHECK: sw 0 8 0
		sw 0 8 num
# CHECK: sw 0 9 0
		sw 0 9 one
# CHECK: sw 0 7 0
		sw 0 7 five
# CHECK: addi 7 7 1
		addi 7 7 1
# CHECK: addi 7 7 -1
		addi 7 7 -1
# CHECK: add 7 8 7
		add 7 8 7
# CHECK: add 8 7 8
		add 8 7 8
# CHECK: nor 7 8 7
		nor 7 8 7
# CHECK: nor 8 7 8
		nor 8 7 8
# CHECK: nand 7 8 7
		nand 7 8 7
# CHECK: nand 8 7 8
		nand 8 7 8
# CHECK: lw 0 7 0
		lw 0 7 one
# CHECK: sw 0 7 0
		sw 0 7 two
# CHECK: addi 7 8 1
		addi 7 8 1
# CHECK: add 8 7 9
		add 8 7 9
# CHECK: nor 9 8 10
		nor 9 8 10
# CHECK: nand 10 9 11
		nand 10 9 11
# CHECK: lw 0 8 0
		lw 0 8 three
# CHECK: add 7 8 9
		add 7 8 9
# CHECK: lw 0 9 0
		lw 0 9 four
# CHECK: nor 7 9 10
		nor 7 9 10
# CHECK: lw 0 10 0
		lw 0 10 six
# CHECK: nand 7 10 11
		nand 7 10 11
# CHECK: sw 0 9 0
		sw 0 9 seven
# CHECK: sw 0 10 0
		sw 0 10 eight
# CHECK: sw 0 8 0
		sw 0 8 nine
# CHECK: addi 8 8 1
		addi 8 8 1
# CHECK: addi 8 8 -1
		addi 8 8 -1
# CHECK: add 8 9 8
		add 8 9 8
# CHECK: add 9 8 9
		add 9 8 9
# CHECK: nor 8 9 8
		nor 8 9 8
# CHECK: nor 9 8 9
		nor 9 8 9
# CHECK: nand 8 9 8
		nand 8 9 8
# CHECK: nand 9 8 9
		nand 9 8 9
# CHECK: lw 0 8 0
		lw 0 8 num
# CHECK: sw 0 8 0
		sw 0 8 one
# CHECK: addi 8 9 1
		addi 8 9 1
# CHECK: add 9 8 10
		add 9 8 10
# CHECK: nor 10 9 11
		nor 10 9 11
# CHECK: nand 11 10 12
		nand 11 10 12
# CHECK: lw 0 9 0
		lw 0 9 five
# CHECK: add 8 9 10
		add 8 9 10
# CHECK: lw 0 10 0
		lw 0 10 one
# CHECK: nor 8 10 11
		nor 8 10 11
# CHECK: lw 0 11 0
		lw 0 11 two
# CHECK: nand 8 11 12
		nand 8 11 12
# CHECK: sw 0 10 0
		sw 0 10 three
# CHECK: sw 0 11 0
		sw 0 11 four
# CHECK: sw 0 9 0
		sw 0 9 six
# CHECK: addi 9 9 1
		addi 9 9 1
# CHECK: addi 9 9 -1
		addi 9 9 -1
# CHECK: add 9 10 9
		add 9 10 9
# CHECK: add 10 9 10
		add 10 9 10
# CHECK: nor 9 10 9
		nor 9 10 9
# CHECK: nor 10 9 10
		nor 10 9 10
# CHECK: nand 9 10 9
		nand 9 10 9
# CHECK: nand 10 9 10
		nand 10 9 10
# CHECK: lw 0 9 0
		lw 0 9 seven
# CHECK: sw 0 9 0
		sw 0 9 eight
# CHECK: addi 9 10 1
		addi 9 10 1
# CHECK: add 10 9 11
		add 10 9 11
# CHECK: nor 11 10 12
		nor 11 10 12
# CHECK: nand 12 11 13
		nand 12 11 13
# CHECK: lw 0 10 0
		lw 0 10 nine
# CHECK: add 9 10 11
		add 9 10 11
# CHECK: lw 0 11 0
		lw 0 11 num
# CHECK: nor 9 11 12
		nor 9 11 12
# CHECK: lw 0 12 0
		lw 0 12 one
# CHECK: nand 9 12 13
		nand 9 12 13
# CHECK: sw 0 11 0
		sw 0 11 five
# CHECK: sw 0 12 0
		sw 0 12 one
# CHECK: sw 0 10 0
		sw 0 10 two
# CHECK: addi 3 4 1
		addi 3 4 1
# CHECK: add 4 3 5
		add 4 3 5
# CHECK: addi 5 5 -1
		addi 5 5 -1
# CHECK: nor 5 4 6
		nor 5 4 6
# CHECK: addi 6 6 -1
		addi 6 6 -1
# CHECK: nand 6 5 7
		nand 6 5 7
# CHECK: lw 0 3 0
		lw 0 3 three
# CHECK: add 3 5 6
		add 3 5 6
# CHECK: lw 0 4 0
		lw 0 4 four
# CHECK: nor 4 6 7
		nor 4 6 7
# CHECK: lw 0 5 0
		lw 0 5 six
# CHECK: nand 5 7 8
		nand 5 7 8
# CHECK: sw 0 3 0
		sw 0 3 seven
# CHECK: sw 0 4 0
		sw 0 4 eight
# CHECK: sw 0 5 0
		sw 0 5 nine
# CHECK: addi 4 5 1
		addi 4 5 1
# CHECK: add 5 4 6
		add 5 4 6
# CHECK: addi 6 6 -1
		addi 6 6 -1
# CHECK: nor 6 5 7
		nor 6 5 7
# CHECK: addi 7 7 -1
		addi 7 7 -1
# CHECK: nand 7 6 8
		nand 7 6 8
# CHECK: lw 0 4 0
		lw 0 4 num
# CHECK: add 4 6 7
		add 4 6 7
# CHECK: lw 0 5 0
		lw 0 5 one
# CHECK: nor 5 7 8
		nor 5 7 8
# CHECK: lw 0 6 0
		lw 0 6 five
# CHECK: nand 6 8 9
		nand 6 8 9
# CHECK: sw 0 4 0
		sw 0 4 one
# CHECK: sw 0 5 0
		sw 0 5 two
# CHECK: sw 0 6 0
		sw 0 6 three
# CHECK: addi 5 6 1
		addi 5 6 1
# CHECK: add 6 5 7
		add 6 5 7
# CHECK: addi 7 7 -1
		addi 7 7 -1
# CHECK: nor 7 6 8
		nor 7 6 8
# CHECK: addi 8 8 -1
		addi 8 8 -1
# CHECK: nand 8 7 9
		nand 8 7 9
# CHECK: lw 0 5 0
		lw 0 5 four
# CHECK: add 5 7 8
		add 5 7 8
# CHECK: lw 0 6 0
		lw 0 6 six
# CHECK: nor 6 8 9
		nor 6 8 9
# CHECK: lw 0 7 0
		lw 0 7 seven
# CHECK: nand 7 9 10
		nand 7 9 10
# CHECK: sw 0 5 0
		sw 0 5 eight
# CHECK: sw 0 6 0
		sw 0 6 nine
# CHECK: sw 0 7 0
		sw 0 7 num
# CHECK: addi 6 7 1
		addi 6 7 1
# CHECK: add 7 6 8
		add 7 6 8
# CHECK: addi 8 8 -1
		addi 8 8 -1
# CHECK: nor 8 7 9
		nor 8 7 9
# CHECK: addi 9 9 -1
		addi 9 9 -1
# CHECK: nand 9 8 10
		nand 9 8 10
# CHECK: lw 0 6 0
		lw 0 6 one
# CHECK: add 6 8 9
		add 6 8 9
# CHECK: lw 0 7 0
		lw 0 7 five
# CHECK: nor 7 9 10
		nor 7 9 10
# CHECK: lw 0 8 0
		lw 0 8 one
# CHECK: nand 8 10 11
		nand 8 10 11
# CHECK: sw 0 6 0
		sw 0 6 two
# CHECK: sw 0 7 0
		sw 0 7 three
# CHECK: sw 0 8 0
		sw 0 8 four
# CHECK: addi 7 8 1
		addi 7 8 1
# CHECK: add 8 7 9
		add 8 7 9
# CHECK: addi 9 9 -1
		addi 9 9 -1
# CHECK: nor 9 8 10
		nor 9 8 10
# CHECK: addi 10 10 -1
		addi 10 10 -1
# CHECK: nand 10 9 11
		nand 10 9 11
# CHECK: lw 0 7 0
		lw 0 7 six
# CHECK: add 7 9 10
		add 7 9 10
# CHECK: lw 0 8 0
		lw 0 8 seven
# CHECK: nor 8 10 11
		nor 8 10 11
# CHECK: lw 0 9 0
		lw 0 9 eight
# CHECK: nand 9 11 12
		nand 9 11 12
# CHECK: sw 0 7 0
		sw 0 7 nine
# CHECK: sw 0 8 0
		sw 0 8 num
# CHECK: sw 0 9 0
		sw 0 9 one
# CHECK: addi 8 9 1
		addi 8 9 1
# CHECK: add 9 8 10
		add 9 8 10
# CHECK: addi 10 10 -1
		addi 10 10 -1
# CHECK: nor 10 9 11
		nor 10 9 11
# CHECK: addi 11 11 -1
		addi 11 11 -1
# CHECK: nand 11 10 12
		nand 11 10 12
# CHECK: lw 0 8 0
		lw 0 8 five
# CHECK: add 8 10 11
		add 8 10 11
# CHECK: lw 0 9 0
		lw 0 9 one
# CHECK: nor 9 11 12
		nor 9 11 12
# CHECK: lw 0 10 0
		lw 0 10 two
# CHECK: nand 10 12 13
		nand 10 12 13
# CHECK: sw 0 8 0
		sw 0 8 three
# CHECK: sw 0 9 0
		sw 0 9 four
# CHECK: sw 0 10 0
		sw 0 10 six
# CHECK: addi 9 10 1
		addi 9 10 1
# CHECK: add 10 9 11
		add 10 9 11
# CHECK: addi 11 11 -1
		addi 11 11 -1
# CHECK: nor 11 10 12
		nor 11 10 12
# CHECK: addi 12 12 -1
		addi 12 12 -1
# CHECK: nand 12 11 13
		nand 12 11 13
# CHECK: lw 0 9 0
		lw 0 9 seven
# CHECK: add 9 11 12
		add 9 11 12
# CHECK: lw 0 10 0
		lw 0 10 eight
# CHECK: nor 10 12 13
		nor 10 12 13
# CHECK: lw 0 11 0
		lw 0 11 nine
# CHECK: nand 11 13 14
		nand 11 13 14
# CHECK: sw 0 9 0
		sw 0 9 num
# CHECK: sw 0 10 0
		sw 0 10 one
# CHECK: sw 0 11 0
		sw 0 11 five
# CHECK: addi 10 11 1
		addi 10 11 1
# CHECK: add 11 10 12
		add 11 10 12
# CHECK: addi 12 12 -1
		addi 12 12 -1
# CHECK: nor 12 11 13
		nor 12 11 13
# CHECK: addi 13 13 -1
		addi 13 13 -1
# CHECK: nand 13 12 14
		nand 13 12 14
# CHECK: lw 0 10 0
		lw 0 10 one
# CHECK: add 10 12 13
		add 10 12 13
# CHECK: lw 0 11 0
		lw 0 11 two
# CHECK: nor 11 13 14
		nor 11 13 14
# CHECK: lw 0 12 0
		lw 0 12 three
# CHECK: nand 12 14 15
		nand 12 14 15
# CHECK: sw 0 10 0
		sw 0 10 four
# CHECK: sw 0 11 0
		sw 0 11 six
# CHECK: sw 0 12 0
		sw 0 12 seven
# CHECK: addi 11 12 1
		addi 11 12 1
# CHECK: add 12 11 13
		add 12 11 13
# CHECK: addi 13 13 -1
		addi 13 13 -1
# CHECK: nor 13 12 14
		nor 13 12 14
# CHECK: addi 14 14 -1
		addi 14 14 -1
# CHECK: nand 14 13 15
		nand 14 13 15
# CHECK: lw 0 11 0
		lw 0 11 eight
# CHECK: add 11 13 14
		add 11 13 14
# CHECK: lw 0 12 0
		lw 0 12 nine
# CHECK: nor 12 14 15
		nor 12 14 15
# CHECK: lw 0 13 0
		lw 0 13 num
# CHECK: nand 13 15 15
		nand 13 15 15
# CHECK: sw 0 11 0
		sw 0 11 one
# CHECK: sw 0 12 0
		sw 0 12 five
# CHECK: sw 0 13 0
		sw 0 13 one
# CHECK: addi 12 13 1
		addi 12 13 1
# CHECK: add 13 12 14
		add 13 12 14
# CHECK: addi 14 14 -1
		addi 14 14 -1
# CHECK: nor 14 13 15
		nor 14 13 15
# CHECK: addi 15 15 -1
		addi 15 15 -1
# CHECK: nand 15 14 15
		nand 15 14 15
# CHECK: lw 0 12 0
		lw 0 12 two
# CHECK: add 12 14 15
		add 12 14 15
# CHECK: lw 0 13 0
		lw 0 13 three
# CHECK: nor 13 15 15
		nor 13 15 15
# CHECK: lw 0 14 0
		lw 0 14 four
# CHECK: nand 14 15 3
		nand 14 15 3
# CHECK: sw 0 12 0
		sw 0 12 six
# CHECK: sw 0 13 0
		sw 0 13 seven
# CHECK: sw 0 14 0
		sw 0 14 eight
# CHECK: addi 13 14 1
		addi 13 14 1
# CHECK: add 14 13 15
		add 14 13 15
# CHECK: addi 15 15 -1
		addi 15 15 -1
# CHECK: nor 15 14 15
		nor 15 14 15
# CHECK: addi 15 15 -1
		addi 15 15 -1
# CHECK: nand 15 15 3
		nand 15 15 3
# CHECK: lw 0 13 0
		lw 0 13 nine
# CHECK: add 13 15 15
		add 13 15 15
# CHECK: lw 0 14 0
		lw 0 14 num
# CHECK: nor 14 15 3
		nor 14 15 3
# CHECK: lw 0 15 0
		lw 0 15 one
# CHECK: nand 15 3 4
		nand 15 3 4
# CHECK: sw 0 13 0
		sw 0 13 five
# CHECK: sw 0 14 0
		sw 0 14 one
# CHECK: sw 0 15 0
		sw 0 15 two
# CHECK: addi 14 15 1
		addi 14 15 1
# CHECK: add 15 14 15
		add 15 14 15
# CHECK: addi 15 15 -1
		addi 15 15 -1
# CHECK: nor 15 15 3
		nor 15 15 3
# CHECK: addi 3 3 -1
		addi 3 3 -1
# CHECK: nand 3 15 4
		nand 3 15 4
# CHECK: lw 0 14 0
		lw 0 14 three
# CHECK: add 14 15 3
		add 14 15 3
# CHECK: lw 0 15 0
		lw 0 15 four
# CHECK: nor 15 3 4
		nor 15 3 4
# CHECK: lw 0 15 0
		lw 0 15 six
# CHECK: nand 15 4 5
		nand 15 4 5
# CHECK: sw 0 14 0
		sw 0 14 seven
# CHECK: sw 0 15 0
		sw 0 15 eight
# CHECK: sw 0 15 0
		sw 0 15 nine
# CHECK: addi 15 15 1
		addi 15 15 1
# CHECK: add 15 15 3
		add 15 15 3
# CHECK: addi 3 3 -1
		addi 3 3 -1
# CHECK: nor 3 15 4
		nor 3 15 4
# CHECK: addi 4 4 -1
		addi 4 4 -1
# CHECK: nand 4 3 5
		nand 4 3 5
# CHECK: lw 0 15 0
		lw 0 15 num
# CHECK: add 15 3 4
		add 15 3 4
# CHECK: lw 0 15 0
		lw 0 15 one
# CHECK: nor 15 4 5
		nor 15 4 5
# CHECK: lw 0 3 0
		lw 0 3 five
# CHECK: nand 3 5 6
		nand 3 5 6
# CHECK: sw 0 15 0
		sw 0 15 one
# CHECK: sw 0 15 0
		sw 0 15 two
# CHECK: sw 0 3 0
		sw 0 3 three
# CHECK: addi 15 3 1
		addi 15 3 1
# CHECK: add 3 15 4
		add 3 15 4
# CHECK: addi 4 4 -1
		addi 4 4 -1
# CHECK: nor 4 3 5
		nor 4 3 5
# CHECK: addi 5 5 -1
		addi 5 5 -1
# CHECK: nand 5 4 6
		nand 5 4 6
# CHECK: lw 0 15 0
		lw 0 15 four
# CHECK: add 15 4 5
		add 15 4 5
# CHECK: lw 0 3 0
		lw 0 3 six
# CHECK: nor 3 5 6
		nor 3 5 6
# CHECK: lw 0 4 0
		lw 0 4 seven
# CHECK: nand 4 6 7
		nand 4 6 7
# CHECK: sw 0 15 0
		sw 0 15 eight
# CHECK: sw 0 3 0
		sw 0 3 nine
# CHECK: sw 0 4 0
		sw 0 4 num
# CHECK: addi 10 10 1
		addi 10 10 1
# CHECK: add 10 11 12
		add 10 11 12
# CHECK: nor 12 10 13
		nor 12 10 13
# CHECK: nand 13 12 14
		nand 13 12 14
# CHECK: lw 0 10 0
		lw 0 10 one
# CHECK: lw 0 11 0
		lw 0 11 five
# CHECK: sw 0 12 0
		sw 0 12 one
# CHECK: sw 0 13 0
		sw 0 13 two
# CHECK: addi 11 11 1
		addi 11 11 1
# CHECK: add 11 12 13
		add 11 12 13
# CHECK: nor 13 11 14
		nor 13 11 14
# CHECK: nand 14 13 15
		nand 14 13 15
# CHECK: lw 0 11 0
		lw 0 11 three
# CHECK: lw 0 12 0
		lw 0 12 four
# CHECK: sw 0 13 0
		sw 0 13 six
# CHECK: sw 0 14 0
		sw 0 14 seven
# CHECK: addi 12 12 1
		addi 12 12 1
# CHECK: add 12 13 14
		add 12 13 14
# CHECK: nor 14 12 15
		nor 14 12 15
# CHECK: nand 15 14 15
		nand 15 14 15
# CHECK: lw 0 12 0
		lw 0 12 eight
# CHECK: lw 0 13 0
		lw 0 13 nine
# CHECK: sw 0 14 0
		sw 0 14 num
# CHECK: sw 0 15 0
		sw 0 15 one
# CHECK: addi 3 3 1
		addi 3 3 1
# CHECK: add 3 4 5
		add 3 4 5
# CHECK: nor 5 3 6
		nor 5 3 6
# CHECK: nand 6 5 7
		nand 6 5 7
# CHECK: lw 0 3 0
		lw 0 3 five
# CHECK: sw 0 5 0
		sw 0 5 one
# CHECK: addi 4 4 1
		addi 4 4 1
# CHECK: add 4 5 6
		add 4 5 6
# CHECK: nor 6 4 7
		nor 6 4 7
# CHECK: nand 7 6 8
		nand 7 6 8
# CHECK: lw 0 4 0
		lw 0 4 two
# CHECK: sw 0 6 0
		sw 0 6 three
# CHECK: addi 5 5 1
		addi 5 5 1
# CHECK: add 5 6 7
		add 5 6 7
# CHECK: nor 7 5 8
		nor 7 5 8
# CHECK: nand 8 7 9
		nand 8 7 9
# CHECK: lw 0 5 0
		lw 0 5 four
# CHECK: sw 0 7 0
		sw 0 7 six
# CHECK: addi 6 6 1
		addi 6 6 1
# CHECK: add 6 7 8
		add 6 7 8
# CHECK: nor 8 6 9
		nor 8 6 9
# CHECK: nand 9 8 10
		nand 9 8 10
# CHECK: lw 0 6 0
		lw 0 6 seven
# CHECK: sw 0 8 0
		sw 0 8 eight
# CHECK: addi 7 7 1
		addi 7 7 1
# CHECK: add 7 8 9
		add 7 8 9
# CHECK: nor 9 7 10
		nor 9 7 10
# CHECK: nand 10 9 11
		nand 10 9 11
# CHECK: lw 0 7 0
		lw 0 7 nine
# CHECK: sw 0 9 0
		sw 0 9 num
# CHECK: addi 8 8 1
		addi 8 8 1
# CHECK: add 8 9 10
		add 8 9 10
# CHECK: nor 10 8 11
		nor 10 8 11
# CHECK: nand 11 10 12
		nand 11 10 12
# CHECK: lw 0 8 0
		lw 0 8 one
# CHECK: sw 0 10 0
		sw 0 10 five
# CHECK: addi 9 9 1
		addi 9 9 1
# CHECK: add 9 10 11
		add 9 10 11
# CHECK: nor 11 9 12
		nor 11 9 12
# CHECK: nand 12 11 13
		nand 12 11 13
# CHECK: lw 0 9 0
		lw 0 9 one
# CHECK: sw 0 11 0
		sw 0 11 two
# CHECK: addi 10 10 1
		addi 10 10 1
# CHECK: add 10 11 12
		add 10 11 12
# CHECK: nor 12 10 13
		nor 12 10 13
# CHECK: nand 13 12 14
		nand 13 12 14
# CHECK: lw 0 10 0
		lw 0 10 three
# CHECK: sw 0 12 0
		sw 0 12 four
# CHECK: addi 11 11 1
		addi 11 11 1
# CHECK: add 11 12 13
		add 11 12 13
# CHECK: nor 13 11 14
		nor 13 11 14
# CHECK: nand 14 13 15
		nand 14 13 15
# CHECK: lw 0 11 0
		lw 0 11 six
# CHECK: sw 0 13 0
		sw 0 13 seven
# CHECK: addi 12 12 1
		addi 12 12 1
# CHECK: add 12 13 14
		add 12 13 14
# CHECK: nor 14 12 15
		nor 14 12 15
# CHECK: nand 15 14 15
		nand 15 14 15
# CHECK: lw 0 12 0
		lw 0 12 eight
# CHECK: sw 0 14 0
		sw 0 14 nine
# CHECK: addi 13 13 1
		addi 13 13 1
# CHECK: add 13 14 15
		add 13 14 15
# CHECK: nor 15 13 15
		nor 15 13 15
# CHECK: nand 15 15 3
		nand 15 15 3
# CHECK: lw 0 13 0
		lw 0 13 num
# CHECK: sw 0 15 0
		sw 0 15 one
# CHECK: addi 14 14 1
		addi 14 14 1
# CHECK: add 14 15 15
		add 14 15 15
# CHECK: nor 15 14 3
		nor 15 14 3
# CHECK: nand 3 15 4
		nand 3 15 4
# CHECK: lw 0 14 0
		lw 0 14 five
# CHECK: sw 0 15 0
		sw 0 15 one
# CHECK: addi 15 15 1
		addi 15 15 1
# CHECK: add 15 15 3
		add 15 15 3
# CHECK: nor 3 15 4
		nor 3 15 4
# CHECK: nand 4 3 5
		nand 4 3 5
# CHECK: lw 0 15 0
		lw 0 15 two
# CHECK: sw 0 3 0
		sw 0 3 three
# CHECK: addi 15 15 1
		addi 15 15 1
# CHECK: add 15 3 4
		add 15 3 4
# CHECK: nor 4 15 5
		nor 4 15 5
# CHECK: nand 5 4 6
		nand 5 4 6
# CHECK: lw 0 15 0
		lw 0 15 four
# CHECK: sw 0 4 0
		sw 0 4 six
# CHECK: addi 3 3 -1
		addi 3 3 -1
# CHECK: add 4 3 5
		add 4 3 5
# CHECK: nor 5 4 6
		nor 5 4 6
# CHECK: nand 6 5 7
		nand 6 5 7
# CHECK: lw 0 3 0
		lw 0 3 seven
# CHECK: lw 0 4 0
		lw 0 4 eight
# CHECK: sw 0 5 0
		sw 0 5 nine
# CHECK: sw 0 6 0
		sw 0 6 num
# CHECK: addi 7 7 -1
		addi 7 7 -1
# CHECK: add 8 7 9
		add 8 7 9
# CHECK: nor 9 8 10
		nor 9 8 10
# CHECK: nand 10 9 11
		nand 10 9 11
# CHECK: lw 0 7 0
		lw 0 7 one
# CHECK: lw 0 8 0
		lw 0 8 five
# CHECK: sw 0 9 0
		sw 0 9 one
# CHECK: sw 0 10 0
		sw 0 10 two
# CHECK: addi 11 11 -1
		addi 11 11 -1
# CHECK: add 12 11 13
		add 12 11 13
# CHECK: nor 13 12 14
		nor 13 12 14
# CHECK: nand 14 13 15
		nand 14 13 15
# CHECK: lw 0 11 0
		lw 0 11 three
# CHECK: lw 0 12 0
		lw 0 12 four
# CHECK: sw 0 13 0
		sw 0 13 six
# CHECK: sw 0 14 0
		sw 0 14 seven
# CHECK: addi 15 15 -1
		addi 15 15 -1
# CHECK: add 15 15 3
		add 15 15 3
# CHECK: nor 3 15 4
		nor 3 15 4
# CHECK: nand 4 3 5
		nand 4 3 5
# CHECK: lw 0 15 0
		lw 0 15 eight
# CHECK: lw 0 15 0
		lw 0 15 nine
# CHECK: sw 0 3 0
		sw 0 3 num
# CHECK: sw 0 4 0
		sw 0 4 one
# CHECK: addi 10 10 -1
		addi 10 10 -1
# CHECK: addi 11 11 1
		addi 11 11 1
# CHECK: add 10 11 12
		add 10 11 12
# CHECK: nor 12 11 13
		nor 12 11 13
# CHECK: nand 13 10 14
		nand 13 10 14
# CHECK: lw 0 10 0
		lw 0 10 five
# CHECK: sw 0 12 0
		sw 0 12 one
# CHECK: addi 12 12 -1
		addi 12 12 -1
# CHECK: addi 13 13 1
		addi 13 13 1
# CHECK: add 12 13 14
		add 12 13 14
# CHECK: nor 14 13 15
		nor 14 13 15
# CHECK: nand 15 12 15
		nand 15 12 15
# CHECK: lw 0 12 0
		lw 0 12 two
# CHECK: sw 0 14 0
		sw 0 14 three
# CHECK: addi 14 14 -1
		addi 14 14 -1
# CHECK: addi 15 15 1
		addi 15 15 1
# CHECK: add 14 15 15
		add 14 15 15
# CHECK: nor 15 15 3
		nor 15 15 3
# CHECK: nand 3 14 4
		nand 3 14 4
# CHECK: lw 0 14 0
		lw 0 14 four
# CHECK: sw 0 15 0
		sw 0 15 six
# CHECK: addi 5 5 1
		addi 5 5 1
# CHECK: addi 5 5 -1
		addi 5 5 -1
# CHECK: add 5 6 7
		add 5 6 7
# CHECK: add 6 5 8
		add 6 5 8
# CHECK: nor 7 5 9
		nor 7 5 9
# CHECK: nand 8 7 10
		nand 8 7 10
# CHECK: lw 0 5 0
		lw 0 5 seven
# CHECK: lw 0 6 0
		lw 0 6 eight
# CHECK: sw 0 7 0
		sw 0 7 nine
# CHECK: sw 0 8 0
		sw 0 8 num
# CHECK: addi 9 9 1
		addi 9 9 1
# CHECK: addi 9 9 -1
		addi 9 9 -1
# CHECK: add 9 10 11
		add 9 10 11
# CHECK: add 10 9 12
		add 10 9 12
# CHECK: nor 11 9 13
		nor 11 9 13
# CHECK: nand 12 11 14
		nand 12 11 14
# CHECK: lw 0 9 0
		lw 0 9 one
# CHECK: lw 0 10 0
		lw 0 10 five
# CHECK: sw 0 11 0
		sw 0 11 one
# CHECK: sw 0 12 0
		sw 0 12 two
# CHECK: lw 0 3 0
		lw 0 3 one
# CHECK: addi 3 3 1
		addi 3 3 1
# CHECK: add 3 4 5
		add 3 4 5
# CHECK: nor 5 3 6
		nor 5 3 6
# CHECK: nand 6 5 7
		nand 6 5 7
# CHECK: lw 0 4 0
		lw 0 4 five
# CHECK: add 4 3 8
		add 4 3 8
# CHECK: addi 8 8 -1
		addi 8 8 -1
# CHECK: sw 0 8 0
		sw 0 8 one
# CHECK: lw 0 9 0
		lw 0 9 two
# CHECK: add 9 8 10
		add 9 8 10
# CHECK: nor 10 9 11
		nor 10 9 11
# CHECK: add 12 11 13
		add 12 11 13
# CHECK: addi 13 13 1
		addi 13 13 1
# CHECK: sw 0 13 0
		sw 0 13 four
# CHECK: lw 0 15 0
		lw 0 15 six
# CHECK: add 15 15 3
		add 15 15 3
# CHECK: sw 0 3 0
		sw 0 3 seven
# CHECK: addi 8 8 -1
		addi 8 8 -1
# CHECK: sw 0 8 0
		sw 0 8 one
# CHECK: lw 0 9 0
		lw 0 9 two
# CHECK: beq 0 0 -576
		beq 0 0 start
# CHECK: halt
done	halt			end of program

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 5
five	.fill 5			OUTPUTS
# CHECK: add 0 0 1
one		.fill 1
# CHECK: add 0 0 2
two		.fill 2
# CHECK: add 0 0 3
three	.fill 3
# CHECK: add 0 0 4
four	.fill 4
# CHECK: add 0 0 6
six		.fill 6
# CHECK: add 0 0 7
seven	.fill 7
# CHECK: add 0 0 8
eight	.fill 8
# CHECK: add 0 0 9
nine	.fill 9
# CHECK: add 0 0 5
num		.fill 5			INPUT
# CHECK: add 0 0 0
stAddr	.fill start		will contain the address of start (2)
