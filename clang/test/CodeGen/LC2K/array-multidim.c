// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

int sum_2d(int arr[4][4]) {
  int total = 0;
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      total += arr[i][j];
    }
  }
  return total;
}

int local_2d_array(void) {
  int grid[3][3];
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
      grid[i][j] = i * 3 + j;
    }
  }
  return grid[2][2];
}
