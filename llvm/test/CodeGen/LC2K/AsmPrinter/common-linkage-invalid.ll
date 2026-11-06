; LC2K assembly has no .comm equivalent, so common linkage is rejected rather
; than being turned into a definition that can't merge at link time. This
; catches what Clang's -fcommon check can't, such as __attribute__((common)).

; RUN: not llc -march=lc2k -global-isel < %s 2>&1 | FileCheck %s
; RUN: not llc -march=lc2k -global-isel -filetype=obj < %s -o /dev/null 2>&1 \
; RUN:   | FileCheck %s

; CHECK: LLVM ERROR: LC2K: common linkage is not supported (global 'e')
@e = common global i32 0
