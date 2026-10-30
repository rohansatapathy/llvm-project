# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: addi 0 12 12
start	addi 0 12 12	INPUT
# CHECK: addi 0 5 0
		addi 0 5 fact
# CHECK: addi 0 6 0
		addi 0 6 mul
# CHECK: beq 1 12 7
fLoop	beq 1 12 end
# CHECK: addi 1 1 1
		addi 1 1 1
# CHECK: addi 1 3 0
		addi 1 3 Stack
# CHECK: add 1 3 3
		add 1 3 3
# CHECK: add 1 3 3
		add 1 3 3
# CHECK: jalr 5 7
		jalr 5 7
# CHECK: sw 1 2 0
		sw 1 2 Stack
# CHECK: beq 0 0 -8
		beq 0 0 fLoop
# CHECK: halt
end		halt
# CHECK: addi 3 3 -1
fact	addi 3 3 -1
# CHECK: sw 3 1 0
		sw 3 1 0
# CHECK: addi 3 3 -1
		addi 3 3 -1
# CHECK: sw 3 7 0
		sw 3 7 0
# CHECK: addi 1 4 -1
		addi 1 4 -1
# CHECK: beq 4 0 8
		beq 4 0 base
# CHECK: addi 1 1 -1
		addi 1 1 -1
# CHECK: jalr 5 7
		jalr 5 7
# CHECK: lw 3 11 0
		lw 3 11 0
# CHECK: addi 3 3 1
		addi 3 3 1
# CHECK: lw 3 1 0
		lw 3 1 0
# CHECK: addi 3 3 1
		addi 3 3 1
# CHECK: jalr 6 7
		jalr 6 7
# CHECK: jalr 11 10
		jalr 11 10
# CHECK: addi 0 2 1
base	addi 0 2 1
# CHECK: lw 3 7 0
		lw 3 7 0
# CHECK: addi 3 3 1
		addi 3 3 1
# CHECK: lw 3 1 0
		lw 3 1 0
# CHECK: addi 3 3 1
		addi 3 3 1
# CHECK: jalr 7 10
		jalr 7 10
# CHECK: addi 0 8 0
mul		addi 0 8 0
# CHECK: addi 1 9 0
		addi 1 9 0
# CHECK: beq 9 0 3
mLoop	beq 9 0 mDone
# CHECK: add 8 2 8
		add 8 2 8
# CHECK: addi 9 9 -1
		addi 9 9 -1
# CHECK: beq 0 0 -4
		beq 0 0 mLoop
# CHECK: add 8 0 2
mDone	add 8 0 2
# CHECK: jalr 7 10
		jalr 7 10

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
Stack	.fill 0			OUTPUT Stack[1:INPUT]
