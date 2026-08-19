// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

int sum_volatile(int n, int step) {
  volatile int i;
  int total = 0;
  for (i = 0; i != n; i = i + step) {
    total += i;
  }
  return total;
}
