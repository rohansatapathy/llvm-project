// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

int ptr_to_int(int *p) {
  return (int)p;
}

int *int_to_ptr(int addr) {
  return (int *)addr;
}

int roundtrip(int *p) {
  int addr = (int)p;
  int *p2 = (int *)addr;
  return *p2;
}
