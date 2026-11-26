;; Exactly one instruction encoding feature must be enabled.

; RUN: not llc < %s -mtriple=lc2k -mattr=-enc-470 2>&1 \
; RUN:   | FileCheck %s --check-prefix=NONE
; RUN: not llc < %s -mtriple=lc2k -mcpu=phobos -mattr=+enc-470 2>&1 \
; RUN:   | FileCheck %s --check-prefix=BOTH

; NONE: LLVM ERROR: LC2K: exactly one instruction encoding feature (enc-470, enc-phobos) must be enabled; got 0 for CPU 'eecs470'
; BOTH: LLVM ERROR: LC2K: exactly one instruction encoding feature (enc-470, enc-phobos) must be enabled; got 2 for CPU 'phobos'

define void @f() {
  ret void
}
