// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s
//
int sizeof_char(void) {
  return (int)sizeof(char);
}

int sizeof_short(void) {
  return (int)sizeof(short);
}

int sizeof_int(void) {
  return (int)sizeof(int);
}

int sizeof_long(void) {
  return (int)sizeof(long);
}

int sizeof_longlong(void) {
  return (int)sizeof(long);
}
