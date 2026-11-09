// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-llvm -o - %s | FileCheck %s
// RUN: %clang_cc1 -triple lc2k-unknown-none -mrelocation-model static -emit-obj -o /dev/null %s

// LC2K is word-addressed, so a byte (char) is 32 bits wide. Every memset that
// clang emits must use the target byte type (i32) as its fill value, not i8.

// CHECK-NOT: @llvm.memset.{{.*}}(ptr {{.*}}, i8

struct Big {
  int a[40];
};

// Mostly-zero local aggregate: lowered to a memset of zero followed by stores.
// CHECK-LABEL: define {{.*}} @zero_local_array(
// CHECK: call void @llvm.memset.p0.i32(ptr {{.*}}, i32 0, i32 40, i1 false)
int zero_local_array(void) {
  int arr[40] = {0};
  return arr[3];
}

// Repeated byte pattern: lowered to a memset with a non-zero word fill value.
// CHECK-LABEL: define {{.*}} @pattern_local_array(
// CHECK: call void @llvm.memset.p0.i32(ptr {{.*}}, i32 -1, i32 40, i1 false)
int pattern_local_array(void) {
  int arr[40] = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                 -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                 -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
                 -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
  return arr[3];
}

// Zero-initialized aggregate assignment.
// CHECK-LABEL: define {{.*}} @zero_struct(
// CHECK: call void @llvm.memset.p0.i64(ptr {{.*}}, i32 0, i64 40, i1 false)
void zero_struct(struct Big *b) {
  *b = (struct Big){0};
}

// __builtin_memset truncates the fill value to a target byte (i32).
// CHECK-LABEL: define {{.*}} @builtin_memset(
// CHECK-NOT: trunc i32 {{.*}} to i8
// CHECK: call void @llvm.memset.p0.i32(ptr {{.*}}, i32 %{{.*}}, i32 %{{.*}}, i1 false)
void builtin_memset(int *p, int v, unsigned n) {
  __builtin_memset(p, v, n);
}

// CHECK-LABEL: define {{.*}} @builtin_bzero(
// CHECK: call void @llvm.memset.p0.i32(ptr {{.*}}, i32 0, i32 %{{.*}}, i1 false)
void builtin_bzero(int *p, unsigned n) {
  __builtin_bzero(p, n);
}
