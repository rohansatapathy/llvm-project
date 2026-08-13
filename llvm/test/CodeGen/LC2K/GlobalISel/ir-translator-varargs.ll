; RUN: llc -march=lc2k -global-isel -verify-machineinstrs -stop-after=irtranslator < %s | FileCheck %s

; CC_LC2K's register-assignment rule is gated by CCIfNotVarArg, so for a
; variadic function every argument -- including fixed ones before the `...`
; -- goes to the stack instead of a register.
; CHECK-LABEL: name: void_ret
; CHECK: %1:_(p0) = G_FRAME_INDEX %fixed-stack.0
; CHECK: %0:_(s32) = G_LOAD %1(p0) :: (load (s32) from %fixed-stack.0)
; CHECK: $r0 = JALR killed $r15
define void @void_ret(i32 %a, ...) {
  ret void
}

; Unlike CC_LC2K's argument-register rule, RetCC_LC2K's register rule is NOT
; CCIfNotVarArg-gated, so the return value's location doesn't depend on
; whether the function is variadic: %a itself still goes to the stack (it's
; an argument), but the return value normally goes through R1, with no sret
; demotion.
; CHECK-LABEL: name: i32_ret
; CHECK: %1:_(p0) = G_FRAME_INDEX %fixed-stack.0
; CHECK: %0:_(s32) = G_LOAD %1(p0) :: (load (s32) from %fixed-stack.0)
; CHECK: $r1 = COPY %0(s32)
; CHECK: $r0 = JALR killed $r15, implicit $r1
define i32 @i32_ret(i32 %a, ...) {
  ret i32 %a
}
