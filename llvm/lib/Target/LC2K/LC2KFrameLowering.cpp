//===-- LC2KFrameLowering.cpp - LC2K Frame Information --------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the LC2K implementation of TargetFrameLowering class.
//
//===----------------------------------------------------------------------===//

#include "LC2KFrameLowering.h"

#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"

using namespace llvm;

void LC2KFrameLowering::emitPrologue(MachineFunction &MF,
                                     MachineBasicBlock &MBB) const {
  assert(&MF.front() == &MBB && "Shrink-wrapping not yet supported");

  MachineFrameInfo &MFI = MF.getFrameInfo();
  MachineBasicBlock::iterator MBBI = MBB.begin();

  unsigned StackSize = MFI.getStackSize();

  // From Lanai: Debug location must be unknown since the first debug
  // location is used to determine the end of the prologue.
  DebugLoc DL;

  // TODO: Finish this function
  // BuildMI(MBB, MBBI, DL);
}

void LC2KFrameLowering::emitEpilogue(MachineFunction &MF,
                                     MachineBasicBlock &MBB) const {
  llvm_unreachable("TODO");
}
