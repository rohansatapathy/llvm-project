//===-- LC2KInstructionSelector.cpp ------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file implements the targeting of the InstructionSelector class for
/// LC2K.
///
/// LC2K has no TableGen selection patterns anywhere (see LC2KInstrInfo.td):
/// the instruction set is tiny (ADD/NOR/NAND/LW/SW/ADDI/BEQ/JALR) and most
/// generic ops the legalizer leaves "legal" (G_SUB/G_AND/G_OR/G_XOR,
/// G_BRCOND, G_SELECT, G_ICMP eq/ne) have no 1:1 hardware equivalent, so this
/// selector is entirely hand-written.
///
/// Pointer values held in GPRs are LC2K *word* addresses. LC2K's memory is
/// only word-addressable, and the DataLayout declares a 32-bit byte (b:32),
/// so generic-MI/LLVM IR pointer arithmetic is already word-granular by the
/// time it reaches this selector -- constant pointer offsets can be folded
/// into instruction immediates directly, with no byte->word scaling needed.
///
//===----------------------------------------------------------------------===//

#include "GISel/LC2KRegisterBankInfo.h"
#include "LC2KInstrInfo.h"
#include "LC2KRegisterInfo.h"
#include "LC2KSubtarget.h"
#include "LC2KTargetMachine.h"
#include "llvm/CodeGen/GlobalISel/GIMatchTableExecutorImpl.h"
#include "llvm/CodeGen/GlobalISel/GenericMachineInstrs.h"
#include "llvm/CodeGen/GlobalISel/InstructionSelector.h"
#include "llvm/CodeGen/GlobalISel/Utils.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/Support/MathExtras.h"

#define DEBUG_TYPE "lc2k-isel"

using namespace llvm;

#define GET_GLOBALISEL_PREDICATE_BITSET
#include "LC2KGenGlobalISel.inc"
#undef GET_GLOBALISEL_PREDICATE_BITSET

namespace {

class LC2KInstructionSelector : public InstructionSelector {
public:
  LC2KInstructionSelector(const LC2KTargetMachine &TM,
                          const LC2KSubtarget &STI,
                          const LC2KRegisterBankInfo &RBI);

  bool select(MachineInstr &I) override;
  static const char *getName() { return DEBUG_TYPE; }

private:
  /// tblgen-generated 'select' implementation. LC2K has no Pat<> patterns,
  /// so this always fails and every real opcode is handled by the switch in
  /// select() below -- it's kept only to satisfy the InstructionSelector /
  /// GIMatchTableExecutor boilerplate.
  bool selectImpl(MachineInstr &I, CodeGenCoverage &CoverageInfo) const;

  bool selectGeneric(MachineInstr &I) const;
  bool selectConstant(MachineInstr &I) const;
  bool selectFConstant(MachineInstr &I) const;
  bool selectAdd(MachineInstr &I) const;
  bool selectSub(MachineInstr &I) const;
  bool selectAnd(MachineInstr &I) const;
  bool selectOr(MachineInstr &I) const;
  bool selectXor(MachineInstr &I) const;
  bool selectFrameIndex(MachineInstr &I) const;
  bool selectGlobalValue(MachineInstr &I) const;
  bool selectJumpTable(MachineInstr &I) const;
  bool selectBrIndirect(MachineInstr &I) const;
  bool selectPtrAdd(MachineInstr &I) const;
  bool selectLoadStore(MachineInstr &I) const;
  bool selectICmp(MachineInstr &I) const;
  bool selectBrCond(MachineInstr &I) const;
  bool selectBr(MachineInstr &I) const;
  bool selectSelect(MachineInstr &I) const;
  bool selectTrunc(MachineInstr &I) const;
  bool selectZExtAnyExt(MachineInstr &I) const;
  bool selectSExt(MachineInstr &I) const;
  bool selectPtrIntCast(MachineInstr &I) const;
  bool selectCall(MachineInstr &I) const;
  bool selectAddrEs(MachineInstr &I) const;

  /// Materializes an arbitrary 32-bit constant into Dst, inserted just
  /// before Before. Values that fit the 20-bit ADDI immediate become a
  /// single ADDI; wider values are built bit-serially via doubling (ADD
  /// acc,acc,acc) and conditionally incrementing (ADDI acc,acc,1), since
  /// LC2K has no shift hardware.
  void materializeConstant(Register Dst, int64_t Val,
                           MachineInstr &Before) const;

  /// Materializes the address of Sym (a global value, jump table, or
  /// external symbol operand -- anything add-able via
  /// MachineInstrBuilder::add) into Dst, inserted just before Before.
  /// Always emits PSEUDO_LA unconditionally: unlike materializeConstant's
  /// literal values, a symbol's real address is never known until link
  /// time (and even a same-object-file absolute reference can't be proven
  /// to fit a single ADDI until then either, since ELF sections have no
  /// final address until the linker places them -- see the PSEUDO_LA doc
  /// comment in LC2KInstrInfo.td), so there's no cheaper form to try
  /// first the way there is for constants.
  void materializeSymbolAddress(Register Dst, const MachineOperand &Sym,
                                MachineInstr &Before) const;

