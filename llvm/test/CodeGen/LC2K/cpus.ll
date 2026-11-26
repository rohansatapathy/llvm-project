;; Check that llc accepts all valid LC2K CPUs, and that no CPU (or "generic")
;; falls back to eecs470 rather than a CPU with no features.

; RUN: llc < %s -mtriple=lc2k 2>&1 | FileCheck %s
; RUN: llc < %s -mtriple=lc2k -mcpu=generic 2>&1 | FileCheck %s
; RUN: llc < %s -mtriple=lc2k -mcpu=eecs470 2>&1 | FileCheck %s
; RUN: llc < %s -mtriple=lc2k -mcpu=phobos 2>&1 | FileCheck %s

; CHECK-NOT: is not a recognized processor for this target
; CHECK-NOT: LLVM ERROR

define void @f() {
  ret void
}
