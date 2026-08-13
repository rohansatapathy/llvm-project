; RUN: llc -march=lc2k -global-isel -verify-machineinstrs -stop-after=irtranslator < %s | FileCheck %s

; CHECK: name: f
; CHECK: liveins: $r1, $r2, $r3, $r4
; CHECK: %0:_(s32) = COPY $r1
; CHECK: %1:_(s32) = COPY $r2
; CHECK: %2:_(s32) = COPY $r3
; CHECK: %3:_(s32) = COPY $r4
; CHECK: %5:_(p0) = G_FRAME_INDEX %fixed-stack.0
; CHECK: %4:_(s32) = G_LOAD %5(p0) :: (load (s32) from %fixed-stack.0)
; CHECK: $r1 = COPY %4(s32)
; CHECK: $r0 = JALR killed $r15, implicit $r1
define i32 @f(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e) {
  ret i32 %e
}
