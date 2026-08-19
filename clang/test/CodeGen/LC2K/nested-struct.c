// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

struct Point {
  int x;
  int y;
};

struct Rect {
  struct Point top_left;
  struct Point bottom_right;
};

int rect_width(struct Rect r) {
  return r.bottom_right.x - r.top_left.x;
}

int rect_height(struct Rect r) {
  return r.bottom_right.y - r.top_left.y;
}

struct Rect make_rect(int x0, int y0, int x1, int y1) {
  struct Rect r;
  r.top_left.x = x0;
  r.top_left.y = y0;
  r.bottom_right.x = x1;
  r.bottom_right.y = y1;
  return r;
}