  /// Appends the (base, offset) operand pair used by LW/SW/ADDI-style
  /// addressing for a pointer value held in PtrReg, folding a directly
  /// visible G_FRAME_INDEX / G_GLOBAL_VALUE / constant-offset G_PTR_ADD into
  /// the addressing mode where possible. Does not erase or otherwise touch
  /// the defining instruction(s) it looked through -- if PtrReg ends up
  /// unused as a result of folding, the defining instruction(s) are still
  /// independently selected (and left for dead-code elimination to clean
  /// up), exactly like every other GlobalISel target's addressing-mode
  /// folding.
  void appendAddrOperands(MachineInstrBuilder &MIB, Register PtrReg,
                          MachineRegisterInfo &MRI) const;

  /// Constrains every register operand of the just-built instruction to its
  /// required register class.
  void constrain(MachineInstrBuilder MIB) const {
    constrainSelectedInstRegOperands(*MIB, TII, TRI, RBI);
  }

  const LC2KInstrInfo &TII;
  const LC2KRegisterInfo &TRI;
  const LC2KRegisterBankInfo &RBI;

#define GET_GLOBALISEL_PREDICATES_DECL
#include "LC2KGenGlobalISel.inc"
#undef GET_GLOBALISEL_PREDICATES_DECL

#define GET_GLOBALISEL_TEMPORARIES_DECL
#include "LC2KGenGlobalISel.inc"
#undef GET_GLOBALISEL_TEMPORARIES_DECL
};

} // namespace

#define GET_GLOBALISEL_IMPL
#include "LC2KGenGlobalISel.inc"
#undef GET_GLOBALISEL_IMPL

LC2KInstructionSelector::LC2KInstructionSelector(
    const LC2KTargetMachine &TM, const LC2KSubtarget &STI,
    const LC2KRegisterBankInfo &RBI)
    : TII(static_cast<const LC2KInstrInfo &>(*STI.getInstrInfo())),
      TRI(TII.getRegisterInfo()), RBI(RBI),
#define GET_GLOBALISEL_PREDICATES_INIT
#include "LC2KGenGlobalISel.inc"
#undef GET_GLOBALISEL_PREDICATES_INIT
#define GET_GLOBALISEL_TEMPORARIES_INIT
#include "LC2KGenGlobalISel.inc"
#undef GET_GLOBALISEL_TEMPORARIES_INIT
{
}

bool LC2KInstructionSelector::select(MachineInstr &I) {
  switch (I.getOpcode()) {
  case LC2K::CALL:
    return selectCall(I);
  case LC2K::ADDR_ES:
    return selectAddrEs(I);
  case TargetOpcode::COPY:
    // COPY is not a pre-ISel generic opcode, so it must be special-cased
    // here rather than in the generic switch below -- otherwise it would
    // hit the !isPreISelGenericOpcode bail-out and never get its vreg
    // constrained to a register class.
    return selectGeneric(I);
  default:
    break;
  }

  if (!isPreISelGenericOpcode(I.getOpcode()))
    return true; // Already real (HALT/NOOP/ADJCALLSTACKDOWN/UP/etc.)

  if (selectImpl(I, *CoverageInfo))
    return true;

  switch (I.getOpcode()) {
  case TargetOpcode::G_PHI:
  case TargetOpcode::G_IMPLICIT_DEF:
    return selectGeneric(I);
  case TargetOpcode::G_CONSTANT:
    return selectConstant(I);
  case TargetOpcode::G_FCONSTANT:
    return selectFConstant(I);
  case TargetOpcode::G_ADD:
    return selectAdd(I);
  case TargetOpcode::G_SUB:
    return selectSub(I);
  case TargetOpcode::G_AND:
    return selectAnd(I);
  case TargetOpcode::G_OR:
    return selectOr(I);
  case TargetOpcode::G_XOR:
    return selectXor(I);
  case TargetOpcode::G_FRAME_INDEX:
    return selectFrameIndex(I);
  case TargetOpcode::G_GLOBAL_VALUE:
    return selectGlobalValue(I);
  case TargetOpcode::G_JUMP_TABLE:
    return selectJumpTable(I);
  case TargetOpcode::G_BRINDIRECT:
    return selectBrIndirect(I);
  case TargetOpcode::G_PTR_ADD:
    return selectPtrAdd(I);
  case TargetOpcode::G_LOAD:
  case TargetOpcode::G_STORE:
    return selectLoadStore(I);
  case TargetOpcode::G_ICMP:
    return selectICmp(I);
  case TargetOpcode::G_BRCOND:
    return selectBrCond(I);
  case TargetOpcode::G_BR:
    return selectBr(I);
  case TargetOpcode::G_SELECT:
    return selectSelect(I);
  case TargetOpcode::G_TRUNC:
    return selectTrunc(I);
  case TargetOpcode::G_ZEXT:
  case TargetOpcode::G_ANYEXT:
    return selectZExtAnyExt(I);
  case TargetOpcode::G_SEXT:
    return selectSExt(I);
  case TargetOpcode::G_PTRTOINT:
  case TargetOpcode::G_INTTOPTR:
    return selectPtrIntCast(I);
  default:
    return false;
  }
}

