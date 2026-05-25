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
#include "LC2KInstrInfo.h"

using namespace llvm;

#define DEBUG_TYPE "lc2k-subtarget"

#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#include "LC2KGenSubtargetInfo.inc"

LC2KSubtarget::LC2KSubtarget(const Triple &TT, const std::string &CPU,
                             const std::string &FS, const TargetMachine &TM)
    : LC2KGenSubtargetInfo(TT, CPU, CPU, FS), InstrInfo(*this),
      FrameLowering() {}

void LC2KSubtarget::anchor() {}
