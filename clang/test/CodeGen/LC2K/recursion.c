// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

int factorial(int n) {
  if (n <= 1) return 1;
  return n * factorial(n - 1);
}

int fib(int n) {
  if (n < 2) return n;
  return fib(n - 1) + fib(n - 2);
}
