# RUN: not llvm-mc --arch=lc2k %s -o /dev/null 2>&1 \
# RUN:   | FileCheck %s --implicit-check-not=error:

# CHECK: [[#@LINE+1]]:15: error: expected label after .weak
        .weak 5
# CHECK: [[#@LINE+1]]:14: error: expected label after .weak
        .weak
