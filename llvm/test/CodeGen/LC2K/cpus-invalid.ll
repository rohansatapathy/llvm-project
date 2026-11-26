;; An unknown CPU gets no features from LLVM and must be rejected.

; RUN: not llc < %s -mtriple=lc2k -mcpu=invalidcpu 2>&1 | FileCheck %s

; CHECK: 'invalidcpu' is not a recognized processor for this target
; CHECK: LLVM ERROR: LC2K: unknown CPU 'invalidcpu'; use -mcpu=help to list valid CPUs

define void @f() {
  ret void
}
