;; LC2K compiles a whole module for one CPU. A function's "target-cpu" must
;; match it, with "" and "generic" treated as the default, eecs470.

; RUN: llc < %s -mtriple=lc2k 2>&1 | FileCheck %s
; RUN: llc < %s -mtriple=lc2k -mcpu=generic 2>&1 | FileCheck %s
; RUN: llc < %s -mtriple=lc2k -mcpu=eecs470 2>&1 | FileCheck %s
; RUN: not llc < %s -mtriple=lc2k -mcpu=phobos 2>&1 \
; RUN:   | FileCheck %s --check-prefix=PHOBOS

; CHECK-NOT: LLVM ERROR
; CHECK: empty_cpu jalr 15 1
; CHECK: generic_cpu jalr 15 1
; CHECK: eecs470_cpu jalr 15 1

; PHOBOS: LLVM ERROR: LC2K: function 'empty_cpu' has target-cpu 'eecs470', but the module is being compiled for 'phobos'; mixing CPUs in one module is not supported

define void @empty_cpu() "target-cpu"="" {
  ret void
}

define void @generic_cpu() "target-cpu"="generic" {
  ret void
}

define void @eecs470_cpu() "target-cpu"="eecs470" {
  ret void
}
