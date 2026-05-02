//===-- LC2KFixupKinds.h - LC2K Specific Fixup Entries ----------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LC2K_MCTARGETDESC_LC2KFIXUPKINDS_H
#define LLVM_LIB_TARGET_LC2K_MCTARGETDESC_LC2KFIXUPKINDS_H

#include "llvm/MC/MCFixup.h"

namespace llvm {
namespace LC2K {

enum Fixups {
  fixup_lc2k_none = FirstTargetFixupKind,
  fixup_lc2k_32,
  fixup_lc2k_20,
  fixup_lc2k_pcplus1rel,

  // Marker
  LastTargetFixupKind,
  NumTargetFixupKinds = LastTargetFixupKind - FirstTargetFixupKind
};
} // namespace LC2K
} // namespace llvm

#endif // LLVM_LIB_TARGET_LC2K_MCTARGETDESC_LC2KFIXUPKINDS_H
