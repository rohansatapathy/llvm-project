; RUN: llc -march=lc2k -global-isel -verify-machineinstrs -stop-after=legalizer < %s | FileCheck %s

declare void @llvm.va_start.p0(ptr)

; G_VASTART is custom-legalized (see LC2KLegalizerInfo::legalizeVAStart): it
; builds a G_FRAME_INDEX for the fixed-stack marker slot
; LC2KCallLowering::lowerFormalArguments reserved as the start of the
; vararg region (LC2KMachineFunctionInfo::VarArgsFrameIndex), then stores
; that address into the va_list's own storage (%stack.0.ap here).
; CHECK-LABEL: name: f
; CHECK: %2:_(p0) = G_FRAME_INDEX %stack.0.ap
; CHECK: %3:_(p0) = G_FRAME_INDEX %fixed-stack.0
; CHECK: G_STORE %3(p0), %2(p0) :: (store (p0))
define void @f(i32 %a, ...) {
entry:
  %ap = alloca ptr, align 4
  call void @llvm.va_start.p0(ptr %ap)
  ret void
}
