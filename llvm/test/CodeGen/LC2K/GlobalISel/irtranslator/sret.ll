; RUN: llc -march=lc2k -global-isel -verify-machineinstrs -stop-after=irtranslator < %s | FileCheck %s

; A 4-field struct return doesn't fit in RetCC_LC2K's single return register,
; so it gets demoted to a hidden sret pointer argument. inner is the callee:
; it receives that pointer as its only formal argument (in R1) and stores
; each field through it instead of returning normally.
%s4 = type { i32, i32, i32, i32 }

; CHECK-LABEL: name: inner
; CHECK: liveins: $r1
; CHECK: %0:_(p0) = COPY $r1
; CHECK: %1:_(s32) = G_CONSTANT i32 1
; CHECK: %2:_(s32) = G_CONSTANT i32 2
; CHECK: %3:_(s32) = G_CONSTANT i32 3
; CHECK: %4:_(s32) = G_CONSTANT i32 4
; CHECK: G_STORE %1(s32), %0(p0) :: (store (s32), align 8)
; CHECK: %6:_(s32) = G_CONSTANT i32 4
; CHECK: %5:_(p0) = nuw inbounds G_PTR_ADD %0, %6(s32)
; CHECK: G_STORE %2(s32), %5(p0) :: (store (s32))
; CHECK: %8:_(s32) = G_CONSTANT i32 8
; CHECK: %7:_(p0) = nuw inbounds G_PTR_ADD %0, %8(s32)
; CHECK: G_STORE %3(s32), %7(p0) :: (store (s32), align 8)
; CHECK: %10:_(s32) = G_CONSTANT i32 12
; CHECK: %9:_(p0) = nuw inbounds G_PTR_ADD %0, %10(s32)
; CHECK: G_STORE %4(s32), %9(p0) :: (store (s32))
; CHECK: $r0 = JALR killed $r15
define %s4 @inner() {
  ret %s4 { i32 1, i32 2, i32 3, i32 4 }
}

; outer is the caller: it allocates a stack buffer for the hidden pointer,
; passes its address in R1 as the call's only argument, and reads the
; result back out of that buffer after the call returns.
; CHECK-LABEL: name: outer
; CHECK: stack:
; CHECK: size: 16
; CHECK: %4:_(p0) = G_FRAME_INDEX %stack.0
; CHECK: %5:_(p0) = G_GLOBAL_VALUE @inner
; CHECK: ADJCALLSTACKDOWN 0, 0, implicit-def $r14, implicit $r14
; CHECK: %6:gpr = COPY %5(p0)
; CHECK: $r1 = COPY %4(p0)
; CHECK: CALL %6, csr, implicit-def $r15, implicit $r1
; CHECK: ADJCALLSTACKUP 0, 0, implicit-def $r14, implicit $r14
; CHECK: %0:_(s32) = G_LOAD %4(p0) :: (load (s32) from %stack.0, align 8)
; CHECK: $r1 = COPY %0(s32)
; CHECK: $r0 = JALR killed $r15, implicit $r1
define i32 @outer() {
  %s = call %s4 @inner()
  %f0 = extractvalue %s4 %s, 0
  ret i32 %f0
}
