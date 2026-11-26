# Instructions the selected CPU doesn't implement are rejected.

# RUN: not llvm-mc --arch=lc2k -mcpu=phobos %s -o /dev/null 2>&1 \
# RUN:   | FileCheck %s --implicit-check-not=error:
# RUN: llvm-mc --arch=lc2k -mcpu=eecs470 %s -o /dev/null

# CHECK: [[#@LINE+1]]:9: error: instruction requires: nor
        nor     1 2 3
# CHECK: [[#@LINE+1]]:9: error: instruction requires: nor
label   nor     1 2 3
