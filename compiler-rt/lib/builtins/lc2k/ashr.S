# int __lc2k_ashr(int val, int shift_amt)
#   val        -- R1 (first argument, CC_LC2K)
#   shift_amt  -- R2 (second argument, CC_LC2K)
#   return     -- R1 (RetCC_LC2K)
#
# Register usage:
# - R3: bit index counter (31 downto shift_amt)
# - R4: result accumulator, seeded 0 or -1 (see below)
# - R5: scratch
	.globl	__lc2k_ashr
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
	jalr	15	0
