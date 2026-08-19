// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

union Value {
  int as_int;
  float as_float;
};

int union_as_int(union Value v) {
  return v.as_int;
}

union Value make_int_value(int x) {
  union Value v;
  v.as_int = x;
  return v;
}

int reinterpret_float_bits(float f) {
  union Value v;
  v.as_float = f;
  return v.as_int;
}
