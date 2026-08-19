// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

double add_double(double a, double b) {
  return a + b;
}

double mul_double(double a, double b) {
  return a * b;
}

int double_to_int(double a) {
  return (int)a;
}

double int_to_double(int a) {
  return (double)a;
}

float double_to_float(double a) {
  return (float)a;
}
