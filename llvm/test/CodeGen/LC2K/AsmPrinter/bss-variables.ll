; RUN: llc -march=lc2k -global-isel < %s | FileCheck %s --check-prefix=ASM
; RUN: llc -march=lc2k -global-isel -filetype=obj < %s \
; RUN:   | llvm-readelf -sS - | FileCheck %s --check-prefix=OBJ

; Regression test for zero-initialized (.bss) globals. Corresponds to C like:
;
;   int a, b;           // external linkage, zero-initialized
;   static int c, d;    // internal linkage, zero-initialized
;   int arr[3];         // zero-initialized aggregate
;
; The LC2K DataLayout uses 32-bit "bytes" ('b:32'), so DataLayout sizes are in
; words while MCStreamer sizes are in 8-bit bytes. Zero-initialized globals
; that were lowered via .local/.comm (internal linkage) used to pass a word
; count where a byte count was expected, so each i32 got a 1-byte slot in .bss
; and overlapped its neighbors, while external globals in the same section
; correctly got 4 bytes each. In textual assembly those globals were dropped
; entirely, and zero-initialized aggregates crashed the streamer.

@a = global i32 0
@b = global i32 0
@c = internal global i32 0
@d = internal global i32 0
@arr = global [3 x i32] zeroinitializer

; Each global gets one .fill per word.
; ASM:      .globl a
; ASM-NEXT: a .fill 0
; ASM-NEXT: .globl b
; ASM-NEXT: b .fill 0
; ASM-NEXT: c .fill 0
; ASM-NEXT: d .fill 0
; ASM-NEXT: .globl arr
; ASM-NEXT: arr .fill 0
; ASM-NEXT: .fill 0
; ASM-NEXT: .fill 0
; ASM-NOT:  .fill

; All words of a, b, c, d, and arr live in .bss (7 words == 28 bytes).
; OBJ: .bss NOBITS {{[0-9a-f]+}} {{[0-9a-f]+}} 00001c
; OBJ-DAG: 00000008 4 OBJECT LOCAL DEFAULT {{[0-9]+}} c
; OBJ-DAG: 0000000c 4 OBJECT LOCAL DEFAULT {{[0-9]+}} d
; OBJ-DAG: 00000000 0 NOTYPE GLOBAL DEFAULT {{[0-9]+}} a
; OBJ-DAG: 00000004 0 NOTYPE GLOBAL DEFAULT {{[0-9]+}} b
; OBJ-DAG: 00000010 0 NOTYPE GLOBAL DEFAULT {{[0-9]+}} arr
