; RUN: llc -march=lc2k -global-isel -verify-machineinstrs -stop-after=irtranslator < %s | FileCheck %s

; A call with more than 4 arguments must spill the overflow arguments to the
; stack (via LC2KOutgoingArgHandler::getStackAddress), and reserve that space
; with a nonzero ADJCALLSTACKDOWN/UP.
; CHECK-LABEL: name: caller
; CHECK: %6:_(p0) = G_GLOBAL_VALUE @callee
; CHECK: ADJCALLSTACKDOWN 4, 0, implicit-def $r14, implicit $r14
; CHECK: %7:gpr = COPY %6(p0)
; CHECK: %8:_(p0) = COPY $r14
; CHECK: %9:_(s32) = G_CONSTANT i32 0
; CHECK: %10:_(p0) = G_PTR_ADD %8, %9(s32)
; CHECK: G_STORE %5(s32), %10(p0) :: (store (s32) into stack)
; CHECK: $r1 = COPY %1(s32)
; CHECK: $r2 = COPY %2(s32)
; CHECK: $r3 = COPY %3(s32)
; CHECK: $r4 = COPY %4(s32)
; CHECK: CALL %7, csr, implicit-def $r15, implicit $r1, implicit $r2, implicit $r3, implicit $r4, implicit-def $r1
; CHECK: ADJCALLSTACKUP 4, 0, implicit-def $r14, implicit $r14
define i32 @callee(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e) {
  ret i32 %e
}

define i32 @caller() {
  %r = call i32 @callee(i32 1, i32 2, i32 3, i32 4, i32 5)
  ret i32 %r
}
