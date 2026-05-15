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

#include "LC2KInstrInfo.h"
#include "LC2KRegisterInfo.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/Support/MathExtras.h"

using namespace llvm;

void LC2KFrameLowering::emitPrologue(MachineFunction &MF,
                                     MachineBasicBlock &MBB) const {
  assert(&MF.front() == &MBB && "Shrink-wrapping not yet supported");

  MachineFrameInfo &MFI = MF.getFrameInfo();
  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();
  MachineBasicBlock::iterator MBBI = MBB.begin();

  // Debug location must be unknown since the first debug location is used
  // to determine the end of the prologue.
  DebugLoc DL;

  int64_t StackSize = MFI.getStackSize();
  if (StackSize == 0)
    return;

  assert(StackSize % 4 == 0 && "Stack size must be word-aligned");
  assert(isInt<20>(-StackSize / 4) &&
         "Stack frame too large for addi immediate field");

  BuildMI(MBB, MBBI, DL, TII.get(LC2K::ADDI), LC2K::SP)
      .addReg(LC2K::SP)
      .addImm(-StackSize / 4)
      .setMIFlag(MachineInstr::FrameSetup);
}

void LC2KFrameLowering::emitEpilogue(MachineFunction &MF,
                                     MachineBasicBlock &MBB) const {
  MachineFrameInfo &MFI = MF.getFrameInfo();
  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();
  MachineBasicBlock::iterator MBBI = MBB.getLastNonDebugInstr();
  DebugLoc DL = MBBI->getDebugLoc();

  int64_t StackSize = MFI.getStackSize();
  if (StackSize == 0)
    return;

  assert(StackSize % 4 == 0 && "Stack size must be word-aligned");
  assert(isInt<20>(StackSize / 4) &&
         "Stack frame too large for addi immediate field");

  BuildMI(MBB, MBBI, DL, TII.get(LC2K::ADDI), LC2K::SP)
      .addReg(LC2K::SP)
      .addImm(StackSize / 4)
      .setMIFlag(MachineInstr::FrameDestroy);
}
