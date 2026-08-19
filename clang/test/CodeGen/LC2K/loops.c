// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

int for_loop(int n) {
  int total = 0;
  for (int i = 0; i < n; i++) {
    if (i == 3) continue;
    if (i == 8) break;
    total += i;
  }
  return total;
}

int while_loop(int n) {
  int total = 0;
  int i = 0;
  while (i < n) {
    total += i;
    i++;
  }
  return total;
}

int do_while_loop(int n) {
  int total = 0;
  int i = 0;
  do {
    total += i;
    i++;
  } while (i < n);
  return total;
}
