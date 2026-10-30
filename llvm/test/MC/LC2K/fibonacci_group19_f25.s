# RUN: llvm-mc --arch=lc2k --filetype=obj %s \
# RUN:  | llvm-objdump --disassemble --section=.text --section=.data - \
# RUN:  | FileCheck %s

# NOTE: labels in a different section than the instruction/directive are
# unresolved until link time, so fixups emit 0 for I-type offsets or .fills
# that reference such labels.

# CHECK: Disassembly of section .text:

# CHECK: lw 0 15 0
start	lw 0 15 zero	r15 <- Mem[0 + addr(zero)] = 0 (load constant 0)
# CHECK: lw 15 13 0
		lw 15 13 stkTop	r13 (SP) <- Mem[0 + addr(stkTop)] = 0x40
# CHECK: lw 15 1 0
		lw 15 1 n		r1 <- Mem[0 + addr(N)] = input N
# CHECK: addi 15 3 0
		addi 15 3 FIB	r3 <- addr(FIB) (r15 is 0, so r3 = 0 + FIB)
# CHECK: jalr 3 2
		jalr 3 2		call FIB(N): jump to r3; r2 <- return address
# CHECK: sw 15 1 0
		sw 15 1 result	Mem[0 + addr(result)] <- r1 (store result)
# CHECK: halt
		halt			Stop execution
# CHECK: lw 15 3 0
FIB		lw 15 3 one		r3 <- 1 (load constant one)
# CHECK: beq 1 15 17
		beq 1 15 is1or0	if r1 == 0: branch to base case (Fib(0) = 0)
# CHECK: beq 1 3 16
		beq 1 3 is1or0	if r1 == 1: branch to base case (Fib(1) = 1)
# CHECK: addi 13 13 -2
		addi 13 13 -2	SP -= 2: make space for RA and saved N
# CHECK: sw 13 2 0
		sw 13 2 0		[SP+0] <- r2 (save return address)
# CHECK: sw 13 1 1
		sw 13 1 1		[SP+1] <- r1 (save original N)
# CHECK: addi 1 1 -1
		addi 1 1 -1		r1 <- N - 1 (argument for FIB(N-1))
# CHECK: addi 15 3 0
		addi 15 3 FIB	r3 <- addr(FIB)
# CHECK: jalr 3 2
		jalr 3 2		call FIB(N-1); on return r1 = Fib(N-1)
# CHECK: lw 13 4 1
		lw 13 4 1		r4 <- [SP+1] = original N
# CHECK: sw 13 1 1
		sw 13 1 1		[SP+1] <- r1 = Fib(N-1) (stash Fib(N-1))
# CHECK: addi 4 1 -2
		addi 4 1 -2		r1 <- r4 - 2 = (original N) - 2 (argument for FIB(N-2))
# CHECK: addi 15 3 0
		addi 15 3 FIB	r3 <- addr(FIB)
# CHECK: jalr 3 2
		jalr 3 2		call FIB(N-2); on return r1 = Fib(N-2)
# CHECK: lw 13 3 1
		lw 13 3 1		r3 <- [SP+1] = Fib(N-1)
# CHECK: add 1 3 1
		add 1 3 1		r1 <- r1 + r3 = Fib(N-2) + Fib(N-1)
# CHECK: lw 13 2 0
		lw 13 2 0		r2 <- [SP+0] (restore return address)
# CHECK: addi 13 13 2
		addi 13 13 2	SP += 2 (pop stack frame)
# CHECK: jalr 2 3
		jalr 2 3		return to caller: jump to r2 (r3 gets ignored)
# CHECK: jalr 2 3
is1or0	jalr 2 3		Base case: return with r1 already 0 or 1

# CHECK: Disassembly of section .data:

# CHECK: add 0 0 0
result	.fill 0			Memory location to store the final Fibonacci result OUTPUT
# CHECK: add 0 0 10
n		.fill 10		INPUT N (Fibonacci argument); here N = 10
# CHECK: add 0 0 0
zero	.fill 0			Constant 0
# CHECK: add 0 0 1
one		.fill 1			Constant 1
# CHECK: add 0 0 0
stkTop .fill 0x40		Initial stack pointer value (top of stack)
