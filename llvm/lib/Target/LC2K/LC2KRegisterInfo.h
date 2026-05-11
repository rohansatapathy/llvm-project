//===- LC2KRegisterInfo.h - LC2K Register Information Impl ------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the LC2K implementation of the TargetRegisterInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LC2K_LC2KREGISTERINFO_H
#define LLVM_LIB_TARGET_LC2K_LC2KREGISTERINFO_H

#include "LC2KFrameLowering.h"
#include "MCTargetDesc/LC2KMCTargetDesc.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/CodeGen/TargetRegisterInfo.h"
#include "llvm/MC/MCRegister.h"

#define GET_REGINFO_HEADER
#include "LC2KGenRegisterInfo.inc"

namespace llvm {

namespace LC2K {

static const MCPhysReg SP = R14;
static const MCPhysReg RA = R15;

} // namespace LC2K

class LC2KRegisterInfo : public LC2KGenRegisterInfo {
public:
  LC2KRegisterInfo();

  const MCPhysReg *getCalleeSavedRegs(const MachineFunction *MF) const override;

  BitVector getReservedRegs(const MachineFunction &MF) const override;

  bool eliminateFrameIndex(MachineBasicBlock::iterator MI, int SPAdj,
                           unsigned FIOperandNum,
                           RegScavenger *RS = nullptr) const override;

  Register getFrameRegister(const MachineFunction &MF) const override;
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_LC2K_LC2KREGISTERINFO_H
