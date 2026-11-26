; RUN: llc -mtriple=lc2k -O2 -align-all-blocks=4 -filetype=obj < %s \
; RUN:   | llvm-objdump -d - | FileCheck %s
; RUN: llc -mtriple=lc2k -mcpu=phobos -O2 -align-all-blocks=4 -filetype=obj \
; RUN:   < %s | llvm-objdump -d -z --mcpu=phobos - \
; RUN:   | FileCheck %s --check-prefix=PHOBOS

; Code-alignment padding is filled by LC2KAsmBackend::writeNopData. Each
; padding word must be a real `noop` (opcode 0b0111 in bits 31-28, i.e.
; 0x70000000, stored little-endian as 70 at the highest byte). This used to be
; written byte-reversed (00 00 00 07 == 0x07000000), which decodes as
; `add 7 0 0` and clobbers R0 with R7 whenever the padding is executed.
;
; Assembly-level alignment directives aren't supported by the LC2K assembler
; and LC2K disables function alignment, so block alignment is used to force
; padding into the object file.
;
; Phobos has no NOOP opcode, so its padding is `add 0 0 0` (all zeros; R0 is
; hardwired to zero there, so this is a true no-op).

define i32 @f(i32 %a, i32 %b) {
; CHECK-LABEL: <f>:
; CHECK:      beq 2 1 3
; CHECK-NEXT: beq 0 0 6
; CHECK-NEXT: 00 00 00 70 noop
; CHECK-NEXT: 00 00 00 70 noop
; CHECK-NEXT: jalr 15 2
; CHECK-NEXT: 00 00 00 70 noop
; CHECK-NEXT: 00 00 00 70 noop
; CHECK-NEXT: 00 00 00 70 noop
; CHECK-NEXT: add 2 0 1
; CHECK-NEXT: jalr 15 2
; CHECK-NOT:  add 7 0 0

; PHOBOS-LABEL: <f>:
; PHOBOS:      beq 2 1 3
; PHOBOS-NEXT: beq 0 0 6
; PHOBOS-NEXT: 00 00 00 00 add 0 0 0
; PHOBOS-NEXT: 00 00 00 00 add 0 0 0
; PHOBOS-NEXT: jalr 15 2
; PHOBOS-NEXT: 00 00 00 00 add 0 0 0
; PHOBOS-NEXT: 00 00 00 00 add 0 0 0
; PHOBOS-NEXT: 00 00 00 00 add 0 0 0
; PHOBOS-NEXT: add 2 0 1
; PHOBOS-NEXT: jalr 15 2
entry:
  %c = icmp eq i32 %a, %b
  br i1 %c, label %t, label %e
t:
  ret i32 %a
e:
  ret i32 %b
}
