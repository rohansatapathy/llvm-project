//===-- LC2KLegalizerInfo.h -------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file declares the targeting of the LegalizerInfo class for LC2K.
///
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LC2K_GISEL_LC2KLEGALIZERINFO_H
#define LLVM_LIB_TARGET_LC2K_GISEL_LC2KLEGALIZERINFO_H

#include "llvm/CodeGen/GlobalISel/LegalizerInfo.h"

namespace llvm {

class LC2KSubtarget;

class LC2KLegalizerInfo : public LegalizerInfo {
public:
  LC2KLegalizerInfo(const LC2KSubtarget &ST);

  bool legalizeCustom(LegalizerHelper &Helper, MachineInstr &MI,
                      LostDebugLocObserver &LocObserver) const override;

private:
  bool legalizeShift(LegalizerHelper &Helper, MachineInstr &MI,
                     LostDebugLocObserver &LocObserver) const;
  bool legalizeICmp(LegalizerHelper &Helper, MachineInstr &MI,
                    LostDebugLocObserver &LocObserver) const;
  bool legalizeVAStart(LegalizerHelper &Helper, MachineInstr &MI) const;
  bool legalizeExt(LegalizerHelper &Helper, MachineInstr &MI) const;
  bool legalizeTrunc(LegalizerHelper &Helper, MachineInstr &MI) const;
  bool legalizeFConstant(LegalizerHelper &Helper, MachineInstr &MI) const;
  bool legalizeBRJT(LegalizerHelper &Helper, MachineInstr &MI) const;
  bool legalizeConstant(LegalizerHelper &Helper, MachineInstr &MI,
                        LostDebugLocObserver &LocObserver) const;
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_LC2K_GISEL_LC2KLEGALIZERINFO_H
