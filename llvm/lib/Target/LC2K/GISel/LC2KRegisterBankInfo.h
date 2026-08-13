//===-- LC2KRegisterBankInfo.h ----------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file declares the targeting of the RegisterBankInfo class for LC2K.
///
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LC2K_GISEL_LC2KREGISTERBANKINFO_H
#define LLVM_LIB_TARGET_LC2K_GISEL_LC2KREGISTERBANKINFO_H

#include "MCTargetDesc/LC2KMCTargetDesc.h"
#include "llvm/CodeGen/RegisterBankInfo.h"

#define GET_REGBANK_DECLARATIONS
#include "LC2KGenRegisterBank.inc"

namespace llvm {

class TargetRegisterInfo;

class LC2KGenRegisterBankInfo : public RegisterBankInfo {
protected:
#define GET_TARGET_REGBANK_CLASS
#include "LC2KGenRegisterBank.inc"
};

class LC2KRegisterBankInfo final : public LC2KGenRegisterBankInfo {
public:
  LC2KRegisterBankInfo(const TargetRegisterInfo &TRI);

  const InstructionMapping &
  getInstrMapping(const MachineInstr &MI) const override;
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_LC2K_GISEL_LC2KREGISTERBANKINFO_H
