; RUN: llc -march=lc2k -global-isel -verify-machineinstrs -stop-after=irtranslator < %s | FileCheck %s

; CHECK: name: f
; CHECK: dead early-clobber %0:gpr = JALR killed $r15
define void @f() {
  ret void
}
