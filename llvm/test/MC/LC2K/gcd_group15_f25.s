# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: addi 0 1 48
		addi 0 1 48		// r1 = input
# CHECK: addi 0 2 18
		addi 0 2 18		// r2 = input
# CHECK: lw 0 7 0
		lw 0 7 addr		// r7 = addr
# CHECK: sw 7 1 0
		sw 7 1 addr
# CHECK: addi 7 7 -1
		addi 7 7 -1
# CHECK: sw 7 2 0
		sw 7 2 addr
# CHECK: addi 7 7 -1
		addi 7 7 -1
# CHECK: beq 1 2 14
loop	beq 1 2 final	// if r1 = r2, goto final
# CHECK: nand 2 2 3
		nand 2 2 3		// r3 = -r2 - 1
# CHECK: addi 3 3 1
		addi 3 3 1		// r3 = -r2
# CHECK: add 1 3 4
		add 1 3 4		// r4 = a - b
# CHECK: lw 0 5 0
		lw 0 5 mask		// r5 = mask
# CHECK: nand 4 5 6
		nand 4 5 6		// r6 checks r4 r5 masks
# CHECK: nand 6 6 6
		nand 6 6 6		// r6 = mask
# CHECK: beq 6 0 1
		beq 6 0 big		// r6 chooses > or <
# CHECK: beq 0 0 2
		beq 0 0 less	// if a < b, b = b-a.
# CHECK: add 1 3 1
big		add 1 3 1		// if a > b, a = a-b
# CHECK: beq 0 0 -11
		beq 0 0 loop
# CHECK: nand 1 1 3
less	nand 1 1 3		// r3 = -r1 - 1
# CHECK: addi 3 3 1
		addi 3 3 1		// r3 = -r1
# CHECK: add 2 3 2
		add 2 3 2		// b = b-a
# CHECK: beq 0 0 -15
		beq 0 0 loop
# CHECK: sw 7 1 0
final	sw 7 1 addr
# CHECK: lw 7 3 49
		lw 7 3 49		// keep updating based on imem (more inst means higher)
# CHECK: lw 7 4 48
		lw 7 4 48		// update on imem
# CHECK: nor 3 4 1
		nor 3 4 1
# CHECK: addi 7 7 -1
		addi 7 7 -1
# CHECK: beq 7 0 15
		beq 7 0 done
# CHECK: lw 0 5 0
		lw 0 5 mask
# CHECK: nand 1 5 6
		nand 1 5 6
# CHECK: nand 6 6 6
		nand 6 6 6
# CHECK: beq 6 0 9
		beq 6 0 pos
# CHECK: beq 0 0 0
		beq 0 0 neg
# CHECK: nand 1 1 1
neg		nand 1 1 1
# CHECK: addi 1 1 1
		addi 1 1 1
# CHECK: add 7 4 2
		add 7 4 2		New inputs are inputted into the system by loading the previous 2 inputs,
# CHECK: addi 2 2 27
		addi 2 2 27		NOR-ing them, and adding arbitrary values along with the address offset.
# CHECK: sw 7 1 0
		sw 7 1 addr		This creates 2 new values and the initial
# CHECK: addi 7 7 -1
		addi 7 7 -1		process repeats until the GCD is found.
# CHECK: sw 7 2 0
		sw 7 2 addr
# CHECK: addi 7 7 -1
		addi 7 7 -1
# CHECK: beq 7 0 1
pos		beq 7 0 done
# CHECK: beq 0 0 -36
		beq 0 0 loop
# CHECK: noop
done	noop
# CHECK: halt
		halt

# CHECK: Disassembly of section .data:

# CHECK: addi 0 0 0
mask	.fill 0x80000000
# CHECK: add 0 0 4
addr	.fill 180		// increments of 3 OUTPUT
