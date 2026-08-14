; RUN: llc -march=lc2k -global-isel -verify-machineinstrs -stop-after=irtranslator < %s | FileCheck %s

; A call whose return value fits in RetCC_LC2K's single return register
; (unlike ir-translator-sret.ll) goes through the normal LC2KCallReturnHandler
; path instead of insertSRetLoads.
; CHECK-LABEL: name: caller
; CHECK: %2:_(p0) = G_GLOBAL_VALUE @inc
; CHECK: ADJCALLSTACKDOWN 0, 0, implicit-def $r14, implicit $r14
; CHECK: %3:gpr = COPY %2(p0)
; CHECK: $r1 = COPY %0(s32)
; CHECK: CALL %3, csr, implicit-def $r15, implicit $r1, implicit-def $r1
; CHECK: ADJCALLSTACKUP 0, 0, implicit-def $r14, implicit $r14
; CHECK: %1:_(s32) = COPY $r1
; CHECK: $r1 = COPY %1(s32)
; CHECK: $r0 = JALR killed $r15, implicit $r1
define i32 @inc(i32 %x) {
  %r = add i32 %x, 1
  ret i32 %r
}

define i32 @caller(i32 %x) {
  %r = call i32 @inc(i32 %x)
  ret i32 %r
}
