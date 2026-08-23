# Lookup table of the bitwise inversion of each __lc2k_bitmasks entry (i.e.
# ~(1 << i) for i in [0, 31]), one word per entry -- see bitmasks.S for the
# indexing convention (word offsets, not byte offsets).
	.globl	__lc2k_bitmasks_inv
__lc2k_bitmasks_inv	.fill	-2
	.fill	-3
	.fill	-5
	.fill	-9
	.fill	-17
	.fill	-33
	.fill	-65
	.fill	-129
	.fill	-257
	.fill	-513
	.fill	-1025
	.fill	-2049
	.fill	-4097
	.fill	-8193
	.fill	-16385
	.fill	-32769
	.fill	-65537
	.fill	-131073
	.fill	-262145
	.fill	-524289
	.fill	-1048577
	.fill	-2097153
	.fill	-4194305
	.fill	-8388609
	.fill	-16777217
	.fill	-33554433
	.fill	-67108865
	.fill	-134217729
	.fill	-268435457
	.fill	-536870913
	.fill	-1073741825
	.fill	2147483647
