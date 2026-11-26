;; Weak definitions and extern_weak declarations are printed as .weak, and keep
;; weak binding whether the object is written directly or assembled from the
;; printed text.

; RUN: llc -mtriple=lc2k < %s | FileCheck %s --check-prefix=ASM
; RUN: llc -mtriple=lc2k -filetype=obj < %s | llvm-readelf -s - \
; RUN:   | FileCheck %s --check-prefix=SYMS
; RUN: llc -mtriple=lc2k < %s | llvm-mc --arch=lc2k --filetype=obj \
; RUN:   | llvm-readelf -s - | FileCheck %s --check-prefix=SYMS

; ASM:      .weak wf
; ASM-NEXT: wf
; ASM:      .weak wodr
; ASM-NEXT: wodr
; ASM:      .weak lodr
; ASM-NEXT: lodr
; ASM:      .globl use
; ASM-NEXT: use
; ASM:      .weak wg
; ASM-NEXT: wg .fill 7
; ASM:      .weak ew

; SYMS-DAG: WEAK   DEFAULT {{[0-9]+}} wf
; SYMS-DAG: WEAK   DEFAULT {{[0-9]+}} wodr
; SYMS-DAG: WEAK   DEFAULT {{[0-9]+}} lodr
; SYMS-DAG: GLOBAL DEFAULT {{[0-9]+}} use
; SYMS-DAG: WEAK   DEFAULT {{[0-9]+}} wg
; SYMS-DAG: WEAK   DEFAULT UND ew

define weak i32 @wf() {
  ret i32 1
}

define weak_odr i32 @wodr() {
  ret i32 2
}

define linkonce_odr i32 @lodr() {
  ret i32 3
}

@wg = weak global i32 7
@ew = extern_weak global i32

define i32 @use() {
  %a = call i32 @wf()
  %b = call i32 @wodr()
  %c = call i32 @lodr()
  %v = load i32, ptr @ew
  %s = add i32 %a, %b
  %t = add i32 %s, %c
  %u = add i32 %t, %v
  ret i32 %u
}
