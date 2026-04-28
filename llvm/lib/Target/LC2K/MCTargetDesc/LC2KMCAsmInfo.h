//===-- LC2KMCAsmInfo.h - LC2K Asm Info -------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file contains the declarations of the LC2K MCAsmInfo properties.
///
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LC2K_MCTARGETDESC_LC2KMCASMINFO_H
#define LLVM_LIB_TARGET_LC2K_MCTARGETDESC_LC2KMCASMINFO_H

#include "llvm/MC/MCAsmInfoELF.h"

namespace llvm {

class LC2KELFMCAsmInfo : public MCAsmInfoELF {
  void anchor() override;

public:
  explicit LC2KELFMCAsmInfo(const Triple &Triple);
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_LC2K_MCTARGETDESC_LC2KMCASMINFO_H
