// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

typedef __builtin_va_list va_list;
#define va_start(ap, last) __builtin_va_start(ap, last)
#define va_arg(ap, type) __builtin_va_arg(ap, type)
#define va_end(ap) __builtin_va_end(ap)

int sum_ints(int count, ...) {
  va_list ap;
  va_start(ap, count);
  int total = 0;
  for (int i = 0; i < count; i++) {
    total += va_arg(ap, int);
  }
  va_end(ap);
  return total;
}
