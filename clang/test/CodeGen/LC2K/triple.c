// RUN: %clang_cc1 %s -triple lc2k-unknown-none -emit-llvm -o - | FileCheck %s

// CHECK: target triple = "lc2k-unknown-none"
void foo() {}
