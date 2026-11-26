# Unresolved I-type offsets use 20-bit relocations on eecs470 and 21-bit
# relocations on phobos.

# RUN: llvm-mc --arch=lc2k --filetype=obj -mcpu=eecs470 %s -o %t.eecs470.o
# RUN: llvm-readobj -r %t.eecs470.o | FileCheck %s --check-prefix=EECS470
# RUN: llvm-mc --arch=lc2k --filetype=obj -mcpu=phobos %s -o %t.phobos.o
# RUN: llvm-readobj -r %t.phobos.o | FileCheck %s --check-prefix=PHOBOS

# EECS470:      Section ({{.*}}) .rela.text {
# EECS470-NEXT:   0x0 R_LC2K_20 ext 0x0
# EECS470-NEXT:   0x4 R_LC2K_20 ext 0x0
# EECS470-NEXT:   0x8 R_LC2K_20 ext 0x0
# EECS470-NEXT:   0xC R_LC2K_20_PCPLUS1REL ext 0x0
# EECS470-NEXT: }
# EECS470-NEXT: Section ({{.*}}) .rela.data {
# EECS470-NEXT:   0x0 R_LC2K_32 ext 0x0
# EECS470-NEXT: }

# PHOBOS:       Section ({{.*}}) .rela.text {
# PHOBOS-NEXT:    0x0 R_LC2K_21 ext 0x0
# PHOBOS-NEXT:    0x4 R_LC2K_21 ext 0x0
# PHOBOS-NEXT:    0x8 R_LC2K_21 ext 0x0
# PHOBOS-NEXT:    0xC R_LC2K_21_PCPLUS1REL ext 0x0
# PHOBOS-NEXT:  }
# PHOBOS-NEXT:  Section ({{.*}}) .rela.data {
# PHOBOS-NEXT:    0x0 R_LC2K_32 ext 0x0
# PHOBOS-NEXT:  }

        lw      0 1 ext
        sw      0 1 ext
        addi    0 1 ext
        beq     0 1 ext
        halt
ptr     .fill   ext
