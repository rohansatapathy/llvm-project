// The CPU is recorded on every function, and -mcpu=phobos produces a phobos
// object (ELF header flags).

// RUN: %clang_cc1 -triple lc2k -mrelocation-model static -target-cpu eecs470 -emit-llvm %s -o - | FileCheck %s -DCPU=eecs470
// RUN: %clang_cc1 -triple lc2k -mrelocation-model static -target-cpu phobos -emit-llvm %s -o - | FileCheck %s -DCPU=phobos

// CHECK: define {{.*}} @f() [[ATTRS:#[0-9]+]]
// CHECK: attributes [[ATTRS]] = { {{.*}}"target-cpu"="[[CPU]]"

// RUN: %clang --target=lc2k -c %s -o %t.eecs470.o
// RUN: llvm-readobj -h %t.eecs470.o | FileCheck %s --check-prefix=OBJ-EECS470
// RUN: %clang --target=lc2k -mcpu=phobos -c %s -o %t.phobos.o
// RUN: llvm-readobj -h %t.phobos.o | FileCheck %s --check-prefix=OBJ-PHOBOS

// OBJ-EECS470:      Flags [ (0x0)
// OBJ-EECS470-NEXT: ]
// OBJ-PHOBOS:       Flags [ (0x1)
// OBJ-PHOBOS-NEXT:    EF_LC2K_MACH_PHOBOS (0x1)

int f(void) { return 0; }
