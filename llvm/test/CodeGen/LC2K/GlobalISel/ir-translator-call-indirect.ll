; RUN: llc -march=lc2k -global-isel -verify-machineinstrs -stop-after=irtranslator < %s | FileCheck %s

; An indirect call through a function-pointer value takes the Info.Callee
; isReg() path, unlike the isGlobal()/G_GLOBAL_VALUE path a direct call to a
; named function uses.
; CHECK-LABEL: name: caller
; CHECK: liveins: $r1
; CHECK: %0:_(p0) = COPY $r1
; CHECK: ADJCALLSTACKDOWN 0, 0, implicit-def $r14, implicit $r14
; CHECK: %2:gpr = COPY %0(p0)
; CHECK: CALL %2, csr, implicit-def $r15, implicit-def $r1
; CHECK: ADJCALLSTACKUP 0, 0, implicit-def $r14, implicit $r14
define i32 @caller(ptr %fp) {
  %r = call i32 %fp()
  ret i32 %r
}
