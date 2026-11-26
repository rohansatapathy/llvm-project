;; Stack frame adjustments and frame-index offsets must fit the CPU's signed
;; ADDI/LW/SW immediate: 20 bits on eecs470, 21 bits on phobos. A frame of
;; 600002 words fits only the latter.

; RUN: not llc < %s -mtriple=lc2k -mcpu=eecs470 2>&1 \
; RUN:   | FileCheck %s --check-prefix=EECS470
; RUN: llc < %s -mtriple=lc2k -mcpu=phobos 2>&1 \
; RUN:   | FileCheck %s --check-prefix=PHOBOS

; EECS470: LLVM ERROR: LC2K: stack frame size 600002 exceeds 20-bit ADDI immediate range

; PHOBOS:      big_frame addi 14 14 -600002
; PHOBOS-NEXT: sw 14 15 600001
; PHOBOS-NEXT: sw 14 8 600000
; PHOBOS:      lw 14 8 600000
; PHOBOS-NEXT: lw 14 15 600001
; PHOBOS-NEXT: addi 14 14 600002
; PHOBOS-NEXT: jalr 15 2

define i32 @big_frame(i32 %i) {
  %buf = alloca [600000 x i32]
  %p = getelementptr [600000 x i32], ptr %buf, i32 0, i32 %i
  store i32 %i, ptr %p
  %q = getelementptr [600000 x i32], ptr %buf, i32 0, i32 599999
  %v = load i32, ptr %q
  ret i32 %v
}