bool LC2KInstructionSelector::selectGeneric(MachineInstr &I) const {
  MachineRegisterInfo &MRI = I.getMF()->getRegInfo();
  switch (I.getOpcode()) {
  case TargetOpcode::COPY: {
    Register Dst = I.getOperand(0).getReg();
    if (Dst.isPhysical())
      return true;
    // No need to constrain the source: it will get constrained when we hit
    // its own def, or it's already a physreg.
    return RBI.constrainGenericRegister(Dst, LC2K::GPRRegClass, MRI) !=
           nullptr;
  }
  case TargetOpcode::G_PHI: {
    Register Dst = I.getOperand(0).getReg();
    I.setDesc(TII.get(TargetOpcode::PHI));
    return RBI.constrainGenericRegister(Dst, LC2K::GPRRegClass, MRI) !=
           nullptr;
  }
  case TargetOpcode::G_IMPLICIT_DEF: {
    Register Dst = I.getOperand(0).getReg();
    I.setDesc(TII.get(TargetOpcode::IMPLICIT_DEF));
    return RBI.constrainGenericRegister(Dst, LC2K::GPRRegClass, MRI) !=
           nullptr;
  }
  default:
    llvm_unreachable("unexpected opcode in selectGeneric");
  }
}

void LC2KInstructionSelector::materializeConstant(Register Dst, int64_t Val,
                                                  MachineInstr &Before) const {
  MachineBasicBlock &MBB = *Before.getParent();
  MachineRegisterInfo &MRI = Before.getMF()->getRegInfo();
  DebugLoc DL = Before.getDebugLoc();

  if (isInt<20>(Val)) {
    constrain(BuildMI(MBB, Before, DL, TII.get(LC2K::ADDI), Dst)
                  .addReg(LC2K::R0)
                  .addImm(Val));
    return;
  }

  // No shift hardware exists, so build the value bit-serially: double the
  // running accumulator (ADD acc,acc,acc) for every bit of the 32-bit
  // pattern from MSB to LSB, incrementing (ADDI acc,acc,1) whenever that
  // bit is set. Exact mod-2^32 arithmetic, so this works for negative
  // values too.
  uint32_t Bits = static_cast<uint32_t>(Val);
  int Highest = Log2_32(Bits);
  Register Acc = LC2K::R0;
  for (int Bit = Highest; Bit >= 0; --Bit) {
    Register Doubled = MRI.createVirtualRegister(&LC2K::GPRRegClass);
    constrain(BuildMI(MBB, Before, DL, TII.get(LC2K::ADD), Doubled)
                  .addReg(Acc)
                  .addReg(Acc));
    Acc = Doubled;

    if (Bits & (1u << Bit)) {
      Register Next = (Bit == 0) ? Dst : MRI.createVirtualRegister(&LC2K::GPRRegClass);
      constrain(BuildMI(MBB, Before, DL, TII.get(LC2K::ADDI), Next)
                    .addReg(Acc)
                    .addImm(1));
      Acc = Next;
    }
  }

  if (Acc != Dst)
    constrain(BuildMI(MBB, Before, DL, TII.get(LC2K::ADD), Dst)
                  .addReg(Acc)
                  .addReg(LC2K::R0));
}

void LC2KInstructionSelector::materializeSymbolAddress(
    Register Dst, const MachineOperand &Sym, MachineInstr &Before) const {
  constrain(BuildMI(*Before.getParent(), Before, Before.getDebugLoc(),
                    TII.get(LC2K::PSEUDO_LA), Dst)
                .addReg(LC2K::R0)
                .add(Sym));
}

bool LC2KInstructionSelector::selectConstant(MachineInstr &I) const {
  Register Dst = I.getOperand(0).getReg();
  int64_t Val = I.getOperand(1).getCImm()->getSExtValue();
  materializeConstant(Dst, Val, I);
  I.eraseFromParent();
  return true;
}

bool LC2KInstructionSelector::selectFConstant(MachineInstr &I) const {
  // A float constant is just its IEEE-754 bit pattern materialized the same
  // memory-free way as an integer constant -- LC2K has no constant-pool
  // support (see the G_FCONSTANT legalizer rule), and doesn't need any,
  // since the same materializeConstant sequence works regardless of how
  // the bits are meant to be interpreted downstream.
  Register Dst = I.getOperand(0).getReg();
  const APInt Bits =
      I.getOperand(1).getFPImm()->getValueAPF().bitcastToAPInt();
  materializeConstant(Dst, Bits.getZExtValue(), I);
  I.eraseFromParent();
  return true;
}

