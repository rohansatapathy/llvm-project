# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 1 0
		lw 0 1 N		# r1 = N (trip count, single-loop)
# CHECK: lw 0 2 0
		lw 0 2 base		#r2 = &array[0]
# CHECK: add 0 3 0
		add 0 3 0
# CHECK: add 0 4 0
		add 0 4 0
# CHECK: lw 0 5 0
		lw 0 5 MASK		# r5 = -1 (0xFFFFFFFF)
# CHECK: addi 0 6 1
		addi 0 6 1		#r6 = 1 (const +1)
# CHECK: lw 0 11 0
		lw 0 11 PERIOD	#r11 = K (branch period)
# CHECK: add 0 11 8
		add 0 11 8		#r8 = K (periodic counter)
# CHECK: add 0 12 0
		add 0 12 0
# CHECK: lw 2 4 0
loop	lw 2 4 0		# r4 = mem[array[0]]
# CHECK: lw 2 9 1
		lw 2 9 1		# r9 = mem[array[1]]
# CHECK: add 3 4 3
		add 3 4 3		# r3 = r3 + r4 (RAW for r4)
# CHECK: addi 4 4 7
		addi 4 4 7		#r4 = r4 + 7 (WAR for r4)
# CHECK: nand 3 5 3
		nand 3 5 3		#r3 = ~r3 (WAW for r3)
# CHECK: sw 2 4 0
		sw 2 4 0		#mem[array[0]] = r4
# CHECK: sw 2 9 1
		sw 2 9 1		# mem[array[1]] = r9
# CHECK: beq 4 9 2
		beq 4 9 eqpath	#Branch #1: r4 == r9 ?
# CHECK: add 3 6 3
		add 3 6 3		#(NotEQ path) r3 += 1
# CHECK: beq 0 0 2
		beq 0 0 aftB1	#100% jump
# CHECK: add 4 6 4
eqpath	add 4 6 4		# (EQ path) r4 += 1
# CHECK: add 12 6 12
		add 12 6 12		#branch jump count
# CHECK: addi 8 8 -1
aftB1	addi 8 8 -1		#period count r8--
# CHECK: beq 8 0 2
		beq 8 0 skip	#Branch		#2: jump every k times
# CHECK: add 3 6 3
		add 3 6 3		# (NOT do skip) r3 += 1
# CHECK: beq 0 0 3
		beq 0 0 aftB2	#100&jump
# CHECK: add 0 11 8
skip	add 0 11 8		#r8 = K
# CHECK: add 4 6 4
		add 4 6 4		# (doskip path) r4 += 1
# CHECK: add 12 6 12
		add 12 6 12		#branch jump count
# CHECK: addi 1 1 -1
aftB2	addi 1 1 -1		# r1--
# CHECK: beq 1 0 1
		beq 1 0 done	# exit loop
# CHECK: beq 0 0 -22
		beq 0 0 loop
# CHECK: sw 0 3 0
done	sw 0 3 resALU
# CHECK: sw 0 4 0
		sw 0 4 rLAST
# CHECK: sw 0 1 0
		sw 0 1 resR1
# CHECK: sw 0 8 0
		sw 0 8 resR8
# CHECK: sw 0 12 0
		sw 0 12 nTaken
# CHECK: halt
		halt

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
base	.fill array
# CHECK: add 0 0 12
N		.fill 220
# CHECK: add 0 0 3
PERIOD	.fill 3			#2~==50%jump,3~==33%,4~==25%...
# CHECK: <unknown>
MASK	.fill -1
# CHECK: add 0 0 1
array	.fill 1
# CHECK: add 0 0 2
		.fill 2
# CHECK: add 0 0 0
resALU	.fill 0			OUTPUT
# CHECK: add 0 0 0
rLAST	.fill 0			OUTPUT
# CHECK: add 0 0 0
resR1	.fill 0			OUTPUT
# CHECK: add 0 0 0
resR8	.fill 0			OUTPUT
# CHECK: add 0 0 0
nTaken	.fill 0			OUTPUT
