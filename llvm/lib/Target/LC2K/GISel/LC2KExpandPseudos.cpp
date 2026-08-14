//===-- LC2KExpandPseudos.cpp ------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// Expands PSEUDO_SELECT and PSEUDO_CMP01 into their real branch/PHI
/// sequences. These can't be expanded directly inside
/// LC2KInstructionSelector::select(): GISel's InstructionSelect pass is
/// itself mid-traversal of the CFG (via post_order) while select() runs, so
/// splitting the block currently being visited there corrupts that
/// traversal. This pass runs immediately after InstructionSelect (see
/// LC2KPassConfig::addPreRegAlloc), once the CFG is safe to mutate again.
///
//===----------------------------------------------------------------------===//

#include "LC2K.h"
#include "LC2KInstrInfo.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"

using namespace llvm;

#define DEBUG_TYPE "lc2k-expand-pseudos"

namespace {

class LC2KExpandPseudos : public MachineFunctionPass {
public:
  static char ID;
  LC2KExpandPseudos() : MachineFunctionPass(ID) {}

  bool runOnMachineFunction(MachineFunction &MF) override;

  StringRef getPassName() const override {
    return "LC2K pseudo instruction expansion";
  }

private:
  void expandSelect(MachineInstr &MI, const TargetInstrInfo &TII) const;
  void expandCmp01(MachineInstr &MI, const TargetInstrInfo &TII) const;
};

} // namespace

char LC2KExpandPseudos::ID = 0;

bool LC2KExpandPseudos::runOnMachineFunction(MachineFunction &MF) {
  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();

  // Collect first, expand after: expanding a pseudo splits its block and
  // inserts new ones, which would invalidate any iterator still walking the
  // block/instruction lists directly.
  SmallVector<MachineInstr *, 8> Worklist;
  for (MachineBasicBlock &MBB : MF)
    for (MachineInstr &MI : MBB)
      if (MI.getOpcode() == LC2K::PSEUDO_SELECT ||
          MI.getOpcode() == LC2K::PSEUDO_CMP01)
        Worklist.push_back(&MI);

  for (MachineInstr *MI : Worklist) {
    if (MI->getOpcode() == LC2K::PSEUDO_SELECT)
      expandSelect(*MI, TII);
    else
      expandCmp01(*MI, TII);
  }

  return !Worklist.empty();
}

void LC2KExpandPseudos::expandSelect(MachineInstr &MI,
                                     const TargetInstrInfo &TII) const {
  MachineBasicBlock &MBB = *MI.getParent();
  MachineFunction &MF = *MBB.getParent();
  MachineRegisterInfo &MRI = MF.getRegInfo();
  DebugLoc DL = MI.getDebugLoc();

  Register Dst = MI.getOperand(0).getReg();
  Register Cond = MI.getOperand(1).getReg();
  Register TrueVal = MI.getOperand(2).getReg();
  Register FalseVal = MI.getOperand(3).getReg();

  // LC2K has no conditional move, so synthesize control flow: branch around
  // a "true" move on false, otherwise fall through it and skip the "false"
  // move, merging the two paths' values with a PHI.
  MachineBasicBlock *MergeMBB = MBB.splitAt(MI, /*UpdateLiveIns=*/false);
  MachineBasicBlock *FalseMBB =
      MF.CreateMachineBasicBlock(MBB.getBasicBlock());
  MF.insert(std::next(MachineFunction::iterator(&MBB)), FalseMBB);

  MBB.replaceSuccessor(MergeMBB, FalseMBB);
  MBB.addSuccessor(MergeMBB);
  FalseMBB->addSuccessor(MergeMBB);

  Register TrueCopy = MRI.createVirtualRegister(&LC2K::GPRRegClass);
  Register FalseCopy = MRI.createVirtualRegister(&LC2K::GPRRegClass);

  // TrueCopy is computed unconditionally, before the branch: the two BEQs
  // below are terminators and must be contiguous at the end of the block,
  // so no non-terminator instruction (like this move) can follow them. It's
  // simply unused on the path where the branch is taken.
  BuildMI(MBB, MBB.end(), DL, TII.get(LC2K::ADD), TrueCopy)
      .addReg(TrueVal)
      .addReg(LC2K::R0);
  BuildMI(MBB, MBB.end(), DL, TII.get(LC2K::BEQ))
      .addReg(Cond)
      .addReg(LC2K::R0)
      .addMBB(FalseMBB);
  BuildMI(MBB, MBB.end(), DL, TII.get(LC2K::BEQ))
      .addReg(LC2K::R0)
      .addReg(LC2K::R0)
      .addMBB(MergeMBB);
  BuildMI(*FalseMBB, FalseMBB->end(), DL, TII.get(LC2K::ADD), FalseCopy)
      .addReg(FalseVal)
      .addReg(LC2K::R0);
  BuildMI(*MergeMBB, MergeMBB->begin(), DL, TII.get(TargetOpcode::PHI), Dst)
      .addReg(TrueCopy)
      .addMBB(&MBB)
      .addReg(FalseCopy)
      .addMBB(FalseMBB);

  MI.eraseFromParent();
}

