; Regression test: a stack frame too large to fit ADDI's 20-bit immediate
; used to hit a bare assert (llvm_unreachable-style crash with no useful
; message in a Release build) in LC2KFrameLowering::emitPrologue/emitEpilogue
; and LC2KRegisterInfo::eliminateFrameIndex. This checks the clean
; reportFatalUsageError diagnostic added instead.

; RUN: not llc -mtriple=lc2k -filetype=asm %s -o /dev/null 2>&1 | FileCheck %s

; CHECK: LLVM ERROR: LC2K: stack frame size

define i32 @f() {
  %arr = alloca [600000 x i32]
  %p = getelementptr [600000 x i32], ptr %arr, i32 0, i32 599999
  %v = load i32, ptr %p
  ret i32 %v
}
