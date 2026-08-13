; RUN: llc -march=lc2k -global-isel -verify-machineinstrs -stop-after=irtranslator < %s | FileCheck %s

; CHECK: name: f
; CHECK: liveins: $r1, $r2
; CHECK: %0:_(s32) = COPY $r1
; CHECK: %1:_(s32) = COPY $r2
; CHECK: %2:_(s32) = G_ADD %0, %1
; CHECK: $r1 = COPY %2(s32)
; CHECK: $r0 = JALR killed $r15, implicit $r1
define i32 @f(i32 %a, i32 %b) {
  %sum = add i32 %a, %b
  ret i32 %sum
}
