//===-- LC2KRegisterInfo.cpp - LC2K Register Information --------*- C++ -*-===//
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

#include "LC2KRegisterInfo.h"

#include "MCTargetDesc/LC2KMCTargetDesc.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/CodeGen/CallingConvLower.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/TargetFrameLowering.h"
#include "llvm/CodeGen/TargetRegisterInfo.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"
#include "llvm/CodeGenTypes/MachineValueType.h"
#include "llvm/MC/MCRegister.h"
#include "llvm/MC/MCRegisterInfo.h"

#define GET_REGINFO_TARGET_DESC
#include "LC2KGenRegisterInfo.inc"

using namespace llvm;

// TODO: Move this to the ISel file
#include "LC2KGenCallingConv.inc"

LC2KRegisterInfo::LC2KRegisterInfo() : LC2KGenRegisterInfo(LC2K::RA) {}

const MCPhysReg *
LC2KRegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const {
  return CSR_SaveList;
}

BitVector LC2KRegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());

  Reserved.set(LC2K::R0);
  Reserved.set(LC2K::SP);
  Reserved.set(LC2K::RA);

  return Reserved;
}

bool LC2KRegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                           int SPAdj, unsigned FIOperandNum,
                                           RegScavenger *RS) const {

  assert(SPAdj == 0 && "Unexpected");

  MachineInstr &MI = *II;
  MachineFunction &MF = *MI.getParent()->getParent();
  const TargetFrameLowering *TFI = MF.getSubtarget().getFrameLowering();

  bool HasFP = TFI->hasFP(MF);

  assert(!HasFP && "LC2K should not have a frame pointer");

  int FrameIndex = MI.getOperand(FIOperandNum).getIndex();

  // The frame object stores the offset relative to the position of the
  // stack pointer *before* the prolog has run, so should be negative.
  int ObjectFPOffset = MF.getFrameInfo().getObjectOffset(FrameIndex);

  // For offset within compound data types.
  int ObjectInternalOffset = MI.getOperand(FIOperandNum + 1).getImm();

  // To convert pre-prologue offset to post-prologue offset.
  int StackSize = MF.getFrameInfo().getStackSize();

  int Offset = ObjectFPOffset + StackSize + ObjectInternalOffset;

  assert(Offset % 4 == 0 && "LC2K stack offsets should be word-aligned");

  assert(isInt<20>(Offset) &&
         "Stack offsets larger than 20 bits are not supported");

  assert((MI.getOpcode() == LC2K::LW || MI.getOpcode() == LC2K::SW) &&
         "Unexpected opcode in frame index elimination");

  MI.getOperand(FIOperandNum).ChangeToRegister(LC2K::SP, /*isDef=*/false);
  // Convert byte offset to word offset.
  MI.getOperand(FIOperandNum + 1).ChangeToImmediate(Offset / 4);

  return false;
}

Register LC2KRegisterInfo::getFrameRegister(const MachineFunction &MF) const {
  // LC2K never uses a frame pointer.
  return LC2K::SP;
}