bool LC2KInstructionSelector::selectAdd(MachineInstr &I) const {
  Register Dst = I.getOperand(0).getReg();
  Register LHS = I.getOperand(1).getReg();
  Register RHS = I.getOperand(2).getReg();
  constrain(BuildMI(*I.getParent(), I, I.getDebugLoc(), TII.get(LC2K::ADD),
                    Dst)
                .addReg(LHS)
                .addReg(RHS));
  I.eraseFromParent();
  return true;
}

bool LC2KInstructionSelector::selectSub(MachineInstr &I) const {
  MachineBasicBlock &MBB = *I.getParent();
  MachineRegisterInfo &MRI = I.getMF()->getRegInfo();
  DebugLoc DL = I.getDebugLoc();
  Register Dst = I.getOperand(0).getReg();
  Register LHS = I.getOperand(1).getReg();
  Register RHS = I.getOperand(2).getReg();

  // a - b == a + (~b + 1); ~b via NOR(b,b).
  Register NotRHS = MRI.createVirtualRegister(&LC2K::GPRRegClass);
  Register NegRHS = MRI.createVirtualRegister(&LC2K::GPRRegClass);
  constrain(BuildMI(MBB, I, DL, TII.get(LC2K::NOR), NotRHS)
                .addReg(RHS)
                .addReg(RHS));
  constrain(BuildMI(MBB, I, DL, TII.get(LC2K::ADDI), NegRHS)
                .addReg(NotRHS)
                .addImm(1));
  constrain(BuildMI(MBB, I, DL, TII.get(LC2K::ADD), Dst)
                .addReg(LHS)
                .addReg(NegRHS));
  I.eraseFromParent();
  return true;
}

bool LC2KInstructionSelector::selectAnd(MachineInstr &I) const {
  MachineBasicBlock &MBB = *I.getParent();
  MachineRegisterInfo &MRI = I.getMF()->getRegInfo();
  DebugLoc DL = I.getDebugLoc();
  Register Dst = I.getOperand(0).getReg();
  Register LHS = I.getOperand(1).getReg();
  Register RHS = I.getOperand(2).getReg();

  // De Morgan: a & b == NOR(~a, ~b).
  Register NotLHS = MRI.createVirtualRegister(&LC2K::GPRRegClass);
  Register NotRHS = MRI.createVirtualRegister(&LC2K::GPRRegClass);
  constrain(BuildMI(MBB, I, DL, TII.get(LC2K::NOR), NotLHS)
                .addReg(LHS)
                .addReg(LHS));
  constrain(BuildMI(MBB, I, DL, TII.get(LC2K::NOR), NotRHS)
                .addReg(RHS)
                .addReg(RHS));
  constrain(BuildMI(MBB, I, DL, TII.get(LC2K::NOR), Dst)
                .addReg(NotLHS)
                .addReg(NotRHS));
  I.eraseFromParent();
  return true;
}

bool LC2KInstructionSelector::selectOr(MachineInstr &I) const {
  MachineBasicBlock &MBB = *I.getParent();
  MachineRegisterInfo &MRI = I.getMF()->getRegInfo();
  DebugLoc DL = I.getDebugLoc();
  Register Dst = I.getOperand(0).getReg();
  Register LHS = I.getOperand(1).getReg();
  Register RHS = I.getOperand(2).getReg();

  // a | b == NOT(NOR(a,b)) == NOR(NOR(a,b), NOR(a,b)).
  Register NorLR = MRI.createVirtualRegister(&LC2K::GPRRegClass);
  constrain(BuildMI(MBB, I, DL, TII.get(LC2K::NOR), NorLR)
                .addReg(LHS)
                .addReg(RHS));
  constrain(BuildMI(MBB, I, DL, TII.get(LC2K::NOR), Dst)
                .addReg(NorLR)
                .addReg(NorLR));
  I.eraseFromParent();
  return true;
}

bool LC2KInstructionSelector::selectXor(MachineInstr &I) const {
  MachineBasicBlock &MBB = *I.getParent();
  MachineRegisterInfo &MRI = I.getMF()->getRegInfo();
  DebugLoc DL = I.getDebugLoc();
  Register Dst = I.getOperand(0).getReg();
  Register LHS = I.getOperand(1).getReg();
  Register RHS = I.getOperand(2).getReg();

  // Classic 4-NAND XOR circuit -- the reason NAND exists as a real LC2K
  // instruction despite never being referenced by the legalizer.
  Register N1 = MRI.createVirtualRegister(&LC2K::GPRRegClass);
  Register N2 = MRI.createVirtualRegister(&LC2K::GPRRegClass);
  Register N3 = MRI.createVirtualRegister(&LC2K::GPRRegClass);
  constrain(BuildMI(MBB, I, DL, TII.get(LC2K::NAND), N1)
                .addReg(LHS)
                .addReg(RHS));
  constrain(BuildMI(MBB, I, DL, TII.get(LC2K::NAND), N2)
                .addReg(LHS)
                .addReg(N1));
  constrain(BuildMI(MBB, I, DL, TII.get(LC2K::NAND), N3)
                .addReg(RHS)
                .addReg(N1));
  constrain(BuildMI(MBB, I, DL, TII.get(LC2K::NAND), Dst)
                .addReg(N2)
                .addReg(N3));
  I.eraseFromParent();
  return true;
}

