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

  // Hi/lo halves of a PSEUDO_LA-expanded wide address: hi12 targets the
  // first ADDI's immediate (the word address's top 12 bits,
  // rounding-compensated so (hi << 20) + lo reconstructs it exactly -- see
  // LC2KAsmBackend::adjustFixupValue), lo20 targets the trailing ADDI's
  // immediate (the low 20 bits, always representable as a signed 20-bit
  // value by construction, so unlike fixup_lc2k_20 this can never
  // overflow).
  fixup_lc2k_hi12,
  fixup_lc2k_lo20,

  // Marker
  LastTargetFixupKind,
  NumTargetFixupKinds = LastTargetFixupKind - FirstTargetFixupKind
};
} // namespace LC2K
} // namespace llvm

#endif // LLVM_LIB_TARGET_LC2K_MCTARGETDESC_LC2KFIXUPKINDS_H
