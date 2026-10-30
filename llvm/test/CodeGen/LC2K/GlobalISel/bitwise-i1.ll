; i1 and/or/xor of two comparisons (what clang emits for `a == b && b == c`
; and friends at -O1 and above) must make it through instruction selection.
; RUN: llc -mtriple=lc2k -global-isel -verify-machineinstrs -stop-after=instruction-select < %s | FileCheck %s

; CHECK-LABEL: name: logical_and
; CHECK-NOT: G_AND
define i32 @logical_and(i32 %a, i32 %b, i32 %c) {
  %x = icmp eq i32 %a, %b
  %y = icmp eq i32 %b, %c
  %z = and i1 %x, %y
  %r = zext i1 %z to i32
  ret i32 %r
}

; CHECK-LABEL: name: logical_or
; CHECK-NOT: G_OR
define i32 @logical_or(i32 %a, i32 %b, i32 %c) {
  %x = icmp eq i32 %a, %b
  %y = icmp eq i32 %b, %c
  %z = or i1 %x, %y
  %r = zext i1 %z to i32
  ret i32 %r
}

; CHECK-LABEL: name: logical_xor
; CHECK-NOT: G_XOR
define i32 @logical_xor(i32 %a, i32 %b, i32 %c) {
  %x = icmp eq i32 %a, %b
  %y = icmp eq i32 %b, %c
  %z = xor i1 %x, %y
  %r = zext i1 %z to i32
  ret i32 %r
}
