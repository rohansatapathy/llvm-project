; RUN: llc -mtriple=lc2k -mcpu=eecs470 -O2 -verify-machineinstrs < %s \
; RUN:   | FileCheck %s --check-prefix=EECS470
; RUN: llc -mtriple=lc2k -mcpu=phobos -O2 -verify-machineinstrs < %s \
; RUN:   | FileCheck %s --check-prefix=PHOBOS

; Returns and indirect branches are JALRs whose return-address write is
; discarded. phobos hardwires R0 to zero, so the write goes to R0. eecs470
; does not, so it goes to a scratch register that must not hold the return
; value.

define i32 @ret_value(i32 %a, i32 %b) {
; EECS470-LABEL: ret_value
; EECS470-NEXT:  add 1 2 1
; EECS470-NEXT:  jalr 15 2
;
; PHOBOS-LABEL: ret_value
; PHOBOS-NEXT:  add 1 2 1
; PHOBOS-NEXT:  jalr 15 0
  %s = add i32 %a, %b
  ret i32 %s
}

define void @ret_void() {
; EECS470-LABEL: ret_void
; EECS470-NEXT:  jalr 15 {{[1-9][0-9]*}}
;
; PHOBOS-LABEL: ret_void
; PHOBOS-NEXT:  jalr 15 0
  ret void
}

define void @indirect(ptr %p) {
; EECS470-LABEL: indirect
; EECS470-NEXT:  jalr 1 {{[1-9][0-9]*}}
;
; PHOBOS-LABEL: indirect
; PHOBOS-NEXT:  jalr 1 0
  indirectbr ptr %p, [label %a, label %b]
a:
  ret void
b:
  ret void
}
