# Phobos has no NOOP opcode, so `noop` is a pseudo for `add 0 0 0` (encoded
# as all zeros). eecs470 keeps its NOOP opcode.

# RUN: llvm-mc --arch=lc2k --filetype=obj -mcpu=phobos %s -o %t.phobos.o
# RUN: llvm-objdump -d --mcpu=phobos %t.phobos.o | FileCheck %s --check-prefix=PHOBOS
# RUN: llvm-mc --arch=lc2k --filetype=obj -mcpu=eecs470 %s -o %t.eecs470.o
# RUN: llvm-objdump -d --mcpu=eecs470 %t.eecs470.o \
# RUN:   | FileCheck %s --check-prefix=EECS470

# PHOBOS:       00 00 00 00 add 0 0 0
# EECS470:      00 00 00 70 noop
        noop
# PHOBOS:       <label>:
# PHOBOS-NEXT:  00 00 00 00 add 0 0 0
# EECS470:      <label>:
# EECS470-NEXT: 00 00 00 70 noop
label   noop
# PHOBOS-NEXT:  00 00 00 c0 halt
# EECS470-NEXT: 00 00 00 60 halt
        halt
