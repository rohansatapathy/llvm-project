# unsigned int __lc2k_lshr(unsigned int val, int shift_amt)
#   val        -- R1 (first argument, CC_LC2K)
#   shift_amt  -- R2 (second argument, CC_LC2K)
#   return     -- R1 (RetCC_LC2K)
#
# Register usage:
# - R3: bit index counter (31 downto shift_amt)
# - R4: result accumulator
# - R5: scratch
	.globl	__lc2k_lshr
__lc2k_lshr	addi	0	3	32
	addi	0	4	0
	nor		1	1	1
__lc2k_lshr_loop	beq	3	2	__lc2k_lshr_done
	addi	3	3	-1
	lw		3	5	__lc2k_bitmasks_inv
	nor		1	5	5
	# R5 = val AND (1 << R3); double the accumulator, then add 1 if that
	# bit was set.
	add		4	4	4
	beq		5	0	__lc2k_lshr_skip
	addi	4	4	1
__lc2k_lshr_skip	beq	0	0	__lc2k_lshr_loop
__lc2k_lshr_done	add	0	4	1
	jalr	15	0
