; Wide symbol addresses (globals, external symbols, jump tables) are always
; materialized via PSEUDO_LA (see materializeSymbolAddress in
; LC2KInstructionSelector.cpp and PSEUDO_LA's doc comment in
; LC2KInstrInfo.td), since a symbol's real address is never known until
; link time and even a same-object-file reference can't be proven to fit a
; single ADDI until then either.
;
; This only has a representation via relocations (fixup_lc2k_hi12/
; fixup_lc2k_lo20), which only exist on the -filetype=obj path -- the
; plain positional text format LC2KAsmStreamer emits (-filetype=asm, meant
; for the course's own external assembler) has no way to spell "half of a
; symbol's address" at all, so it falls back to the original single-ADDI
; form instead (see LC2KAsmPrinter::emitInstruction).

; RUN: llc -mtriple=lc2k -filetype=asm %s -o - | FileCheck %s --check-prefix=ASM
; RUN: llc -mtriple=lc2k -filetype=obj %s -o %t.o
; RUN: llvm-objdump -d %t.o | FileCheck %s --check-prefix=OBJ
; RUN: llvm-readobj -r %t.o | FileCheck %s --check-prefix=RELOCS

@g = global i32 42

define i32 @get() {
  %v = load i32, ptr @g
  ret i32 %v
}

; ASM: get addi 0 1 g
; ASM-NEXT: lw 1 1 0
; ASM-NEXT: jalr 15 0

; A single hi-ADDI, 20 doubling ADDs, and a trailing lo-ADDI, then the LW
; using the now-fully-materialized address as a plain register base.
; OBJ: <get>:
; OBJ-NEXT: addi 0 1 0
; OBJ-COUNT-20: add 1 1 1
; OBJ-NEXT: addi 1 1 0
; OBJ-NEXT: lw 1 1 0
; OBJ-NEXT: jalr 15 0

; RELOCS: R_LC2K_HI12 g
; RELOCS-NEXT: R_LC2K_LO20 g
