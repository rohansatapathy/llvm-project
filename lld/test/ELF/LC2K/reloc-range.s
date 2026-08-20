// Regression test: LC2K's ADDI/LW/SW/BEQ instructions all pack a value into a
// signed 20-bit field (R_LC2K_20 for absolute word addresses, matching every
// isInt<20> check in the codegen backend; R_LC2K_20_PCPLUS1REL for BEQ's
// PC-relative branch offset). Both used to be silently truncated by
// LC2K::relocate with no diagnostic at all -- this checks the real
// out-of-range error introduced instead.

// RUN: llvm-mc -filetype=obj -triple=lc2k %s -o %t.o

// RUN: not ld.lld %t.o --defsym big=6000000 2>&1 | FileCheck %s --check-prefix=ABS --implicit-check-not=error:
// ABS: error: {{.*}}: relocation R_LC2K_20 out of range: 1500000 is not in [-524288, 524287]; references 'big'

// RUN: not ld.lld %t.o --defsym big=-6000000 2>&1 | FileCheck %s --check-prefix=ABS-NEG --implicit-check-not=error:
// ABS-NEG: error: {{.*}}: relocation R_LC2K_20 out of range: -1500000 is not in [-524288, 524287]; references 'big'

// A word address of exactly 524287 (the largest that fits a signed 20-bit
// field) must still link successfully.
// RUN: ld.lld %t.o --defsym big=2097148 -o %t

// RUN: llvm-mc -filetype=obj -triple=lc2k %S/Inputs/branch-range.s -o %t2.o
// RUN: not ld.lld %t2.o --defsym far=6000000 2>&1 | FileCheck %s --check-prefix=PCREL --implicit-check-not=error:
// PCREL: error: {{.*}}: relocation R_LC2K_20_PCPLUS1REL out of range: 1482546 is not in [-524288, 524287]; references 'far'

foo	addi	0	1	big
	jalr	15	0
