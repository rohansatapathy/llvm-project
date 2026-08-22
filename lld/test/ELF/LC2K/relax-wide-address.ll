; Regression test: codegen always emits PSEUDO_LA's wide (hi-ADDI + 20
; doubling ADDs + lo-ADDI, R_LC2K_HI12/R_LC2K_LO20) form for any symbolic
; address, since a symbol's final address is never known until link time
; (even for a same-object-file reference -- ELF sections have no final
; address until the linker places them either). The linker
; (LC2K::relaxOnce/finalizeRelax, lld/ELF/Arch/LC2K.cpp) is what shrinks
; it back down to a single ADDI once it can see the real address fits --
; this checks that shrink actually happens for an externally-resolved
; symbol (only known at link time), and that it stays wide when the
; address genuinely doesn't fit.

; RUN: llc -mtriple=lc2k -filetype=obj %s -o %t.o

; A small address: shrinks to a single ADDI with base register R0.
; RUN: ld.lld %t.o --defsym big=400 -o %t
; RUN: llvm-objdump -d %t | FileCheck %s --check-prefix=SMALL
; SMALL: <foo>:
; SMALL-NEXT: addi 0 1 100
; SMALL-NEXT: jalr 15 0

; A large address: doesn't fit, stays as the full wide sequence.
; RUN: ld.lld %t.o --defsym big=6000000 -o %t2
; RUN: llvm-objdump -d %t2 | FileCheck %s --check-prefix=WIDE
; WIDE: <foo>:
; WIDE-NEXT: addi 0 1 {{.*}}
; WIDE-COUNT-20: add 1 1 1
; WIDE-NEXT: addi 1 1 {{.*}}
; WIDE-NEXT: jalr 15 0

@big = external global i32

define ptr @foo() {
  ret ptr @big
}
