// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

int goto_loop(int n) {
  int total = 0;
  int i = 0;
loop_start:
  if (i >= n) goto loop_end;
  total += i;
  i++;
  goto loop_start;
loop_end:
  return total;
}
