; RUN: llc -march=lc2k -global-isel -verify-machineinstrs -stop-after=legalizer < %s | FileCheck %s

declare void @llvm.va_start.p0(ptr)

; G_VAARG has no LC2K-specific rule and falls through to .lower(): per
; LC2KLegalizerInfo.cpp its generic expansion is a load/round-up/advance/
; store/load sequence over G_LOAD, G_STORE, G_CONSTANT, and G_PTR_ADD, all
; already legal for {s32,p0}/{p0,p0}. The round-up step only emits a
; G_PTRMASK (which LC2K has no rule for) when the argument's alignment
; exceeds TLI.getMinStackArgumentAlignment(), which never happens for the
; word-aligned i32 here, so that step is elided and no G_PTRMASK appears.
; CHECK-LABEL: name: f
; CHECK: %2:_(p0) = G_FRAME_INDEX %stack.0.ap
; CHECK: %4:_(p0) = G_LOAD %2(p0)
; CHECK: %5:_(s32) = G_CONSTANT i32 4
; CHECK: %6:_(p0) = G_PTR_ADD %4, %5(s32)
; CHECK: G_STORE %6(p0), %2(p0)
; CHECK: %3:_(s32) = G_LOAD %4(p0)
define i32 @f(i32 %a, ...) {
entry:
  %ap = alloca ptr, align 4
  call void @llvm.va_start.p0(ptr %ap)
  %v = va_arg ptr %ap, i32
  ret i32 %v
}
