;; An unknown CPU gets no features from LLVM, so it has no instruction encoding
;; and must be rejected.

; RUN: not llc < %s -mtriple=lc2k -mcpu=invalidcpu 2>&1 | FileCheck %s

; CHECK: 'invalidcpu' is not a recognized processor for this target
; CHECK: LLVM ERROR: LC2K: exactly one instruction encoding feature (enc-470, enc-phobos) must be enabled; got 0 for CPU 'invalidcpu'

define void @f() {
  ret void
}
