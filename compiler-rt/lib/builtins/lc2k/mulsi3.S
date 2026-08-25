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
	.globl	__mulsi3
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
	jalr	15	0
