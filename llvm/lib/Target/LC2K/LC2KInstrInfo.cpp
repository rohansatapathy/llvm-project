//===-- LC2KInstrInfo.cpp - LC2K Instruction Information --------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the LC2K implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

#include "LC2KInstrInfo.h"
#include "LC2KRegisterInfo.h"
#include "LC2KSubtarget.h"

using namespace llvm;

#define GET_INSTRINFO_CTOR_DTOR
#include "LC2KGenInstrInfo.inc"

LC2KInstrInfo::LC2KInstrInfo(const LC2KSubtarget &STI)
    : LC2KGenInstrInfo(STI, *STI.getRegisterInfo(), LC2K::ADJCALLSTACKDOWN,
                       LC2K::ADJCALLSTACKUP, /*CatchRetOpcode=*/~0u,
                       LC2K::JALR) {}

void LC2KInstrInfo::copyPhysReg(MachineBasicBlock &MBB,
                                MachineBasicBlock::iterator MI,
                                const DebugLoc &DL, Register DestReg,
                                Register SrcReg, bool KillSrc,
                                bool RenamableDest, bool RenamableSrc) const {
  assert(LC2K::GPRRegClass.contains(DestReg, SrcReg) &&
         "reg-reg copy regs should be GPRs");

  BuildMI(MBB, MI, DL, get(LC2K::ADD), DestReg)
      .addReg(Register(SrcReg), getKillRegState(KillSrc))
      .addReg(Register(LC2K::R0));
}

void LC2KInstrInfo::storeRegToStackSlot(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MI, Register SrcReg,
    bool IsKill, int FrameIndex, const TargetRegisterClass *RC, Register VReg,
    MachineInstr::MIFlag Flags) const {

  assert((RC == &LC2K::GPRRegClass) && "all registers should be GPRRegClass");

  DebugLoc DL;
  if (MI != MBB.end()) {
    DL = MI->getDebugLoc();
  }

  BuildMI(MBB, MI, DL, get(LC2K::SW))
      .addReg(SrcReg, getKillRegState(IsKill))
      .addFrameIndex(FrameIndex)
      .addImm(0);
}

void LC2KInstrInfo::loadRegFromStackSlot(MachineBasicBlock &MBB,
                                         MachineBasicBlock::iterator MI,
                                         Register DestReg, int FrameIndex,
                                         const TargetRegisterClass *RC,
                                         Register VReg, unsigned SubReg,
                                         MachineInstr::MIFlag Flags) const {
  assert((RC == &LC2K::GPRRegClass) && "all registers should be GPRRegClass");

  DebugLoc DL;
  if (MI != MBB.end()) {
    DL = MI->getDebugLoc();
  }

  BuildMI(MBB, MI, DL, get(LC2K::LW), DestReg)
      .addFrameIndex(FrameIndex)
      .addImm(0);
}
