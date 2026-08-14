; RUN: llc -march=lc2k -global-isel < %s | FileCheck %s

; Regression test: emitting more than one global variable used to crash the
; LC2K asm streamer. Scalar initializers reach the streamer through
; MCStreamer::emitIntValue(), whose default implementation calls emitBytes(),
; which LC2KAsmStreamer does not override. That silently dropped the
; initializer and left the pending label buffered, so the *next* label
; (either the following global, or end-of-stream) tripped
; "Cannot emit two labels in a row" / "Dangling label".

; CHECK: .globl g1
; CHECK-NEXT: g1 .fill 1
@g1 = global i32 1

; CHECK-NEXT: .globl g2
; CHECK-NEXT: g2 .fill 2
@g2 = global i32 2

; CHECK-NEXT: .globl g3
; CHECK-NEXT: g3 .fill 0
@g3 = global i32 0
