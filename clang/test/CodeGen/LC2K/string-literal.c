// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

const char *greeting(void) {
  return "hello";
}

char first_char(void) {
  static const char msg[] = "world";
  return msg[0];
}

int string_length(const char *s) {
  int len = 0;
  while (s[len] != '\0') {
    len++;
  }
  return len;
}
