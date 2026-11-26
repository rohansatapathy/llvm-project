; RUN: llc -mtriple=lc2k -mcpu=eecs470 -O2 < %s | FileCheck %s --check-prefix=EECS470
; RUN: llc -mtriple=lc2k -mcpu=phobos -O2 < %s | FileCheck %s --check-prefix=PHOBOS

; A constant that fits the signed immediate field (20 bits on eecs470, 21 on
; phobos) is a single ADDI. Wider ones are split into Hi << ImmBits plus a
; sign-extended ImmBits-wide Lo, with the shift done by __lc2k_shl.

; EECS470-LABEL: c_524287
; EECS470-NEXT:  addi 0 1 524287
; EECS470-NEXT:  jalr 15 2
;
; PHOBOS-LABEL: c_524287
; PHOBOS-NEXT:  addi 0 1 524287
; PHOBOS-NEXT:  jalr 15 2
define i32 @c_524287() {
  ret i32 524287
}

; EECS470-LABEL: c_m524288
; EECS470-NEXT:  addi 0 1 -524288
; EECS470-NEXT:  jalr 15 2
;
; PHOBOS-LABEL: c_m524288
; PHOBOS-NEXT:  addi 0 1 -524288
; PHOBOS-NEXT:  jalr 15 2
define i32 @c_m524288() {
  ret i32 -524288
}

; EECS470-LABEL: c_524288
; EECS470:       addi 0 1 1
; EECS470-NEXT:  addi 0 2 20
; EECS470-NEXT:  addi 0 3 __lc2k_shl
; EECS470-NEXT:  jalr 3 15
; EECS470-NEXT:  addi 0 2 -524288
; EECS470-NEXT:  add 1 2 1
;
; PHOBOS-LABEL: c_524288
; PHOBOS-NEXT:  addi 0 1 524288
; PHOBOS-NEXT:  jalr 15 2
define i32 @c_524288() {
  ret i32 524288
}

; EECS470-LABEL: c_m524289
; EECS470:       addi 0 1 4095
; EECS470-NEXT:  addi 0 2 20
; EECS470-NEXT:  addi 0 3 __lc2k_shl
; EECS470-NEXT:  jalr 3 15
; EECS470-NEXT:  addi 0 2 524287
; EECS470-NEXT:  add 1 2 1
;
; PHOBOS-LABEL: c_m524289
; PHOBOS-NEXT:  addi 0 1 -524289
; PHOBOS-NEXT:  jalr 15 2
define i32 @c_m524289() {
  ret i32 -524289
}

; EECS470-LABEL: c_1048575
; EECS470:       addi 0 1 1
; EECS470-NEXT:  addi 0 2 20
; EECS470-NEXT:  addi 0 3 __lc2k_shl
; EECS470-NEXT:  jalr 3 15
; EECS470-NEXT:  addi 0 2 -1
; EECS470-NEXT:  add 1 2 1
;
; PHOBOS-LABEL: c_1048575
; PHOBOS-NEXT:  addi 0 1 1048575
; PHOBOS-NEXT:  jalr 15 2
define i32 @c_1048575() {
  ret i32 1048575
}

; EECS470-LABEL: c_m1048576
; EECS470:       addi 0 1 4095
; EECS470-NEXT:  addi 0 2 20
; EECS470-NEXT:  addi 0 3 __lc2k_shl
; EECS470-NEXT:  jalr 3 15
; EECS470-NEXT:  addi 0 2 0
; EECS470-NEXT:  add 1 2 1
;
; PHOBOS-LABEL: c_m1048576
; PHOBOS-NEXT:  addi 0 1 -1048576
; PHOBOS-NEXT:  jalr 15 2
define i32 @c_m1048576() {
  ret i32 -1048576
}

; EECS470-LABEL: c_1048576
; EECS470:       addi 0 1 1
; EECS470-NEXT:  addi 0 2 20
; EECS470-NEXT:  addi 0 3 __lc2k_shl
; EECS470-NEXT:  jalr 3 15
; EECS470-NEXT:  addi 0 2 0
; EECS470-NEXT:  add 1 2 1
;
; PHOBOS-LABEL: c_1048576
; PHOBOS:       addi 0 1 1
; PHOBOS-NEXT:  addi 0 2 21
; PHOBOS-NEXT:  addi 0 3 __lc2k_shl
; PHOBOS-NEXT:  jalr 3 15
; PHOBOS-NEXT:  addi 0 2 -1048576
; PHOBOS-NEXT:  add 1 2 1
define i32 @c_1048576() {
  ret i32 1048576
}

; EECS470-LABEL: c_m1048577
; EECS470:       addi 0 1 4095
; EECS470-NEXT:  addi 0 2 20
; EECS470-NEXT:  addi 0 3 __lc2k_shl
; EECS470-NEXT:  jalr 3 15
; EECS470-NEXT:  addi 0 2 -1
; EECS470-NEXT:  add 1 2 1
;
; PHOBOS-LABEL: c_m1048577
; PHOBOS:       addi 0 1 2047
; PHOBOS-NEXT:  addi 0 2 21
; PHOBOS-NEXT:  addi 0 3 __lc2k_shl
; PHOBOS-NEXT:  jalr 3 15
; PHOBOS-NEXT:  addi 0 2 1048575
; PHOBOS-NEXT:  add 1 2 1
define i32 @c_m1048577() {
  ret i32 -1048577
}

; EECS470-LABEL: c_2147483647
; EECS470:       addi 0 1 2048
; EECS470-NEXT:  addi 0 2 20
; EECS470-NEXT:  addi 0 3 __lc2k_shl
; EECS470-NEXT:  jalr 3 15
; EECS470-NEXT:  addi 0 2 -1
; EECS470-NEXT:  add 1 2 1
;
; PHOBOS-LABEL: c_2147483647
; PHOBOS:       addi 0 1 1024
; PHOBOS-NEXT:  addi 0 2 21
; PHOBOS-NEXT:  addi 0 3 __lc2k_shl
; PHOBOS-NEXT:  jalr 3 15
; PHOBOS-NEXT:  addi 0 2 -1
; PHOBOS-NEXT:  add 1 2 1
define i32 @c_2147483647() {
  ret i32 2147483647
}

; EECS470-LABEL: c_m2147483648
; EECS470:       addi 0 1 2048
; EECS470-NEXT:  addi 0 2 20
; EECS470-NEXT:  addi 0 3 __lc2k_shl
; EECS470-NEXT:  jalr 3 15
; EECS470-NEXT:  addi 0 2 0
; EECS470-NEXT:  add 1 2 1
;
; PHOBOS-LABEL: c_m2147483648
; PHOBOS:       addi 0 1 1024
; PHOBOS-NEXT:  addi 0 2 21
; PHOBOS-NEXT:  addi 0 3 __lc2k_shl
; PHOBOS-NEXT:  jalr 3 15
; PHOBOS-NEXT:  addi 0 2 0
; PHOBOS-NEXT:  add 1 2 1
define i32 @c_m2147483648() {
  ret i32 -2147483648
}
