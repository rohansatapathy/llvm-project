;; A function with "target-cpu"="phobos" compiles only when the module is
;; compiled for phobos.

; RUN: llc < %s -mtriple=lc2k -mcpu=phobos 2>&1 | FileCheck %s
; RUN: not llc < %s -mtriple=lc2k 2>&1 | FileCheck %s --check-prefix=DEFAULT
; RUN: not llc < %s -mtriple=lc2k -mcpu=eecs470 2>&1 \
; RUN:   | FileCheck %s --check-prefix=DEFAULT

; CHECK-NOT: LLVM ERROR
; CHECK: phobos_cpu jalr 15 0

; DEFAULT: LLVM ERROR: LC2K: function 'phobos_cpu' has target-cpu 'phobos', but the module is being compiled for 'eecs470'; mixing CPUs in one module is not supported

define void @phobos_cpu() "target-cpu"="phobos" {
  ret void
}
