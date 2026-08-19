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

static bool isBEQOpcode(unsigned Opc) {
  return Opc == LC2K::BEQ || Opc == LC2K::BEQ_UNCOND;
}

bool LC2KInstrInfo::analyzeBranch(MachineBasicBlock &MBB,
                                  MachineBasicBlock *&TBB,
                                  MachineBasicBlock *&FBB,
                                  SmallVectorImpl<MachineOperand> &Cond,
                                  bool AllowModify) const {
  TBB = FBB = nullptr;
  Cond.clear();

  // No terminators (including the case where the block has no real
  // instructions at all): falls through to the layout successor.
  MachineBasicBlock::iterator I = MBB.getLastNonDebugInstr();
  if (I == MBB.end() || !I->isTerminator())
    return false;

  // JALR (used for returns) is LC2K's only other terminator; anything that
  // isn't one of our two branch opcodes can't be analyzed as a branch.
  if (!isBEQOpcode(I->getOpcode()))
    return true;

  // Count the trailing BEQ/BEQ_UNCONDs, mirroring
  // RISCVInstrInfo::analyzeBranch. LC2K's selector never leaves more than
  // two terminators behind (a conditional BEQ optionally followed by a
  // BEQ_UNCOND), so there's no dead-branch cleanup for AllowModify to do
  // here.
  int NumTerminators = 0;
  for (auto J = I.getReverse(); J != MBB.rend() && isBEQOpcode(J->getOpcode());
       ++J)
    ++NumTerminators;

  if (NumTerminators > 2)
    return true;

  // A single unconditional branch.
  if (NumTerminators == 1 && I->getOpcode() == LC2K::BEQ_UNCOND) {
    TBB = I->getOperand(2).getMBB();
    return false;
  }

  // A single conditional branch that falls through to its other successor.
  if (NumTerminators == 1) {
    TBB = I->getOperand(2).getMBB();
    Cond.push_back(I->getOperand(0));
    Cond.push_back(I->getOperand(1));
    return false;
  }

  // Exactly two terminators left: a conditional branch followed by an
  // unconditional one is the only two-terminator shape LC2K's selector ever
  // produces.
  if (std::prev(I)->getOpcode() == LC2K::BEQ &&
      I->getOpcode() == LC2K::BEQ_UNCOND) {
    TBB = std::prev(I)->getOperand(2).getMBB();
    Cond.push_back(std::prev(I)->getOperand(0));
    Cond.push_back(std::prev(I)->getOperand(1));
    FBB = I->getOperand(2).getMBB();
    return false;
  }

  return true;
}

unsigned LC2KInstrInfo::removeBranch(MachineBasicBlock &MBB,
                                     int *BytesRemoved) const {
  if (BytesRemoved)
    *BytesRemoved = 0;

  MachineBasicBlock::iterator Instruction = MBB.end();
  unsigned Count = 0;

  // LLVM allows basic blocks to end with two consecutive branches
  // (conditional + unconditional pair), so loop until all branches at
  // end are removed.
  while (Instruction != MBB.begin()) {
    --Instruction;
    if (Instruction->isDebugInstr())
      continue;
    if (!isBEQOpcode(Instruction->getOpcode()))
      break;

    // getDesc().getSize() must be read before erasing -- the MachineInstr
    // (and its MCInstrDesc reference) won't exist afterward.
    if (BytesRemoved)
      *BytesRemoved += Instruction->getDesc().getSize();

    // Remove the branch.
    Instruction->eraseFromParent();
    Instruction = MBB.end();
    ++Count;
  }

  return Count;
}

unsigned LC2KInstrInfo::insertBranch(
    MachineBasicBlock &MBB, MachineBasicBlock *TBB, MachineBasicBlock *FBB,
    ArrayRef<MachineOperand> Cond, const DebugLoc &DL, int *BytesAdded) const {
  if (BytesAdded)
    *BytesAdded = 0;

  assert(TBB && "insertBranch must not be told to insert a fallthrough");
  assert((Cond.empty() || Cond.size() == 2) &&
         "a branch condition is exactly the two registers a BEQ compares");

  // Unconditional branch: BEQ_UNCOND $r0, $r0, TBB is always taken (see
  // selectBr).
  if (Cond.empty()) {
    MachineInstr &MI = *BuildMI(&MBB, DL, get(LC2K::BEQ_UNCOND))
                            .addReg(LC2K::R0)
                            .addReg(LC2K::R0)
                            .addMBB(TBB);
    if (BytesAdded)
      *BytesAdded += MI.getDesc().getSize();
    return 1;
  }

  // One or two-way conditional branch.
  MachineInstr &CondMI =
      *BuildMI(&MBB, DL, get(LC2K::BEQ)).add(Cond[0]).add(Cond[1]).addMBB(TBB);
  if (BytesAdded)
    *BytesAdded += CondMI.getDesc().getSize();

  if (!FBB)
    return 1;

  MachineInstr &UncondMI = *BuildMI(&MBB, DL, get(LC2K::BEQ_UNCOND))
                                .addReg(LC2K::R0)
                                .addReg(LC2K::R0)
                                .addMBB(FBB);
  if (BytesAdded)
    *BytesAdded += UncondMI.getDesc().getSize();
  return 2;
}
