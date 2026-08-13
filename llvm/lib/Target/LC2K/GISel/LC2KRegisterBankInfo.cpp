//===-- LC2KRegisterBankInfo.cpp --------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file implements the targeting of the RegisterBankInfo class for
/// LC2K.
///
//===----------------------------------------------------------------------===//

#include "LC2KRegisterBankInfo.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/RegisterBank.h"
#include "llvm/CodeGen/TargetRegisterInfo.h"

#define DEBUG_TYPE "lc2k-reg-bank-info"

#define GET_TARGET_REGBANK_IMPL
#include "LC2KGenRegisterBank.inc"

using namespace llvm;

LC2KRegisterBankInfo::LC2KRegisterBankInfo(const TargetRegisterInfo &TRI)
    : LC2KGenRegisterBankInfo() {}

const RegisterBankInfo::InstructionMapping &
LC2KRegisterBankInfo::getInstrMapping(const MachineInstr &MI) const {
  // The generic implementation already knows how to map copy-like
  // instructions (COPY/PHI/REG_SEQUENCE) and instructions whose operands
  // have fixed register class constraints, so prefer it when it succeeds.
  const InstructionMapping &Mapping = getInstrMappingImpl(MI);
  if (Mapping.isValid())
    return Mapping;

  // Otherwise, fall back to mapping every register operand to GPRRegBank,
  // since LC2K has a single register class and a single register bank.
  const MachineRegisterInfo &MRI = MI.getMF()->getRegInfo();
  unsigned NumOperands = MI.getNumOperands();

  SmallVector<const ValueMapping *, 8> OpdsMapping(NumOperands);
  for (unsigned Idx = 0; Idx < NumOperands; ++Idx) {
    const MachineOperand &MO = MI.getOperand(Idx);
    if (!MO.isReg() || !MO.getReg())
      continue;

    LLT Ty = MRI.getType(MO.getReg());
    if (!Ty.isValid())
      continue;

    OpdsMapping[Idx] =
        &getValueMapping(0, Ty.getSizeInBits(), LC2K::GPRRegBank);
  }

  return getInstructionMapping(DefaultMappingID, /*Cost=*/1,
                               getOperandsMapping(OpdsMapping), NumOperands);
}
