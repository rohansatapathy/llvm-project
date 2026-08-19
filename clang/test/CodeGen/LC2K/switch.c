// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

int dense_switch(int x) {
  switch (x) {
  case 0: return 10;
  case 1: return 20;
  case 2: return 30;
  case 3: return 40;
  default: return -1;
  }
}

int sparse_switch(int x) {
  switch (x) {
  case 1: return 1;
  case 100: return 2;
  case 10000: return 3;
  default: return 0;
  }
}

int fallthrough_switch(int x) {
  int result = 0;
  switch (x) {
  case 0:
  case 1:
    result += 1;
    // fallthrough
  case 2:
    result += 2;
    break;
  default:
    result = -1;
  }
  return result;
}
