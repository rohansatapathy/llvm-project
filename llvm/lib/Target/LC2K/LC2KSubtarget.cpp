//===-- LC2KSubtarget.cpp - LC2K Subtarget Information --------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements the LC2K specific subclass of TargetSubtargetInfo.
//
//===----------------------------------------------------------------------===//

#include "LC2KSubtarget.h"
#include "GISel/LC2KCallLowering.h"
#include "GISel/LC2KLegalizerInfo.h"
#include "GISel/LC2KRegisterBankInfo.h"
#include "LC2KInstrInfo.h"
#include "LC2KTargetMachine.h"

// createLC2KInstructionSelector is declared in LC2KSubtarget.h and defined
// in GISel/LC2KInstructionSelector.cpp.

using namespace llvm;

#define DEBUG_TYPE "lc2k-subtarget"

#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#include "LC2KGenSubtargetInfo.inc"

LC2KSubtarget::LC2KSubtarget(const Triple &TT, const std::string &CPU,
                             const std::string &FS, const LC2KTargetMachine &TM)
    : LC2KGenSubtargetInfo(TT, CPU, CPU, FS), InstrInfo(*this), FrameLowering(),
      TLInfo(TM, *this) {
  CallLoweringInfo.reset(new LC2KCallLowering(*getTargetLowering()));
  Legalizer.reset(new LC2KLegalizerInfo(*this));
  RegBankInfo.reset(new LC2KRegisterBankInfo(*getRegisterInfo()));
  InstSelector.reset(createLC2KInstructionSelector(
      TM, *this, *static_cast<const LC2KRegisterBankInfo *>(RegBankInfo.get())));
}

void LC2KSubtarget::anchor() {}

const CallLowering *LC2KSubtarget::getCallLowering() const {
  return CallLoweringInfo.get();
}

InstructionSelector *LC2KSubtarget::getInstructionSelector() const {
  return InstSelector.get();
}

const LegalizerInfo *LC2KSubtarget::getLegalizerInfo() const {
  return Legalizer.get();
}

const RegisterBankInfo *LC2KSubtarget::getRegBankInfo() const {
  return RegBankInfo.get();
}
