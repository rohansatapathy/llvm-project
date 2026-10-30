# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 14 0
main	lw 0 14 zero	// r14 = 0
# CHECK: lw 14 15 0
		lw 14 15 sp		// r15 = stack pointer (stack will grow upwards)
# CHECK: lw 14 2 0
		lw 14 2 addr	// r2 = address of gcd function
# CHECK: lw 14 0 0
		lw 14 0 oneA	// r0 = 2
# CHECK: lw 14 1 0
		lw 14 1 oneB	// r1 = 10
# CHECK: jalr 2 3
		jalr 2 3		// store return address in r3, jump to r2
# CHECK: addi 0 3 -1
		addi 0 3 -1		// r3 = r0 - 1 (checking if gcd(10,2) == 2)
# CHECK: beq 3 14 118
		beq 3 14 end	// error check, if gcd(10, 2) == 1, halt early
# CHECK: sw 14 0 0
		sw 14 0 oneA	// mem[oneA] = gcd(10,2) = 2
# CHECK: lw 14 0 0
		lw 14 0 twoA	// r0 = 128
# CHECK: lw 14 1 0
		lw 14 1 twoB	// r1 = 64
# CHECK: jalr 2 3
		jalr 2 3
# CHECK: sw 14 0 0
		sw 14 0 oneB	// mem[oneB] = gcd(128, 64) = 64
# CHECK: lw 14 0 0
		lw 14 0 threeA	// r0 = 987
# CHECK: lw 14 1 0
		lw 14 1 threeB	// r1 = 610
# CHECK: jalr 2 3
		jalr 2 3
# CHECK: sw 14 0 0
		sw 14 0 twoA	// mem[twoA] = 1
# CHECK: lw 14 0 0
		lw 14 0 fourA	// r0 = 2584
# CHECK: lw 14 1 0
		lw 14 1 fourB	// r1 = 1597
# CHECK: jalr 2 3
		jalr 2 3
# CHECK: sw 14 0 0
		sw 14 0 twoB	// mem[twoB] = 1
# CHECK: lw 14 0 0
		lw 14 0 fiveA	// r0 = 233
# CHECK: lw 14 1 0
		lw 14 1 fiveB	// r1 = 144
# CHECK: jalr 2 3
		jalr 2 3
# CHECK: sw 14 0 0
		sw 14 0 threeA	// mem[threeA] = 1
# CHECK: lw 14 0 0
		lw 14 0 sixA	// r0 = 377
# CHECK: lw 14 1 0
		lw 14 1 sixB	// r1 = 233
# CHECK: jalr 2 3
		jalr 2 3
# CHECK: sw 14 0 0
		sw 14 0 threeB	// mem[threeB] = 1
# CHECK: lw 14 0 0
		lw 14 0 sevenA	// r0 = 514
# CHECK: lw 14 1 0
		lw 14 1 sevenB	// r1 = 317
# CHECK: jalr 2 3
		jalr 2 3
# CHECK: sw 14 0 0
		sw 14 0 fourA	// mem[fourA] = 1
# CHECK: lw 14 0 0
		lw 14 0 eightA	// r0 = 1023
# CHECK: lw 14 1 0
		lw 14 1 eightB	// r1 = 632
# CHECK: jalr 2 3
		jalr 2 3
# CHECK: sw 14 0 0
		sw 14 0 fourB	// mem[fourB] = 1
# CHECK: lw 14 0 0
		lw 14 0 nineA	// r0 = 841
# CHECK: lw 14 1 0
		lw 14 1 nineB	// r1 = 520
# CHECK: jalr 2 3
		jalr 2 3
# CHECK: sw 14 0 0
		sw 14 0 fiveA	// mem[fiveA] = 1
# CHECK: lw 14 0 0
		lw 14 0 tenA	// r0 = 765
# CHECK: lw 14 1 0
		lw 14 1 tenB	// r1 = 473
# CHECK: jalr 2 3
		jalr 2 3
# CHECK: sw 14 0 0
		sw 14 0 fiveB	// mem[fiveB] = 1
# CHECK: lw 14 0 0
		lw 14 0 elevA	// r0 = 901
# CHECK: lw 14 1 0
		lw 14 1 elevB	// r1 = 557
# CHECK: jalr 2 3
		jalr 2 3
# CHECK: sw 14 0 0
		sw 14 0 sixA	// mem[sixA] = 1
# CHECK: lw 14 0 0
		lw 14 0 twelA	// r0 = 1189
