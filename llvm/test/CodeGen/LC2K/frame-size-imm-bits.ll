;; Stack frame adjustments and frame-index offsets must fit the CPU's signed
;; ADDI/LW/SW immediate: 20 bits on eecs470, 21 bits on phobos. A frame of
;; 600000+ words fits only the latter.

; RUN: not llc < %s -mtriple=lc2k -mcpu=eecs470 2>&1 \
; RUN:   | FileCheck %s --check-prefix=EECS470
; RUN: llc < %s -mtriple=lc2k -mcpu=phobos 2>&1 \
; RUN:   | FileCheck %s --check-prefix=PHOBOS

; EECS470: LLVM ERROR: LC2K: stack frame size 600002 exceeds 20-bit ADDI immediate range

;; On phobos the 599999-word offset also folds into the lw, so the function
;; makes no __lc2k_shl call and needs no return-address spill.
; PHOBOS:      big_frame addi 14 14 -600000
; PHOBOS-NEXT: addi 14 2 0
; PHOBOS-NEXT: add 2 1 2
; PHOBOS-NEXT: sw 2 1 0
; PHOBOS-NEXT: lw 14 1 599999
; PHOBOS-NEXT: addi 14 14 600000
; PHOBOS-NEXT: jalr 15 2

define i32 @big_frame(i32 %i) {
  %buf = alloca [600000 x i32]
  %p = getelementptr [600000 x i32], ptr %buf, i32 0, i32 %i
  store i32 %i, ptr %p
  %q = getelementptr [600000 x i32], ptr %buf, i32 0, i32 599999
  %v = load i32, ptr %q
  ret i32 %v
}
