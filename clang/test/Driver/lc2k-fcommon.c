// LC2K has no common symbols, so -fcommon is rejected.

// RUN: not %clang -### --target=lc2k -c -fcommon %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=ERR
// ERR: error: unsupported option '-fcommon' for target 'lc2k'

// The last flag wins, as it does for other targets.
// RUN: not %clang -### --target=lc2k -c -fno-common -fcommon %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=ERR
// RUN: %clang -### --target=lc2k -c -fcommon -fno-common %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=OK
// RUN: %clang -### --target=lc2k -c %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=OK
// OK-NOT: error:
// OK-NOT: "-fcommon"

// The flag is still accepted on other targets.
// RUN: %clang -### --target=x86_64-unknown-linux-gnu -c -fcommon %s 2>&1 \
// RUN:   | FileCheck %s --check-prefix=OTHER
// OTHER-NOT: error:
// OTHER: "-fcommon"
