// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

int bitwise_and(int a, int b) { return a & b; }
int bitwise_or(int a, int b) { return a | b; }
int bitwise_xor(int a, int b) { return a ^ b; }
int bitwise_not(int a) { return ~a; }

int shift_left(int a, int n) { return a << n; }
int shift_right_signed(int a, int n) { return a >> n; }
unsigned shift_right_unsigned(unsigned a, int n) { return a >> n; }

int compound_bitwise(int a, int b) {
  a &= b;
  a |= 0xF;
  a ^= b;
  a <<= 2;
  a >>= 1;
  return a;
}
