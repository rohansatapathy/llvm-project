// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

int deref(int *p) {
  return *p;
}

void increment_through_pointer(int *p) {
  *p = *p + 1;
}

int sum_via_pointer_arith(int *p, int n) {
  int total = 0;
  for (int i = 0; i < n; i++) {
    total += *(p + i);
  }
  return total;
}

int double_deref(int **pp) {
  return **pp;
}

int pointer_diff(int *a, int *b) {
  return (int)(a - b);
}
