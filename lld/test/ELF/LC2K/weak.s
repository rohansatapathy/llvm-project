# A strong definition in another object overrides a weak one, and an
# undefined weak reference resolves to 0.

# RUN: rm -rf %t && split-file %s %t && cd %t
# RUN: llvm-mc --arch=lc2k --filetype=obj main.s -o main.o
# RUN: llvm-mc --arch=lc2k --filetype=obj strong.s -o strong.o

# RUN: ld.lld main.o -o weak.out 2>&1 | count 0
# RUN: llvm-readelf -s weak.out > weak.txt
# RUN: llvm-objdump -d weak.out >> weak.txt
# RUN: FileCheck %s --check-prefix=WEAK --input-file=weak.txt

## lw takes a word address, so it encodes val's byte address divided by 4.
# WEAK:      [[#%x,VAL:]] 0 NOTYPE WEAK DEFAULT [[#]] val
# WEAK:      00000000     0 NOTYPE WEAK DEFAULT UND missing
# WEAK:      lw 0 1 [[#%u,div(VAL,4)]]
# WEAK-NEXT: lw 0 2 0

# RUN: ld.lld main.o strong.o -o strong.out 2>&1 | count 0
# RUN: llvm-readelf -s strong.out > strong.txt
# RUN: llvm-objdump -d strong.out >> strong.txt
# RUN: FileCheck %s --check-prefix=STRONG --input-file=strong.txt

# STRONG:      [[#%x,VAL:]] 0 NOTYPE GLOBAL DEFAULT [[#]] val
# STRONG:      lw 0 1 [[#%u,div(VAL,4)]]
# STRONG-NEXT: lw 0 2 0

#--- main.s
        .globl  _start
_start  lw      0 1 val
        lw      0 2 missing
        halt
        .weak   val
val     .fill   1
        .weak   missing

#--- strong.s
        .globl  val
val     .fill   2
