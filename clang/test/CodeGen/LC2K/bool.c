// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

#include <stdbool.h>

bool is_positive(int x) {
  return x > 0;
}

int bool_to_int(bool b) {
  return (int)b;
}

bool logical_and(bool a, bool b) {
  return a && b;
}

bool logical_or(bool a, bool b) {
  return a || b;
}

bool logical_not(bool a) {
  return !a;
}
