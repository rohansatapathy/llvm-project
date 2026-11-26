# int __lc2k_ashr(int val, int shift_amt)
#   val        -- R1 (first argument, CC_LC2K)
#   shift_amt  -- R2 (second argument, CC_LC2K)
#   return     -- R1 (RetCC_LC2K)
#
# Register usage:
# - R3: bit index counter (31 downto shift_amt)
# - R4: result accumulator, seeded 0 or -1 (see below)
# - R5: scratch
# - R6: -1 (phobos only)
#
# phobos has no NOR, so its version tests bits with NAND against the
# non-inverted __lc2k_bitmasks table instead: NAND(x, 1 << i) is -1 exactly
# when bit i of x is clear, so it is compared against R6 = -1.
	.weak	__lc2k_ashr
#if defined(__LC2K_CPU_EECS470__)
__lc2k_ashr	addi	0	3	32
	nor		1	1	1
	addi	0	5	31
	lw		5	5	__lc2k_bitmasks_inv
	nor		1	5	5
	# R5 = val AND (1 << 31); nonzero iff val is negative.
	beq		5	0	__lc2k_ashr_pos
	addi	0	4	-1
	beq		0	0	__lc2k_ashr_loop
__lc2k_ashr_pos	addi	0	4	0
__lc2k_ashr_loop	beq	3	2	__lc2k_ashr_done
	addi	3	3	-1
	lw		3	5	__lc2k_bitmasks_inv
	nor		1	5	5
	# R5 = val AND (1 << R3); double the accumulator, then add 1 if that
	# bit was set.
	add		4	4	4
	beq		5	0	__lc2k_ashr_skip
	addi	4	4	1
__lc2k_ashr_skip	beq	0	0	__lc2k_ashr_loop
__lc2k_ashr_done	add	0	4	1
	jalr	15	2
#elif defined(__LC2K_CPU_PHOBOS__)
__lc2k_ashr	addi	0	3	32
	addi	0	6	-1
	addi	0	5	31
	lw		5	5	__lc2k_bitmasks
	nand	1	5	5
	# R5 = -1 iff val is non-negative.
	beq		5	6	__lc2k_ashr_pos
	addi	0	4	-1
	beq		0	0	__lc2k_ashr_loop
__lc2k_ashr_pos	addi	0	4	0
__lc2k_ashr_loop	beq	3	2	__lc2k_ashr_done
	addi	3	3	-1
	lw		3	5	__lc2k_bitmasks
	nand	1	5	5
	# R5 = -1 iff bit R3 of val is clear. Double the accumulator, then add 1
	# when that bit was set.
	add		4	4	4
	beq		5	6	__lc2k_ashr_skip
	addi	4	4	1
__lc2k_ashr_skip	beq	0	0	__lc2k_ashr_loop
__lc2k_ashr_done	add	0	4	1
	jalr	15	2
#else
#error "unknown LC2K CPU"
#endif
