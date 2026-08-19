// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

long long add_ll(long long a, long long b) {
  return a + b;
}

long long mul_ll(long long a, long long b) {
  return a * b;
}

int ll_to_int(long long a) {
  return (int)a;
}

long long int_to_ll(int a) {
  return (long long)a;
}

unsigned long long shift_ull(unsigned long long a, int n) {
  return a << n;
}
