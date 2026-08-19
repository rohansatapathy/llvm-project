// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

int truncate_from_long(long long x) {
  return (int)x;
}

long long widen_signed(int x) {
  return (long long)x;
}

unsigned int widen_unsigned(unsigned short x) {
  return (unsigned int)x;
}

int signed_to_unsigned(int x) {
  return (int)(unsigned int)x;
}

int char_to_int(char c) {
  return (int)c;
}

char int_to_char(int x) {
  return (char)x;
}

int *int_to_pointer(long addr) {
  return (int *)addr;
}

long pointer_to_int(int *p) {
  return (long)p;
}
