; RUN: llc -mtriple=lc2k -mcpu=eecs470 -O2 < %s \
; RUN:   | FileCheck %s --check-prefixes=CHECK,EECS470
; RUN: llc -mtriple=lc2k -mcpu=phobos -O2 < %s \
; RUN:   | FileCheck %s --check-prefixes=CHECK,PHOBOS

; A bitwise NOT (xor with all-ones) should be a single NAND(x, x), not a -1
; materialization plus the general four-NAND XOR circuit.

define i32 @not_rhs(i32 %x) {
; CHECK-LABEL: not_rhs
; CHECK-NEXT:  nand 1 1 1
; EECS470-NEXT: jalr 15 2
; PHOBOS-NEXT:  jalr 15 0
  %r = xor i32 %x, -1
  ret i32 %r
}

; Constant on the left-hand side (llc runs no InstCombine to canonicalize it).
; FIXME: This should also be a single NAND. TableGen rejects patterns with an
; immediate on the LHS of a commutative operator, and LC2K has no GISel
; combiner to canonicalize constants to the RHS (commute_constant_to_rhs), so
; this still falls through to the general XOR pattern.
define i32 @not_lhs(i32 %x) {
; CHECK-LABEL: not_lhs
; CHECK-NEXT:  addi 0 {{[0-9]+}} -1
; CHECK-COUNT-4: nand
; EECS470-NEXT: jalr 15 2
; PHOBOS-NEXT:  jalr 15 0
  %r = xor i32 -1, %x
  ret i32 %r
}

; ~(a | b) must still use the more specific single-NOR pattern. phobos has
; no NOR, so it is OR's three-NAND fallback plus the NOT.
define i32 @nor(i32 %a, i32 %b) {
; CHECK-LABEL: nor
; EECS470-NEXT: nor 1 2 1
; EECS470-NEXT: jalr 15 2
; PHOBOS-NEXT:  nand 2 2 2
; PHOBOS-NEXT:  nand 1 1 1
; PHOBOS-NEXT:  nand 1 2 1
; PHOBOS-NEXT:  nand 1 1 1
; PHOBOS-NEXT:  jalr 15 0
  %o = or i32 %a, %b
  %r = xor i32 %o, -1
  ret i32 %r
}

; A non-constant XOR still uses the general four-NAND circuit.
define i32 @xor(i32 %a, i32 %b) {
; CHECK-LABEL: xor
; CHECK-COUNT-4: nand
; EECS470-NEXT: jalr 15 2
; PHOBOS-NEXT:  jalr 15 0
  %r = xor i32 %a, %b
  ret i32 %r
}
