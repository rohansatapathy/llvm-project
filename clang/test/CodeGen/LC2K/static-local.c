// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

int counter(void) {
  static int count = 0;
  count++;
  return count;
}

int accumulate(int x) {
  static int total = 0;
  total += x;
  return total;
}
