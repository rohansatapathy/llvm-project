// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

struct Point {
  int x;
  int y;
};

int designated_struct_init(void) {
  struct Point p = {.y = 2, .x = 1};
  return p.x + p.y;
}

int designated_array_init(void) {
  int arr[5] = {[4] = 10, [0] = 1};
  return arr[0] + arr[4];
}

struct Point compound_literal_sum(void) {
  return (struct Point){.x = 3, .y = 4};
}