# CHECK: lw 14 1 0
		lw 14 1 twelB	// r1 = 735
# CHECK: jalr 2 3
		jalr 2 3
# CHECK: sw 14 0 0
		sw 14 0 sixB	// mem[sixB] = 1
# CHECK: lw 14 0 0
		lw 14 0 thirA	// r0 = 1597
# CHECK: lw 14 1 0
		lw 14 1 thirB	// r1 = 897
# CHECK: jalr 2 3
		jalr 2 3
# CHECK: sw 14 0 0
		sw 14 0 sevenA	// mem[sevenA] = 1
# CHECK: lw 14 0 0
		lw 14 0 frtnA	// r0 = 2000
# CHECK: lw 14 1 0
		lw 14 1 frtnB	// r1 = 1234
# CHECK: jalr 2 3
		jalr 2 3
# CHECK: sw 14 0 0
		sw 14 0 sevenB	// mem[sevenB] = 1
# CHECK: lw 14 0 0
		lw 14 0 fftnA	// r0 = 1500
# CHECK: lw 14 1 0
		lw 14 1 fftnB	// r1 = 927
# CHECK: jalr 2 3
		jalr 2 3
# CHECK: sw 14 0 0
		sw 14 0 eightA	// mem[eightA] = 1
# CHECK: beq 0 0 60
		beq 0 0 end		// end
# CHECK: addi 15 15 1
gcd		addi 15 15 1	// ++sp (each address stores a word)
# CHECK: sw 15 1 0
		sw 15 1 0		// callee save r1 onto the stack
# CHECK: addi 15 15 1
		addi 15 15 1	// ++sp
# CHECK: sw 15 2 0
		sw 15 2 0		// callee save r2 onto the stack
# CHECK: addi 15 15 1
		addi 15 15 1	// ++sp
# CHECK: sw 15 3 0
		sw 15 3 0		// callee save r3 onto the stack
# CHECK: addi 15 15 1
		addi 15 15 1	// ++sp
# CHECK: sw 15 4 0
		sw 15 4 0		// callee save r4 onto the stack
# CHECK: addi 15 15 1
		addi 15 15 1	// ++sp
# CHECK: sw 15 5 0
		sw 15 5 0		// callee save r5 onto the stack
# CHECK: addi 15 15 1
		addi 15 15 1	// ++sp
# CHECK: sw 15 6 0
		sw 15 6 0		// callee save r6 onto the stack
# CHECK: addi 15 15 1
		addi 15 15 1	// ++sp
# CHECK: sw 15 7 0
		sw 15 7 0		// callee save r7 onto the stack
# CHECK: addi 15 15 1
		addi 15 15 1	// ++sp
# CHECK: sw 15 8 0
		sw 15 8 0		// callee save r8 onto the stack
# CHECK: addi 15 15 1
		addi 15 15 1	// ++sp
# CHECK: sw 15 9 0
		sw 15 9 0		// callee save r9 onto the stack
# CHECK: addi 15 15 1
		addi 15 15 1	// ++sp
# CHECK: sw 15 10 0
		sw 15 10 0		// callee save r10 onto the stack
# CHECK: addi 15 15 1
		addi 15 15 1	// ++sp
# CHECK: sw 15 11 0
		sw 15 11 0		// callee save r11 onto the stack
# CHECK: nand 1 1 2
loop	nand 1 1 2		// r2 = -r1
# CHECK: addi 2 4 1
		addi 2 4 1		// r4 = -r1 + 1, (2's complement of r1)
# CHECK: add 0 4 5
		add 0 4 5		// r5 = r0 - r1 (diff = r0 + r4)
# CHECK: lw 14 6 0
		lw 14 6 zero	// r6 = 0
# CHECK: beq 5 6 10
		beq 5 6 return	// if diff == 0, return r0
# CHECK: addi 14 7 -524288
		addi 14 7 -524288	// r7 = 0x800... (sign_mask)
# CHECK: nand 5 7 8
		nand 5 7 8		// r8 = nand(diff, sign_mask)
# CHECK: nand 8 8 9
		nand 8 8 9		// r9 = MSB = 1: neg, MSB = 0: pos ( r8 = and(diff, sign mask) )
# CHECK: beq 6 9 4
		beq 6 9 diffA	// if sign_bit == 0, a = diff: else, compute b - a
# CHECK: nand 0 0 10
		nand 0 0 10		// r10 = -r0
