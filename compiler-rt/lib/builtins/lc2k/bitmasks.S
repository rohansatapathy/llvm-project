# Lookup table of the 32 single-bit masks (1 << i for i in [0, 31]), one
# word per entry, so other LC2K routines can test/set/clear an individual
# bit without hardware shift support.
#
# Indexing: LC2K is word-addressed, so `lw <base> <dst> <i>` with <base>
# holding the address of __lc2k_bitmasks fetches element i directly --
# there's no need to scale i by 4 the way a byte-addressed target would.
#
# Entry 31 is written as -2147483648 (its two's-complement bit pattern)
# rather than 2147483648, since .fill only accepts values that fit a
# signed 32-bit integer.
	.globl	__lc2k_bitmasks
__lc2k_bitmasks	.fill	1
	.fill	2
	.fill	4
	.fill	8
	.fill	16
	.fill	32
	.fill	64
	.fill	128
	.fill	256
	.fill	512
	.fill	1024
	.fill	2048
	.fill	4096
	.fill	8192
	.fill	16384
	.fill	32768
	.fill	65536
	.fill	131072
	.fill	262144
	.fill	524288
	.fill	1048576
	.fill	2097152
	.fill	4194304
	.fill	8388608
	.fill	16777216
	.fill	33554432
	.fill	67108864
	.fill	134217728
	.fill	268435456
	.fill	536870912
	.fill	1073741824
	.fill	-2147483648
