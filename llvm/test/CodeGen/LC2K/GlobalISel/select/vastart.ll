; RUN: llc -march=lc2k -global-isel -verify-machineinstrs -stop-after=instruction-select < %s | FileCheck %s

declare void @llvm.va_start.p0(ptr)

; The legalized G_FRAME_INDEX (fixed-stack.0, the vararg-region marker) is
; materialized with ADDI (selectFrameIndex), and the G_STORE's destination
; address operand (%stack.0.ap, the va_list's own storage) is folded
; directly into SW's addressing mode by appendAddrOperands rather than
; needing a separate address-materializing instruction.
; CHECK-LABEL: name: f
; CHECK: %3:gpr = ADDI %fixed-stack.0, 0
; CHECK: SW %3, %stack.0.ap, 0
define void @f(i32 %a, ...) {
entry:
  %ap = alloca ptr, align 4
  call void @llvm.va_start.p0(ptr %ap)
  ret void
}
