# The output's e_flags record the CPU of the inputs. Objects for different
# CPUs use different instruction encodings and cannot be linked together.

# RUN: rm -rf %t && split-file %s %t && cd %t
# RUN: llvm-mc --arch=lc2k --filetype=obj main.s -o main.eecs470.o
# RUN: llvm-mc --arch=lc2k --filetype=obj lib.s -o lib.eecs470.o
# RUN: llvm-mc --arch=lc2k --filetype=obj -mcpu=phobos main.s -o main.phobos.o
# RUN: llvm-mc --arch=lc2k --filetype=obj -mcpu=phobos lib.s -o lib.phobos.o

# RUN: ld.lld main.eecs470.o lib.eecs470.o -o eecs470.out
# RUN: llvm-readobj -h eecs470.out | FileCheck %s --check-prefix=EECS470
# RUN: llvm-objdump -d eecs470.out | FileCheck %s --check-prefix=DIS-EECS470

# EECS470:      Flags [ (0x0)
# EECS470-NEXT: ]

# DIS-EECS470:      03 00 20 01 add 1 2 3
# DIS-EECS470:      03 00 20 91 nand 1 2 3

## llvm-objdump picks the phobos disassembler from e_flags; no --mcpu needed.
# RUN: ld.lld main.phobos.o lib.phobos.o -o phobos.out
# RUN: llvm-readobj -h phobos.out | FileCheck %s --check-prefix=PHOBOS
# RUN: llvm-objdump -d phobos.out | FileCheck %s --check-prefix=DIS-PHOBOS

# PHOBOS:      Flags [ (0x1)
# PHOBOS-NEXT:   EF_LC2K_MACH_PHOBOS (0x1)
# PHOBOS-NEXT: ]

# DIS-PHOBOS:      03 00 40 02 add 1 2 3
# DIS-PHOBOS:      03 00 40 22 nand 1 2 3

# RUN: not ld.lld main.eecs470.o lib.phobos.o -o /dev/null 2>&1 | FileCheck %s --check-prefix=MIX1 --implicit-check-not=error:
# MIX1: error: lib.phobos.o: cannot link object files with different LC2K CPUs: phobos is incompatible with eecs470 (main.eecs470.o)

# RUN: not ld.lld main.phobos.o lib.eecs470.o -o /dev/null 2>&1 | FileCheck %s --check-prefix=MIX2 --implicit-check-not=error:
# MIX2: error: lib.eecs470.o: cannot link object files with different LC2K CPUs: eecs470 is incompatible with phobos (main.phobos.o)

#--- main.s
        .globl  _start
_start  add     1 2 3

#--- lib.s
lib     nand    1 2 3
