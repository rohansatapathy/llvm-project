// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

struct Mixed {
  char c;
  int i;
  char c2;
};

int sizeof_int(void) {
  return (int)sizeof(int);
}

int sizeof_mixed_struct(void) {
  return (int)sizeof(struct Mixed);
}

int alignof_mixed_struct(void) {
  return (int)_Alignof(struct Mixed);
}

int offset_of_i(void) {
  struct Mixed m;
  return (int)((char *)&m.i - (char *)&m);
}
