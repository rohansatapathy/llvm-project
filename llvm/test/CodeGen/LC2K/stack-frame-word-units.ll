; LC2K is word-addressable (DataLayout b:32), so every stack slot -- spill
; slots, callee-saved register slots, and stack-passed arguments -- must be
; one word, and stack offsets must count words. Regression test for frames
; that were sized in 8-bit bytes (4 units per 32-bit register).

; RUN: llc -mtriple=lc2k < %s | FileCheck %s
; RUN: llc -mtriple=lc2k -O0 < %s | FileCheck %s --check-prefix=O0

declare i32 @g(i32, i32, i32, i32, i32)

; Callee-saved registers, incoming stack args, and an outgoing stack arg.
; Frame = 1 outgoing-arg word + 7 callee-saved words (r8-r13, r15) = 8 words.
; CHECK-LABEL: {{^}}f addi 14 14 -8
; CHECK-NEXT: sw 14 15 7
; CHECK-NEXT: sw 14 8 6
; CHECK-NEXT: sw 14 9 5
; CHECK-NEXT: sw 14 10 4
; CHECK-NEXT: sw 14 11 3
; CHECK-NEXT: sw 14 12 2
; CHECK-NEXT: sw 14 13 1
; Incoming stack args %e and %f6 sit just above the 8-word frame.
; CHECK:      lw 14 12 8
; CHECK-NEXT: lw 14 13 9
; The 5th outgoing argument to @g goes in the word at the bottom of the frame.
; CHECK:      sw 14 12 0
; CHECK-NEXT: jalr 5 15
; CHECK:      lw 14 15 7
; CHECK-NEXT: addi 14 14 8
; CHECK-NEXT: jalr 15 2
define i32 @f(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f6) {
  %r = call i32 @g(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e)
  %s1 = add i32 %r, %a
  %s2 = add i32 %s1, %b
  %s3 = add i32 %s2, %c
  %s4 = add i32 %s3, %d
  %s5 = add i32 %s4, %e
  %s6 = add i32 %s5, %f6
  ret i32 %s6
}

; Register-allocator spill slots: at -O0, %x and %y are spilled across the
; branch, giving a 2-word frame with slots at offsets 0 and 1.
; O0-LABEL: {{^}}spills addi 14 14 -2
; O0:      sw 14 4 0
; O0:      sw 14 1 1
; O0:      lw 14 1 0
; O0-NEXT: lw 14 2 1
; O0:      addi 14 14 2
define i32 @spills(i32 %a, i32 %b, i1 %c) {
entry:
  %x = add i32 %a, %b
  %y = sub i32 %a, %b
  br i1 %c, label %t, label %e
t:
  br label %e
e:
  %z = add i32 %x, %y
  ret i32 %z
}
