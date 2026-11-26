# int __mulsi3(int a, int b)
#   a       -- R1 (first argument, CC_LC2K)
#   b       -- R2 (second argument, CC_LC2K)
#   return  -- R1 (RetCC_LC2K); a * b
#
# MSB-first shift-and-add (Horner's method): walk b from bit 31 down to
# bit 0, doubling the accumulator each step and adding a whenever the
# current bit of b is set. Doubling only the accumulator (never a) avoids
# needing a second doubling chain, unlike the classic LSB-first algorithm.
# Bit testing follows the same NOR trick as ashr.S/lshr.S: b is negated
# once up front so each iteration's "AND with bitmask" is a single `nor`
# against the pre-inverted __lc2k_bitmasks_inv table.
#
# Register usage:
# - R3: bit index counter (32 downto 0)
# - R4: scratch (masked bit of b)
# - R5: result accumulator
# - R6: -1 (phobos only)
#
# phobos has no NOR, so its version tests bits with NAND against the
# non-inverted __lc2k_bitmasks table instead: NAND(x, 1 << i) is -1 exactly
# when bit i of x is clear, so it is compared against R6 = -1.
	.weak	__mulsi3
#if defined(__LC2K_CPU_EECS470__)
__mulsi3	addi	0	3	32
	addi	0	5	0
	nor		2	2	2
__mulsi3_loop	beq	3	0	__mulsi3_done
	addi	3	3	-1
	lw		3	4	__lc2k_bitmasks_inv
	nor		2	4	4
	add		5	5	5
	beq		4	0	__mulsi3_skip
	add		1	5	5
__mulsi3_skip	beq	0	0	__mulsi3_loop
__mulsi3_done	add	0	5	1
	jalr	15	2
#elif defined(__LC2K_CPU_PHOBOS__)
__mulsi3	addi	0	3	32
	addi	0	5	0
	addi	0	6	-1
__mulsi3_loop	beq	3	0	__mulsi3_done
	addi	3	3	-1
	lw		3	4	__lc2k_bitmasks
	nand	2	4	4
	add		5	5	5
	beq		4	6	__mulsi3_skip
	add		1	5	5
__mulsi3_skip	beq	0	0	__mulsi3_loop
__mulsi3_done	add	0	5	1
	jalr	15	2
#else
#error "unknown LC2K CPU"
#endif