bool LC2KInstructionSelector::selectFrameIndex(MachineInstr &I) const {
  Register Dst = I.getOperand(0).getReg();
  int FI = I.getOperand(1).getIndex();
  constrain(BuildMI(*I.getParent(), I, I.getDebugLoc(), TII.get(LC2K::ADDI),
                    Dst)
                .addFrameIndex(FI)
                .addImm(0));
  I.eraseFromParent();
  return true;
}

bool LC2KInstructionSelector::selectGlobalValue(MachineInstr &I) const {
  Register Dst = I.getOperand(0).getReg();
  materializeSymbolAddress(Dst, I.getOperand(1), I);
  I.eraseFromParent();
  return true;
}

bool LC2KInstructionSelector::selectJumpTable(MachineInstr &I) const {
  // Same idea as selectGlobalValue: the base address of a jump table is
  // just another symbol's word address.
  Register Dst = I.getOperand(0).getReg();
  materializeSymbolAddress(Dst, I.getOperand(1), I);
  I.eraseFromParent();
  return true;
}

bool LC2KInstructionSelector::selectBrIndirect(MachineInstr &I) const {
  // Same "jump to regA, discard the return address into R0" shape as a
  // plain return (see LC2KCallLowering::lowerReturn), but using JALR_IND
  // instead of JALR so this isn't mistaken for a return -- see the
  // JALR_IND comment in LC2KInstrInfo.td.
  Register Target = I.getOperand(0).getReg();
  constrain(BuildMI(*I.getParent(), I, I.getDebugLoc(), TII.get(LC2K::JALR_IND))
                .addReg(LC2K::R0, RegState::Define)
                .addReg(Target));
  I.eraseFromParent();
  return true;
}

bool LC2KInstructionSelector::selectPtrAdd(MachineInstr &I) const {
  auto &PtrAdd = cast<GPtrAdd>(I);
  MachineRegisterInfo &MRI = I.getMF()->getRegInfo();
  Register Dst = PtrAdd.getReg(0);
  Register Base = PtrAdd.getBaseReg();
  Register Offset = PtrAdd.getOffsetReg();

  auto Cst = getIConstantVRegSExtVal(Offset, MRI);
  if (!Cst) {
    // Non-constant addend: pointers are plain word addresses on LC2K, so
    // this is just a register-register add, identical to selectAdd.
    constrain(BuildMI(*I.getParent(), I, I.getDebugLoc(), TII.get(LC2K::ADD),
                      Dst)
                  .addReg(Base)
                  .addReg(Offset));
    I.eraseFromParent();
    return true;
  }

  int64_t WordOff = *Cst;

  if (isInt<20>(WordOff)) {
    constrain(BuildMI(*I.getParent(), I, I.getDebugLoc(), TII.get(LC2K::ADDI),
                      Dst)
                  .addReg(Base)
                  .addImm(WordOff));
  } else {
    Register Tmp = MRI.createVirtualRegister(&LC2K::GPRRegClass);
    materializeConstant(Tmp, WordOff, I);
    constrain(BuildMI(*I.getParent(), I, I.getDebugLoc(), TII.get(LC2K::ADD),
                      Dst)
                  .addReg(Base)
                  .addReg(Tmp));
  }
  I.eraseFromParent();
  return true;
}

void LC2KInstructionSelector::appendAddrOperands(
    MachineInstrBuilder &MIB, Register PtrReg, MachineRegisterInfo &MRI) const {
  MachineInstr *Def = MRI.getVRegDef(PtrReg);

  if (Def->getOpcode() == TargetOpcode::G_FRAME_INDEX) {
    // Offset is always 0 here.
    MIB.addFrameIndex(Def->getOperand(1).getIndex());
    MIB.addImm(0);
    return;
  }

  // G_GLOBAL_VALUE is deliberately NOT folded here the way G_FRAME_INDEX is
  // above: a global's address may need PSEUDO_LA's wide, multi-instruction
  // form (see materializeSymbolAddress), which needs a real destination
  // register to build the address into -- LW/SW's own destination register
  // holds the loaded/stored data value, not an address, so there's nowhere
  // to build a wide address even if this fold looked through to one. Global
  // addresses always fall through to the general fallback below instead,
  // where G_GLOBAL_VALUE's own independent selection (selectGlobalValue)
  // materializes the full address into its own register first.

  if (Def->getOpcode() == TargetOpcode::G_PTR_ADD) {
    auto &PtrAdd = cast<GPtrAdd>(*Def);
    Register Base = PtrAdd.getBaseReg();
    if (auto Cst = getIConstantVRegSExtVal(PtrAdd.getOffsetReg(), MRI)) {
      MachineInstr *BaseDef = MRI.getVRegDef(Base);
      if (BaseDef->getOpcode() == TargetOpcode::G_FRAME_INDEX) {
        MIB.addFrameIndex(BaseDef->getOperand(1).getIndex());
        MIB.addImm(*Cst);
        return;
      }
      if (BaseDef->getOpcode() != TargetOpcode::G_GLOBAL_VALUE) {
        int64_t WordOff = *Cst;
        if (isInt<20>(WordOff)) {
          MIB.addReg(Base);
          MIB.addImm(WordOff);
          return;
        }
      }
      // Global-relative constant offsets and out-of-range word offsets
      // fall through to the general case: PtrReg's own (independent)
      // selection already materializes the full address.
    }
  }

  // General fallback: plain register base, zero offset.
  MIB.addReg(PtrReg);
  MIB.addImm(0);
}