# CHECK: addi 10 11 1
		addi 10 11 1	// r11 = -r10 + 1, (2's complement of r0)
# CHECK: add 1 11 1
		add 1 11 1		// r1 = r1 - r11 (b = b - a)
# CHECK: beq 0 0 -13
		beq 0 0 loop
# CHECK: addi 5 0 0
diffA	addi 5 0 0		// r0 = r5 (a = a - b)
# CHECK: beq 0 0 -15
		beq 0 0 loop
# CHECK: lw 15 11 0
return	lw 15 11 0		// callee load r11 from stack
# CHECK: addi 15 15 -1
		addi 15 15 -1	// --sp
# CHECK: lw 15 10 0
		lw 15 10 0		// callee load r10 from stack
# CHECK: addi 15 15 -1
		addi 15 15 -1	// --sp
# CHECK: lw 15 9 0
		lw 15 9 0		// callee load r9 from stack
# CHECK: addi 15 15 -1
		addi 15 15 -1	// --sp
# CHECK: lw 15 8 0
		lw 15 8 0		// callee load r8 from stack
# CHECK: addi 15 15 -1
		addi 15 15 -1	// --sp
# CHECK: lw 15 7 0
		lw 15 7 0		// callee load r7 from stack
# CHECK: addi 15 15 -1
		addi 15 15 -1	// --sp
# CHECK: lw 15 6 0
		lw 15 6 0		// callee load r6 from stack
# CHECK: addi 15 15 -1
		addi 15 15 -1	// --sp
# CHECK: lw 15 5 0
		lw 15 5 0		// callee load r5 from stack
# CHECK: addi 15 15 -1
		addi 15 15 -1	// --sp
# CHECK: lw 15 4 0
		lw 15 4 0		// callee load r4 from stack
# CHECK: addi 15 15 -1
		addi 15 15 -1	// --sp
# CHECK: lw 15 3 0
		lw 15 3 0		// callee load r3 from stack
# CHECK: addi 15 15 -1
		addi 15 15 -1	// --sp
# CHECK: lw 15 2 0
		lw 15 2 0		// callee load r2 from stack
# CHECK: addi 15 15 -1
		addi 15 15 -1	// --sp
# CHECK: lw 15 1 0
		lw 15 1 0		// callee load r2 from stack
# CHECK: addi 15 15 -1
		addi 15 15 -1	// --sp
# CHECK: jalr 3 12
		jalr 3 12		// jump to main
# CHECK: halt
end		halt

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
zero	.fill 0
# CHECK: add 0 0 0
addr	.fill gcd
# CHECK: add 0 0 2
oneA	.fill 2
# CHECK: add 0 0 10
oneB	.fill 10
# CHECK: add 0 0 0
twoA	.fill 128
# CHECK: add 0 0 0
twoB	.fill 64
# CHECK: add 0 0 11
threeA	.fill 987
# CHECK: add 0 0 2
threeB	.fill 610
# CHECK: add 0 0 8
fourA	.fill 2584
# CHECK: add 0 0 13
fourB	.fill 1597
# CHECK: add 0 0 9
fiveA	.fill 233
# CHECK: add 0 0 0
fiveB	.fill 144
# CHECK: add 0 0 9
sixA	.fill 377
# CHECK: add 0 0 9
sixB	.fill 233
# CHECK: add 0 0 2
sevenA	.fill 514
# CHECK: add 0 0 13
sevenB	.fill 317
# CHECK: add 0 0 15
eightA	.fill 1023
# CHECK: add 0 0 8
eightB	.fill 632
# CHECK: add 0 0 9
nineA	.fill 841
# CHECK: add 0 0 8
nineB	.fill 520
# CHECK: add 0 0 13
tenA	.fill 765
# CHECK: add 0 0 9
tenB	.fill 473
# CHECK: add 0 0 5
elevA	.fill 901
# CHECK: add 0 0 13
elevB	.fill 557
# CHECK: add 0 0 5
twelA	.fill 1189
# CHECK: add 0 0 15
twelB	.fill 735
# CHECK: add 0 0 13
thirA	.fill 1597
# CHECK: add 0 0 1
thirB	.fill 897
# CHECK: add 0 0 0
frtnA	.fill 2000
# CHECK: add 0 0 2
frtnB	.fill 1234
# CHECK: add 0 0 12
fftnA	.fill 1500
# CHECK: add 0 0 15
fftnB	.fill 927
# CHECK: add 0 0 0
sp		.fill sp
