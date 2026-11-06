; RUN: llc -march=lc2k -global-isel < %s | FileCheck %s --check-prefix=ASM
; RUN: llc -march=lc2k -global-isel < %s | llvm-mc --arch=lc2k --filetype=obj \
; RUN:   | llvm-readelf -s - | FileCheck %s --check-prefix=OBJ
; RUN: llc -march=lc2k -global-isel -filetype=obj < %s \
; RUN:   | llvm-readelf -s - | FileCheck %s --check-prefix=OBJ

; Private symbols use the .L prefix, and the LC2K assembler parses it. They are
; temporary, so they stay out of the symbol table. A user symbol that merely
; starts with 'L' is not temporary and must stay in the symbol table.

@__const.f.a = private constant [2 x i32] [i32 1, i32 2]
@.str = private constant [2 x i32] [i32 104, i32 0]
@Lfoo = global i32 5

define ptr @f() {
; ASM-LABEL: f
; ASM: .L__const.f.a
  ret ptr @__const.f.a
}

define ptr @g() {
; ASM-LABEL: g
; ASM: .L.str
  ret ptr @.str
}

define i32 @h(i32 %x) {
; ASM-LABEL: h
; ASM: beq {{.*}} .LBB2_2
; ASM: .LBB2_2
entry:
  %c = icmp eq i32 %x, 0
  br i1 %c, label %a, label %b
a:
  ret i32 1
b:
  ret i32 2
}

; ASM: .L__const.f.a .fill 1
; ASM: .L.str .fill 104
; ASM: Lfoo .fill 5

; OBJ-NOT: .L
; OBJ-DAG: GLOBAL {{.*}} Lfoo
; OBJ-DAG: GLOBAL {{.*}} f
; OBJ-NOT: .L
