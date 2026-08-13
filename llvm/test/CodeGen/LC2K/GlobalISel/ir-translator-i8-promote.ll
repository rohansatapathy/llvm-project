; RUN: llc -march=lc2k -global-isel -verify-machineinstrs -stop-after=irtranslator < %s | FileCheck %s

; i8 arguments/returns get promoted to i32 by CC_LC2K/RetCC_LC2K's
; CCPromoteToType<i32> rule. zeroext/signext attributes should produce the
; matching G_ASSERT_ZEXT/G_ASSERT_SEXT hint on the way in, and the matching
; extend op on the way out.
; CHECK-LABEL: name: f
; CHECK: liveins: $r1, $r2
; CHECK: %2:_(s32) = COPY $r1
; CHECK: %3:_(s32) = G_ASSERT_ZEXT %2, 8
; CHECK: %0:_(s8) = G_TRUNC %3(s32)
; CHECK: %4:_(s32) = COPY $r2
; CHECK: %5:_(s32) = G_ASSERT_SEXT %4, 8
; CHECK: %1:_(s8) = G_TRUNC %5(s32)
; CHECK: %6:_(s8) = G_ADD %0, %1
; CHECK: %7:_(s32) = G_ZEXT %6(s8)
; CHECK: $r1 = COPY %7(s32)
; CHECK: $r0 = JALR killed $r15, implicit $r1
define zeroext i8 @f(i8 zeroext %a, i8 signext %b) {
  %r = add i8 %a, %b
  ret i8 %r
}
