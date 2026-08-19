// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

int initialized_global = 42;
int zero_initialized_global;
static int internal_global = 7;

int read_globals(void) {
  return initialized_global + zero_initialized_global + internal_global;
}

void write_globals(int value) {
  initialized_global = value;
  zero_initialized_global = value * 2;
}

int increment_global(void) {
  return ++initialized_global;
}
