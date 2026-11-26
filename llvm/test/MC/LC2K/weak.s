# .weak gives a symbol weak binding, for definitions in .text and .data and
# for undefined references. It can come before or after the definition.

# RUN: llvm-mc --arch=lc2k --filetype=obj %s -o %t.o
# RUN: llvm-readelf -s %t.o | FileCheck %s

# CHECK-DAG: NOTYPE WEAK   DEFAULT {{[0-9]+}} func
# CHECK-DAG: NOTYPE WEAK   DEFAULT {{[0-9]+}} after
# CHECK-DAG: NOTYPE GLOBAL DEFAULT {{[0-9]+}} strong
# CHECK-DAG: NOTYPE WEAK   DEFAULT {{[0-9]+}} data
# CHECK-DAG: NOTYPE WEAK   DEFAULT UND ref

        .weak   func
func    lw      0 1 ref
        jalr    15 2
after   halt
        .weak   after
        .globl  strong
strong  halt
        .weak   data
data    .fill   5
        .weak   ref
