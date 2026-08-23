# int __lc2k_shl(int val, int shift_amt)
#   val        -- R1 (first argument, CC_LC2K)
#   shift_amt  -- R2 (second argument, CC_LC2K)
#   return     -- R1 (RetCC_LC2K)
	.globl	__lc2k_shl
__lc2k_shl	addi 	0	3	0
__lc2k_shl_loop beq		3	2	__lc2k_shl_end
	add		1	1	1
	addi	3	3	1
	beq		0	0	__lc2k_shl_loop
__lc2k_shl_end	jalr	15	0
