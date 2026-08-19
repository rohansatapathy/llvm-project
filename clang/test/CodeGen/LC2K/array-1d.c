// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

int sum_array(int arr[], int n) {
  int total = 0;
  for (int i = 0; i < n; i++) {
    total += arr[i];
  }
  return total;
}

void fill_array(int arr[], int n, int value) {
  for (int i = 0; i < n; i++) {
    arr[i] = value;
  }
}

int local_array_sum(void) {
  int arr[8];
  for (int i = 0; i < 8; i++) {
    arr[i] = i * 2;
  }
  int total = 0;
  for (int i = 0; i < 8; i++) {
    total += arr[i];
  }
  return total;
}
