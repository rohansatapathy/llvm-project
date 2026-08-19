// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

struct Point {
  int x;
  int y;
};

int sum_point(struct Point p) {
  return p.x + p.y;
}

struct Point make_point(int x, int y) {
  struct Point p;
  p.x = x;
  p.y = y;
  return p;
}

struct Point add_points(struct Point a, struct Point b) {
  struct Point r;
  r.x = a.x + b.x;
  r.y = a.y + b.y;
  return r;
}