bool LC2KInstructionSelector::selectLoadStore(MachineInstr &I) const {
  MachineRegisterInfo &MRI = I.getMF()->getRegInfo();
  bool IsLoad = I.getOpcode() == TargetOpcode::G_LOAD;

  Register PtrReg = IsLoad ? cast<GLoad>(I).getPointerReg()
                           : cast<GStore>(I).getPointerReg();
  Register DataReg =
      IsLoad ? cast<GLoad>(I).getDstReg() : cast<GStore>(I).getValueReg();

  auto MIB = BuildMI(*I.getParent(), I, I.getDebugLoc(),
                     TII.get(IsLoad ? LC2K::LW : LC2K::SW));
  if (IsLoad)
    MIB.addReg(DataReg, RegState::Define);
  else
    MIB.addReg(DataReg);

  appendAddrOperands(MIB, PtrReg, MRI);

  constrain(MIB);
  I.eraseFromParent();
  return true;
}

bool LC2KInstructionSelector::selectICmp(MachineInstr &I) const {
  auto &Cmp = cast<GICmp>(I);
  assert((Cmp.getCond() == CmpInst::ICMP_EQ ||
         Cmp.getCond() == CmpInst::ICMP_NE) &&
         "relational icmp predicates should have been legalized to libcalls");
  bool IsEq = Cmp.getCond() == CmpInst::ICMP_EQ;

  // LC2K has no compare-into-register instruction: materializing a real 0/1
  // value needs real control flow (compare-and-branch + merge). That can't
  // safely be built here -- GISel's InstructionSelect pass is itself
  // mid-traversal of the CFG (via post_order) while select() runs, and
  // splitting the block being visited corrupts that traversal. Emit a
  // single-instruction placeholder instead; LC2KExpandPseudos expands it
  // into the real sequence once InstructionSelect has fully finished and
  // the CFG is safe to mutate again.
  constrain(BuildMI(*I.getParent(), I, I.getDebugLoc(),
                    TII.get(LC2K::PSEUDO_CMP01), Cmp.getReg(0))
                .addReg(Cmp.getLHSReg())
                .addReg(Cmp.getRHSReg())
                .addImm(IsEq));
  I.eraseFromParent();
  return true;
}

