;; With no -mcpu, or -mcpu=generic, LC2K must compile exactly as for eecs470
;; (an empty or unknown CPU would otherwise get no features at all). The
;; input exercises everything that currently depends on the CPU: NOR and NAND
;; patterns, a constant wider than the immediate, and a stack frame.

; RUN: llc -mtriple=lc2k < %s -o %t.default.s
; RUN: llc -mtriple=lc2k -mcpu=generic < %s -o %t.generic.s
; RUN: llc -mtriple=lc2k -mcpu=eecs470 < %s -o %t.eecs470.s
; RUN: diff %t.default.s %t.eecs470.s
; RUN: diff %t.generic.s %t.eecs470.s

;; Sanity check that the input is CPU-sensitive, so the diffs above are
;; meaningful.
; RUN: llc -mtriple=lc2k -mcpu=phobos < %s -o %t.phobos.s
; RUN: not diff %t.phobos.s %t.eecs470.s > /dev/null

define i32 @or_nor(i32 %a, i32 %b) {
  %o = or i32 %a, %b
  %n = xor i32 %o, -1
  %r = add i32 %o, %n
  ret i32 %r
}
define i32 @nand_ops(i32 %a, i32 %b) {
  %s = sub i32 %a, %b
  %x = xor i32 %s, %b
  %y = and i32 %x, %a
  ret i32 %y
}
define i32 @wide_const() {
  ret i32 12345678
}
define i32 @frame(i32 %i) {
  %buf = alloca [16 x i32]
  %p = getelementptr [16 x i32], ptr %buf, i32 0, i32 %i
  store i32 %i, ptr %p
  %q = getelementptr [16 x i32], ptr %buf, i32 0, i32 3
  %v = load i32, ptr %q
  ret i32 %v
}
