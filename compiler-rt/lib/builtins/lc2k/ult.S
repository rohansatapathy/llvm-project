# int __lc2k_ult(unsigned int a, unsigned int b)
#   a       -- R1 
#   b       -- R2
#   return  -- R1 (RetCC_LC2K); 1 if a < b (unsigned), else 0
#
# Register usage:
# - R3: a XNOR b
# - R4: bitmask index counter
# - R5: scratch
	.globl	__lc2k_ult
__lc2k_ult	nor	1	1	3
	nor		2	2	4
	nor		3	4	4
	nor		1	2	3
	nor		3	4	3
	# R3 = a XNOR b
	nor		3	3	3
	addi	0	4	32
__lc2k_ult_loop	beq	4	0	__lc2k_ult_no
	addi	4	4	-1
	lw		4	5	__lc2k_bitmasks_inv
	nor		3	5	5
	# If bits are the same, continue loop
	beq		5	0	__lc2k_ult_loop
	# Otherwise, they must be different. R5 is currently one-hot, so invert to 
	# get zero-hot mask to handle other bits:
	nor		5	5	5
	# Then get the masked bit of b with the masked bit inverted.
	# If bit at b is 1 (i.e. inverted bit is 0), a < b
	nor		5	2	5
	beq		5	0	__lc2k_ult_yes
__lc2k_ult_no	addi	0	1	0
	jalr	15	0
__lc2k_ult_yes	addi	0	1	1
	jalr	15	0