bool LC2KInstructionSelector::selectBrCond(MachineInstr &I) const {
  MachineBasicBlock &MBB = *I.getParent();
  MachineRegisterInfo &MRI = I.getMF()->getRegInfo();

  Register Cond = I.getOperand(0).getReg();
  MachineBasicBlock *TrueMBB = I.getOperand(1).getMBB();

  // G_BRCOND is usually paired with an explicit sibling G_BR to the
  // false-path target ("IRTranslator's fixed shape for conditional
  // branches", see below) -- but IRTranslator::emitJumpTableHeader (the
  // range check ahead of a jump-table dispatch) omits that sibling
  // whenever the false-path target is already this block's fallthrough
  // layout successor, leaving G_BRCOND as the block's only terminator.
  // Handle that shape directly: since Cond is canonically 0/1 (see
  // selectICmp/PSEUDO_CMP01), materialize a 1 and branch on equality to
  // it -- BEQ is LC2K's only conditional branch, so there's no way to
  // branch "if nonzero" outright, and unlike the two-terminator shapes
  // below there's no sibling branch here to retarget, so the false path
  // must be reached purely by the implicit fallthrough that's already
  // there.
  MachineBasicBlock::iterator NextIt =
      std::next(MachineBasicBlock::iterator(I));
  if (NextIt == MBB.end()) {
    Register One = MRI.createVirtualRegister(&LC2K::GPRRegClass);
    constrain(BuildMI(MBB, I, I.getDebugLoc(), TII.get(LC2K::ADDI), One)
                  .addReg(LC2K::R0)
                  .addImm(1));
    constrain(BuildMI(MBB, I, I.getDebugLoc(), TII.get(LC2K::BEQ))
                  .addReg(Cond)
                  .addReg(One)
                  .addMBB(TrueMBB));
    I.eraseFromParent();
    return true;
  }

  // InstructionSelect visits a block's instructions in reverse order, so
  // the terminator immediately after this G_BRCOND may already have been
  // independently selected into `BEQ_UNCOND R0,R0,%bb.false` by selectBr,
  // or may still be the original generic G_BR %bb.false. Handle both: the
  // false-target operand sits at index 0 for G_BR, index 2 for a
  // BEQ_UNCOND.
  MachineInstr &Next = *NextIt;
  unsigned FalseMBBOpIdx;
  if (Next.getOpcode() == TargetOpcode::G_BR) {
    FalseMBBOpIdx = 0;
  } else {
    assert(Next.getOpcode() == LC2K::BEQ_UNCOND &&
           "expected G_BRCOND's sibling terminator to be an unconditional "
           "branch");
    FalseMBBOpIdx = 2;
  }
  MachineBasicBlock *FalseMBB = Next.getOperand(FalseMBBOpIdx).getMBB();

  // If Cond is produced by a same-block, single-use G_ICMP (always eq/ne --
  // legalizeICmp routes every relational predicate to a libcall before isel
  // ever runs, see LC2KLegalizerInfo::legalizeICmp), fuse the compare
  // directly into this branch instead of first materializing it into a real
  // 0/1 register via PSEUDO_CMP01 (a whole extra compare-and-branch-and-PHI
  // sequence) and then branching on *that*. This collapses what would
  // otherwise be two independent compare-and-branch sequences (up to 4
  // BEQs) into a single one (1-2 BEQs).
  MachineInstr *CmpMI = MRI.getVRegDef(Cond);
  if (CmpMI->getOpcode() == TargetOpcode::G_ICMP &&
      CmpMI->getParent() == &MBB && MRI.hasOneUse(Cond)) {
    auto &Cmp = cast<GICmp>(*CmpMI);
    assert((Cmp.getCond() == CmpInst::ICMP_EQ ||
            Cmp.getCond() == CmpInst::ICMP_NE) &&
           "relational icmp predicates should have been legalized to "
           "libcalls");
    bool IsEq = Cmp.getCond() == CmpInst::ICMP_EQ;
    // When equal, take the branch target of whichever side the comparison
    // is actually equivalent to (the BRCOND's own true target for `eq`, the
    // sibling unconditional branch's target for `ne`); redirect that
    // sibling branch to the true target when it isn't already going there.
    MachineBasicBlock *EqMBB = IsEq ? TrueMBB : FalseMBB;
    if (!IsEq)
      Next.getOperand(FalseMBBOpIdx).setMBB(TrueMBB);
    constrain(BuildMI(MBB, I, I.getDebugLoc(), TII.get(LC2K::BEQ))
                  .addReg(Cmp.getLHSReg())
                  .addReg(Cmp.getRHSReg())
                  .addMBB(EqMBB));
    CmpMI->eraseFromParent();
    I.eraseFromParent();
    return true;
  }

  // LC2K only has "branch if equal": branch to the false target when the
  // (always exactly 0/1) condition is 0, and redirect the existing
  // unconditional branch -- which already goes wherever "otherwise" should
  // go -- to the true target instead.
  Next.getOperand(FalseMBBOpIdx).setMBB(TrueMBB);
  constrain(BuildMI(MBB, I, I.getDebugLoc(), TII.get(LC2K::BEQ))
                .addReg(Cond)
                .addReg(LC2K::R0)
                .addMBB(FalseMBB));

  I.eraseFromParent();
  return true;
}

bool LC2KInstructionSelector::selectBr(MachineInstr &I) const {
  MachineBasicBlock *Target = I.getOperand(0).getMBB();
  // LC2K has no dedicated unconditional jump; BEQ_UNCOND R0,R0 (encoded
  // identically to a real BEQ, see LC2KInstrInfo.td) is always taken.
  constrain(BuildMI(*I.getParent(), I, I.getDebugLoc(),
                    TII.get(LC2K::BEQ_UNCOND))
                .addReg(LC2K::R0)
                .addReg(LC2K::R0)
                .addMBB(Target));
  I.eraseFromParent();
  return true;
}

bool LC2KInstructionSelector::selectSelect(MachineInstr &I) const {
  auto &Sel = cast<GSelect>(I);
  // Same rationale as selectICmp above: LC2K has no conditional move, so
  // this needs real control flow, which is unsafe to build while
  // InstructionSelect is itself mid-traversal of the CFG. Emit a
  // placeholder for LC2KExpandPseudos to expand later instead.
  constrain(BuildMI(*I.getParent(), I, I.getDebugLoc(),
                    TII.get(LC2K::PSEUDO_SELECT), Sel.getReg(0))
                .addReg(Sel.getCondReg())
                .addReg(Sel.getTrueReg())
                .addReg(Sel.getFalseReg()));
  I.eraseFromParent();
  return true;
}

bool LC2KInstructionSelector::selectTrunc(MachineInstr &I) const {
  // Only ever used to narrow an s32 relational-icmp libcall result back to
  // nominal s1; both are stored as a full word, so this is a no-op copy.
  Register Dst = I.getOperand(0).getReg();
  Register Src = I.getOperand(1).getReg();
  constrain(BuildMI(*I.getParent(), I, I.getDebugLoc(),
                    TII.get(TargetOpcode::COPY), Dst)
                .addReg(Src));
  I.eraseFromParent();
  return true;
}

