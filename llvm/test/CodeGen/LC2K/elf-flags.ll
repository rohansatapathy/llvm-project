; llc records the CPU in the ELF header flags of object files.

; RUN: llc -mtriple=lc2k -filetype=obj %s -o - \
; RUN:   | llvm-readelf -h - | FileCheck %s --check-prefix=EECS470
; RUN: llc -mtriple=lc2k -mcpu=eecs470 -filetype=obj %s -o - \
; RUN:   | llvm-readelf -h - | FileCheck %s --check-prefix=EECS470
; RUN: llc -mtriple=lc2k -mcpu=phobos -filetype=obj %s -o - \
; RUN:   | llvm-readelf -h - | FileCheck %s --check-prefix=PHOBOS

; EECS470: Flags: 0x0{{$}}
; PHOBOS:  Flags: 0x1, phobos

define void @f() {
  ret void
}
