// At -O1 and above, logical/bitwise combinations of comparisons are narrowed
// to i1 and/or/xor, which must still compile.
// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -O1 -emit-obj -o /dev/null %s

int logical_and(int a, int b, int c) { return a == b && b == c; }
int logical_or(int a, int b, int c) { return a == b || b == c; }
int logical_xor(int a, int b, int c) { return (a == b) ^ (b == c); }
