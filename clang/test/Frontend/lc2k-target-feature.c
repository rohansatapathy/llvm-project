// Each LC2K CPU is a fixed feature set; changing individual features is an
// error rather than a backend crash. This includes restating a feature the
// CPU already has.

// RUN: not %clang_cc1 -triple lc2k -target-feature -nor -fsyntax-only %s 2>&1 | FileCheck %s -DFEAT=-nor
// RUN: not %clang_cc1 -triple lc2k -target-feature +nor -fsyntax-only %s 2>&1 | FileCheck %s -DFEAT=+nor
// RUN: not %clang_cc1 -triple lc2k -target-cpu phobos -target-feature +nor -fsyntax-only %s 2>&1 | FileCheck %s -DFEAT=+nor

// CHECK: error: changing target feature '[[FEAT]]' is not supported for this target; select a CPU with -mcpu instead
