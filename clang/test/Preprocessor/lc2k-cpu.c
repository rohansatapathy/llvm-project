// Each LC2K CPU defines a macro naming it.

// RUN: %clang_cc1 -triple lc2k -E -dM %s -o - | FileCheck %s --check-prefix=EECS470 --implicit-check-not=__LC2K_CPU_
// RUN: %clang_cc1 -triple lc2k -target-cpu eecs470 -E -dM %s -o - | FileCheck %s --check-prefix=EECS470 --implicit-check-not=__LC2K_CPU_
// RUN: %clang_cc1 -triple lc2k -target-cpu generic -E -dM %s -o - | FileCheck %s --check-prefix=EECS470 --implicit-check-not=__LC2K_CPU_
// RUN: %clang_cc1 -triple lc2k -target-cpu phobos -E -dM %s -o - | FileCheck %s --check-prefix=PHOBOS --implicit-check-not=__LC2K_CPU_

// EECS470: #define __LC2K_CPU_EECS470__ 1
// PHOBOS:  #define __LC2K_CPU_PHOBOS__ 1
