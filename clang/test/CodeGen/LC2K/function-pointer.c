// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

int add(int a, int b) { return a + b; }
int sub(int a, int b) { return a - b; }

int apply(int (*fn)(int, int), int a, int b) {
  return fn(a, b);
}

int call_add(int a, int b) {
  int (*fp)(int, int) = add;
  return fp(a, b);
}

typedef int (*BinOp)(int, int);

int dispatch(int which, int a, int b) {
  BinOp ops[2] = { add, sub };
  return ops[which](a, b);
}
