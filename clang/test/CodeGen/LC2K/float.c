// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

float add_float(float a, float b) {
  return a + b;
}

float mul_float(float a, float b) {
  return a * b;
}

int float_to_int(float a) {
  return (int)a;
}

float int_to_float(int a) {
  return (float)a;
}

int compare_float(float a, float b) {
  return a < b;
}
