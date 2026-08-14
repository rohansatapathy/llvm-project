; RUN: llc -march=lc2k -global-isel -verify-machineinstrs -stop-after=irtranslator < %s | FileCheck %s

%s4 = type { i32, i32, i32, i32 }
%s6 = type { i32, i32, i32, i32, i32, i32 }

; A 4-field struct's fields all fit in the argument registers.
; CHECK-LABEL: name: four_field_struct
; CHECK: liveins: $r1, $r2, $r3, $r4
; CHECK: %0:_(s32) = COPY $r1
; CHECK: %1:_(s32) = COPY $r2
; CHECK: %2:_(s32) = COPY $r3
; CHECK: %3:_(s32) = COPY $r4
; CHECK: $r1 = COPY %0(s32)
; CHECK: $r0 = JALR killed $r15, implicit $r1
define i32 @four_field_struct(%s4 %s) {
  %f0 = extractvalue %s4 %s, 0
  ret i32 %f0
}

; A 6-field struct overflows the 4 argument registers, so the last two
; fields are spilled to the stack.
; CHECK-LABEL: name: six_field_struct
; CHECK: liveins: $r1, $r2, $r3, $r4
; CHECK: %0:_(s32) = COPY $r1
; CHECK: %1:_(s32) = COPY $r2
; CHECK: %2:_(s32) = COPY $r3
; CHECK: %3:_(s32) = COPY $r4
; CHECK: %6:_(p0) = G_FRAME_INDEX %fixed-stack.1
; CHECK: %4:_(s32) = G_LOAD %6(p0) :: (load (s32) from %fixed-stack.1)
; CHECK: %7:_(p0) = G_FRAME_INDEX %fixed-stack.0
; CHECK: %5:_(s32) = G_LOAD %7(p0) :: (load (s32) from %fixed-stack.0)
; CHECK: %8:_(s32) = G_ADD %0, %5
; CHECK: $r1 = COPY %8(s32)
; CHECK: $r0 = JALR killed $r15, implicit $r1
define i32 @six_field_struct(%s6 %s) {
  %f0 = extractvalue %s6 %s, 0
  %f5 = extractvalue %s6 %s, 5
  %sum = add i32 %f0, %f5
  ret i32 %sum
}
