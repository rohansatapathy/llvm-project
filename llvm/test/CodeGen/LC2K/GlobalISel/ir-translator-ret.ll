; RUN: llc -march=lc2k -global-isel -verify-machineinstrs -stop-after=irtranslator < %s | FileCheck %s

; CHECK: name: f
; CHECK: $r0 = JALR killed $r15
define void @f() {
  ret void
}
