// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

enum Color { RED, GREEN, BLUE };

int color_to_int(enum Color c) {
  return (int)c;
}

enum Color next_color(enum Color c) {
  if (c == BLUE) return RED;
  return (enum Color)(c + 1);
}

int is_green(enum Color c) {
  switch (c) {
  case GREEN: return 1;
  default: return 0;
  }
}
