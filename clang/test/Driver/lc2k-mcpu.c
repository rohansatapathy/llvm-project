// The driver always passes an LC2K CPU to cc1 and cc1as, defaulting to
// eecs470, so the IR and objects record it explicitly.

// RUN: %clang -### --target=lc2k -c %s 2>&1 | FileCheck %s --check-prefix=EECS470
// RUN: %clang -### --target=lc2k -mcpu=eecs470 -c %s 2>&1 | FileCheck %s --check-prefix=EECS470
// RUN: %clang -### --target=lc2k -mcpu=phobos -c %s 2>&1 | FileCheck %s --check-prefix=PHOBOS
// RUN: %clang -### --target=lc2k -mcpu=eecs470 -mcpu=phobos -c %s 2>&1 | FileCheck %s --check-prefix=PHOBOS

// "generic" is passed through as written; cc1 and the backend treat it as
// eecs470.
// RUN: %clang -### --target=lc2k -mcpu=generic -c %s 2>&1 | FileCheck %s --check-prefix=GENERIC

// The integrated assembler gets the CPU too.
// RUN: %clang -### --target=lc2k -c -x assembler %s 2>&1 | FileCheck %s --check-prefix=AS-EECS470
// RUN: %clang -### --target=lc2k -mcpu=phobos -c -x assembler %s 2>&1 | FileCheck %s --check-prefix=AS-PHOBOS

// EECS470:    "-cc1" {{.*}} "-target-cpu" "eecs470"
// PHOBOS:     "-cc1" {{.*}} "-target-cpu" "phobos"
// GENERIC:    "-cc1" {{.*}} "-target-cpu" "generic"
// AS-EECS470: "-cc1as" {{.*}} "-target-cpu" "eecs470"
// AS-PHOBOS:  "-cc1as" {{.*}} "-target-cpu" "phobos"

// The builtins are built once per CPU (see LLVM_BUILTIN_MULTILIBS), and the
// link uses the library for the selected CPU.
// RUN: %clang -### --target=lc2k-unknown-none %s 2>&1 | FileCheck %s --check-prefix=RT-EECS470
// RUN: %clang -### --target=lc2k-unknown-none -mcpu=generic %s 2>&1 | FileCheck %s --check-prefix=RT-EECS470
// RUN: %clang -### --target=lc2k-unknown-none -mcpu=phobos %s 2>&1 | FileCheck %s --check-prefix=RT-PHOBOS

// RT-EECS470: "{{[^"]*}}lc2k-unknown-none{{/|\\\\}}eecs470{{/|\\\\}}libclang_rt.builtins.a"
// RT-PHOBOS:  "{{[^"]*}}lc2k-unknown-none{{/|\\\\}}phobos{{/|\\\\}}libclang_rt.builtins.a"
