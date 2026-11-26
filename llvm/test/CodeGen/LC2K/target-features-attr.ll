;; A function's "target-features" may restate features of the CPU preset (in
;; any order), but may not change them.
;;
;; llc appends -mattr to every function's "target-features", and -mattr is
;; itself checked against the preset (mattr.ll), so these mismatches come from
;; the IR attributes alone.

; RUN: split-file %s %t

; RUN: llc < %t/same.ll -mtriple=lc2k 2>&1 | FileCheck %s --check-prefix=SAME
; RUN: not llc < %t/no-nor.ll -mtriple=lc2k 2>&1 \
; RUN:   | FileCheck %s --check-prefix=NO-NOR
; RUN: not llc < %t/multi.ll -mtriple=lc2k 2>&1 \
; RUN:   | FileCheck %s --check-prefix=MULTI

; SAME-NOT: LLVM ERROR
; SAME: empty_fs jalr 15 1
; SAME: redundant_fs jalr 15 1
; SAME: reordered_fs jalr 15 1
; SAME: no_fs jalr 15 1

; NO-NOR: LLVM ERROR: LC2K: function 'no_nor' changes individual target features (-nor) of CPU 'eecs470'; only the presets selected by -mcpu are supported
; MULTI: LLVM ERROR: LC2K: function 'multi' changes individual target features (+enc-phobos,+hardwired-r0,-noop-instr) of CPU 'eecs470'; only the presets selected by -mcpu are supported

;--- same.ll
define void @empty_fs() "target-features"="" {
  ret void
}

define void @redundant_fs() "target-features"="+nand,+nor" {
  ret void
}

define void @reordered_fs() "target-features"="+nor,+nand" {
  ret void
}

define void @no_fs() {
  ret void
}

;--- no-nor.ll
define void @no_nor() "target-features"="-nor" {
  ret void
}

;--- multi.ll
define void @multi() "target-features"="+hardwired-r0,-noop-instr,+enc-phobos" {
  ret void
}
