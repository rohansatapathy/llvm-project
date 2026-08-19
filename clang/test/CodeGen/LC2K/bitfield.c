// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

struct Flags {
  unsigned a : 1;
  unsigned b : 3;
  unsigned c : 4;
};

int read_flags(struct Flags f) {
  return f.a + f.b + f.c;
}

struct Flags make_flags(unsigned a, unsigned b, unsigned c) {
  struct Flags f;
  f.a = a;
  f.b = b;
  f.c = c;
  return f;
}