bool LC2KInstructionSelector::selectZExtAnyExt(MachineInstr &I) const {
  // s1 values are always materialized as canonical 0/1 in a full word (see
  // selectICmp), so both a zero-extension and an "any" extension of one are
  // already correct as-is: a no-op copy.
  //
  // COPY has no fixed register class in its MCInstrDesc, so constrain()
  // (constrainSelectedInstRegOperands) is a no-op on both of its operands --
  // Src gets a class from its own defining instruction, but Dst does not
  // unless something explicitly assigns one, exactly like the top-level
  // COPY case in selectGeneric above.
  MachineRegisterInfo &MRI = I.getMF()->getRegInfo();
  Register Dst = I.getOperand(0).getReg();
  Register Src = I.getOperand(1).getReg();
  BuildMI(*I.getParent(), I, I.getDebugLoc(), TII.get(TargetOpcode::COPY),
         Dst)
      .addReg(Src);
  I.eraseFromParent();
  return RBI.constrainGenericRegister(Dst, LC2K::GPRRegClass, MRI) != nullptr;
}

bool LC2KInstructionSelector::selectPtrIntCast(MachineInstr &I) const {
  // Pointers and s32 integers are both 32-bit values in the same (only)
  // register bank/class on LC2K (a flat, word-addressed address space with
  // no pointer tagging), so a G_PTRTOINT/G_INTTOPTR is a pure
  // reinterpretation of the same bits: a no-op copy, exactly like
  // selectZExtAnyExt/selectTrunc above.
  MachineRegisterInfo &MRI = I.getMF()->getRegInfo();
  Register Dst = I.getOperand(0).getReg();
  Register Src = I.getOperand(1).getReg();
  BuildMI(*I.getParent(), I, I.getDebugLoc(), TII.get(TargetOpcode::COPY),
         Dst)
      .addReg(Src);
  I.eraseFromParent();
  return RBI.constrainGenericRegister(Dst, LC2K::GPRRegClass, MRI) != nullptr;
}

bool LC2KInstructionSelector::selectSExt(MachineInstr &I) const {
  // s1 values are canonical 0/1 (see selectICmp). Sign-extending a 1-bit
  // value replicates its single (sign) bit, so true (1) must become -1
  // (0xFFFFFFFF), not 1 -- i.e. this is two's-complement negation:
  // -0 == 0, -1 == 0xFFFFFFFF. Same NOT-then-increment idiom as selectSub.
  MachineBasicBlock &MBB = *I.getParent();
  MachineRegisterInfo &MRI = I.getMF()->getRegInfo();
  DebugLoc DL = I.getDebugLoc();
  Register Dst = I.getOperand(0).getReg();
  Register Src = I.getOperand(1).getReg();

  Register NotSrc = MRI.createVirtualRegister(&LC2K::GPRRegClass);
  constrain(BuildMI(MBB, I, DL, TII.get(LC2K::NOR), NotSrc)
                .addReg(Src)
                .addReg(Src));
  constrain(BuildMI(MBB, I, DL, TII.get(LC2K::ADDI), Dst)
                .addReg(NotSrc)
                .addImm(1));
  I.eraseFromParent();
  return true;
}

bool LC2KInstructionSelector::selectCall(MachineInstr &I) const {
  // Real lowering of the CALL pseudo to JALR_CALL R15, $callee (JALR_CALL,
  // not JALR: same encoding, but JALR is marked isTerminator/isReturn for
  // its use as a return, which a call -- not the end of its block -- must
  // not be).
  auto MIB =
      BuildMI(*I.getParent(), I, I.getDebugLoc(), TII.get(LC2K::JALR_CALL))
                .addReg(LC2K::RA, RegState::Define)
                .addReg(I.getOperand(0).getReg());
  // Preserve the regmask and the implicit arg-use/ret-def operands
  // LC2KCallLowering attached to the pseudo; skip the pseudo's own
  // implicit-def of RA (from `Defs = [R15]`), now represented explicitly
  // above.
  for (unsigned Idx = 1, End = I.getNumOperands(); Idx != End; ++Idx) {
    MachineOperand &MO = I.getOperand(Idx);
    if (MO.isReg() && MO.isImplicit() && MO.isDef() && MO.getReg() == LC2K::RA)
      continue;
    MIB.add(MO);
  }
  constrain(MIB);
  I.eraseFromParent();
  return true;
}

bool LC2KInstructionSelector::selectAddrEs(MachineInstr &I) const {
  Register Dst = I.getOperand(0).getReg();
  materializeSymbolAddress(Dst, I.getOperand(1), I);
  I.eraseFromParent();
  return true;
}

namespace llvm {
InstructionSelector *
createLC2KInstructionSelector(const LC2KTargetMachine &TM,
                              const LC2KSubtarget &Subtarget,
                              const LC2KRegisterBankInfo &RBI) {
  return new LC2KInstructionSelector(TM, Subtarget, RBI);
}
} // namespace llvm
