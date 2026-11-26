; RUN: llc -mtriple=lc2k -mcpu=eecs470 -O2 < %s | FileCheck %s --check-prefix=NOR
; RUN: llc -mtriple=lc2k -mcpu=phobos -O2 < %s | FileCheck %s --check-prefix=NAND

; OR and NOR use the NOR instruction when the CPU has it, and fall back to
; NAND-only sequences on CPUs without it (phobos).

define i32 @or_regs(i32 %a, i32 %b) {
; NOR-LABEL: or_regs
; NOR-NEXT:  nor 1 2 1
; NOR-NEXT:  nor 1 1 1
; NOR-NEXT:  jalr 15 2
;
; NAND-LABEL: or_regs
; NAND-NEXT:  nand 2 2 2
; NAND-NEXT:  nand 1 1 1
; NAND-NEXT:  nand 1 2 1
; NAND-NEXT:  jalr 15 0
  %r = or i32 %a, %b
  ret i32 %r
}

define i32 @nor_regs(i32 %a, i32 %b) {
; NOR-LABEL: nor_regs
; NOR-NEXT:  nor 1 2 1
; NOR-NEXT:  jalr 15 2
;
; NAND-LABEL: nor_regs
; NAND-NEXT:  nand 2 2 2
; NAND-NEXT:  nand 1 1 1
; NAND-NEXT:  nand 1 2 1
; NAND-NEXT:  nand 1 1 1
; NAND-NEXT:  jalr 15 0
  %o = or i32 %a, %b
  %r = xor i32 %o, -1
  ret i32 %r
}
