# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: addi 0 4 0
		addi 0 4 0		//R4 = 0, just creates a dependency for this load
# CHECK: lw 0 4 0
		lw 0 4 numfib	//R4 = 10 (compute first 10 Fibonacci numbers)
# CHECK: lw 0 6 0
		lw 0 6 mem		//R6 = base memory address to store Fibonacci numbers
# CHECK: addi 0 2 0
		addi 0 2 0		//R2 = 0 (fib_0)		//cache line end
# CHECK: addi 0 1 1
		addi 0 1 1		//R1 = 1 (fib_1)
# CHECK: addi 0 1 1
		addi 0 1 1		//redundant but switches order of lw and addi when issued
# CHECK: addi 0 1 1
		addi 0 1 1		//redundant but switches order of lw and addi when issued
# CHECK: lw 0 3 0
		lw 0 3 zero		//R3 = 0 (loop index)
# CHECK: sw 6 2 0
		sw 6 2 0		//store fib_0 at memory[R6 + 0]
# CHECK: addi 3 3 1
		addi 3 3 1		//R3 = 1
# CHECK: sw 6 1 1
		sw 6 1 1		//store fib_1 at memory[R6 + 1]
# CHECK: addi 6 6 1
		addi 6 6 1
# CHECK: addi 6 6 1
		addi 6 6 1		//increment store pointer, need to keep cache lines
# CHECK: lw 0 15 0
		lw 0 15 times	//loads number of times to loop
# CHECK: lw 0 14 0
		lw 0 14 zero	//keep cache lines lined up
# CHECK: add 1 2 5
loop	add 1 2 5		//R5 = fib_n + fib_n-1 (next Fibonacci)
# CHECK: sw 6 5 0
		sw 6 5 0		//store new value at memory[R6 + R3]
# CHECK: add 0 1 2
		add 0 1 2		//R2 = previous fib_n (old R1)
# CHECK: add 0 5 1
		add 0 5 1		//R1 = new Fibonacci number (R5)
# CHECK: addi 3 3 1
		addi 3 3 1		//increment loop index R3
# CHECK: beq 3 4 3
		beq 3 4 rst		//if R3 == N, reset
# CHECK: addi 6 6 1
		addi 6 6 1		//increment memory offset
# CHECK: noop
		noop			//puts beq on seond half of cache line
# CHECK: beq 0 0 -9
		beq 0 0 loop	//repeat
# CHECK: lw 0 4 0
rst		lw 0 4 numfib	//R4 = 10 (compute first 10 Fibonacci numbers)
# CHECK: lw 0 6 0
		lw 0 6 mem		//R6 = base memory address to store Fibonacci numbers
# CHECK: addi 0 2 0
		addi 0 2 0		//R2 = 0 (fib_0) //cache line end
# CHECK: addi 0 1 1
		addi 0 1 1		//R1 = 1 (fib_1)
# CHECK: lw 0 3 0
		lw 0 3 zero		//R3 = 0 (loop index)
# CHECK: sw 6 2 0
		sw 6 2 0		//store fib_0 at memory[R6 + 0]
# CHECK: addi 3 3 1
		addi 3 3 1		//R3 = 1
# CHECK: sw 6 1 1
		sw 6 1 1		//store fib_1 at memory[R6 + 1]
# CHECK: addi 14 14 1
		addi 14 14 1	//increment outer loop
# CHECK: addi 3 3 1
		addi 3 3 1		//increment loop index R3
# CHECK: beq 14 15 1
		beq 14 15 done	//if R3 == N, done
# CHECK: beq 0 0 -21
		beq 0 0 loop
# CHECK: halt
done	halt

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 6
times	.fill 6			//number of times to calculate all fibonocci nums INPUT
# CHECK: add 0 0 14
numfib	.fill 46		//number of fibonacci numbers to calculate (46 is the max for reg size) INPUT
# CHECK: add 0 0 0
zero 	.fill 0			//zero
# CHECK: add 0 0 0
mem		.fill output	//starting point of memory for storing fib nums
# CHECK: add 0 0 0
output	.fill 0			OUTPUT
