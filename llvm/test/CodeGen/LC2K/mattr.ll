;; LC2K features describe fixed hardware variants, so the only supported
;; configurations are the CPU presets. -mattr may restate features the CPU
;; already has, but not change them.

; RUN: llc < %s -mtriple=lc2k -mattr=+nor,+nand 2>&1 | FileCheck %s
; RUN: llc < %s -mtriple=lc2k -mcpu=phobos -mattr=+enc-phobos,-nor 2>&1 \
; RUN:   | FileCheck %s

; RUN: not llc < %s -mtriple=lc2k -mattr=-nor 2>&1 \
; RUN:   | FileCheck %s --check-prefix=NO-NOR
; RUN: not llc < %s -mtriple=lc2k -mattr=-enc-470 2>&1 \
; RUN:   | FileCheck %s --check-prefix=NO-ENC
; RUN: not llc < %s -mtriple=lc2k -mcpu=phobos -mattr=+enc-470,+nor 2>&1 \
; RUN:   | FileCheck %s --check-prefix=PHOBOS

; CHECK-NOT: LLVM ERROR
; CHECK: f jalr 15 1

; NO-NOR: LLVM ERROR: LC2K: changes individual target features (-nor) of CPU 'eecs470'; only the presets selected by -mcpu are supported
; NO-ENC: LLVM ERROR: LC2K: changes individual target features (-enc-470) of CPU 'eecs470'; only the presets selected by -mcpu are supported
; PHOBOS: LLVM ERROR: LC2K: changes individual target features (+enc-470,+nor) of CPU 'phobos'; only the presets selected by -mcpu are supported

define void @f() {
  ret void
}