void LC2KExpandPseudos::expandCmp01(MachineInstr &MI,
                                    const TargetInstrInfo &TII) const {
  MachineBasicBlock &MBB = *MI.getParent();
  MachineFunction &MF = *MBB.getParent();
  MachineRegisterInfo &MRI = MF.getRegInfo();
  DebugLoc DL = MI.getDebugLoc();

  Register Dst = MI.getOperand(0).getReg();
  Register LHS = MI.getOperand(1).getReg();
  Register RHS = MI.getOperand(2).getReg();
  bool IsEq = MI.getOperand(3).getImm() != 0;

  // LC2K has no compare-into-register instruction, so materialize a real
  // 0/1 value via a compare-and-branch + PHI merge. Deliberately not fused
  // with whatever consumes it (a real G_BRCOND/G_SELECT lowering already
  // works correctly against any already-0/1 register regardless of what
  // produced it) -- fusing away this extra branch is a possible future
  // optimization, not required for correctness.
  MachineBasicBlock *MergeMBB = MBB.splitAt(MI, /*UpdateLiveIns=*/false);
  MachineBasicBlock *TakenMBB =
      MF.CreateMachineBasicBlock(MBB.getBasicBlock());
  MF.insert(std::next(MachineFunction::iterator(&MBB)), TakenMBB);

  MBB.replaceSuccessor(MergeMBB, TakenMBB);
  MBB.addSuccessor(MergeMBB);
  TakenMBB->addSuccessor(MergeMBB);

  Register NotTakenVal = MRI.createVirtualRegister(&LC2K::GPRRegClass);
  Register TakenVal = MRI.createVirtualRegister(&LC2K::GPRRegClass);

  // NotTakenVal is computed unconditionally, before the branches: the two
  // BEQs below are terminators and must be contiguous at the end of the
  // block, so no non-terminator instruction (like this immediate load) can
  // follow them. It's simply unused on the path where the branch is taken.
  BuildMI(MBB, MBB.end(), DL, TII.get(LC2K::ADDI), NotTakenVal)
      .addReg(LC2K::R0)
      .addImm(IsEq ? 0 : 1);
  BuildMI(MBB, MBB.end(), DL, TII.get(LC2K::BEQ))
      .addReg(LHS)
      .addReg(RHS)
      .addMBB(TakenMBB);
  BuildMI(MBB, MBB.end(), DL, TII.get(LC2K::BEQ))
      .addReg(LC2K::R0)
      .addReg(LC2K::R0)
      .addMBB(MergeMBB);
  BuildMI(*TakenMBB, TakenMBB->end(), DL, TII.get(LC2K::ADDI), TakenVal)
      .addReg(LC2K::R0)
      .addImm(IsEq ? 1 : 0);
  BuildMI(*MergeMBB, MergeMBB->begin(), DL, TII.get(TargetOpcode::PHI), Dst)
      .addReg(NotTakenVal)
      .addMBB(&MBB)
      .addReg(TakenVal)
      .addMBB(TakenMBB);

  MI.eraseFromParent();
}

namespace llvm {
FunctionPass *createLC2KExpandPseudosPass() {
  return new LC2KExpandPseudos();
}
} // namespace llvm
