//===-- LC2KLegalizerInfo.cpp -----------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file implements the targeting of the LegalizerInfo class for LC2K.
///
//===----------------------------------------------------------------------===//

#include "LC2KLegalizerInfo.h"
#include "llvm/CodeGen/GlobalISel/GenericMachineInstrs.h"
#include "llvm/CodeGen/GlobalISel/LegalizerHelper.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/IR/DerivedTypes.h"

#define DEBUG_TYPE "lc2k-legalizer-info"

using namespace llvm;

LC2KLegalizerInfo::LC2KLegalizerInfo(const LC2KSubtarget &ST) {
  using namespace TargetOpcode;

  const LLT s1 = LLT::scalar(1);
  const LLT s32 = LLT::scalar(32);
  const LLT p0 = LLT::pointer(0, 32);

  // LC2K's only integer type is a 32-bit word: char/short/int are all 32
  // bits wide at the Clang target level, so the frontend never produces
  // narrower integer types for real source programs. Anything narrower than
  // s32 is deliberately left with no rule below, so legalization fails
  // loudly if it's ever produced instead of being silently miscompiled.

  getActionDefinitionsBuilder(G_CONSTANT).legalFor({s32});

  getActionDefinitionsBuilder(G_IMPLICIT_DEF).legalFor({s32, p0});

  getActionDefinitionsBuilder(G_BR).alwaysLegal();

  getActionDefinitionsBuilder(G_PHI).legalFor({s32, p0});

  getActionDefinitionsBuilder(G_FRAME_INDEX).legalFor({p0});

  getActionDefinitionsBuilder(G_GLOBAL_VALUE).legalFor({p0});

  getActionDefinitionsBuilder(G_PTR_ADD).legalFor({{p0, s32}});

  getActionDefinitionsBuilder(G_ADD).legalFor({s32});

  // LC2K has no SUB/AND/OR/XOR instructions, only ADD and NOR. Each of these
  // is still synthesizable from ADD/NOR in a small fixed number of
  // instructions (no loop or runtime call needed), so they're legalized here
  // and left for instruction selection to expand into the real NOR/ADD
  // sequences.
  getActionDefinitionsBuilder({G_SUB, G_AND, G_OR, G_XOR}).legalFor({s32});

  getActionDefinitionsBuilder({G_LOAD, G_STORE})
      .legalFor({{s32, p0}, {p0, p0}});

  // LC2K has no multiply or divide/remainder hardware. These are lowered to
  // calls to the standard compiler-rt/libgcc runtime routines.
  getActionDefinitionsBuilder({G_MUL, G_SDIV, G_UDIV, G_SREM, G_UREM})
      .libcallFor({s32});

  // LC2K has no shift instructions at all. Unlike the arithmetic ops above,
  // there's no standard RTLIB call for a plain integer shift (virtually
  // every other target has real shift hardware), so these are lowered to
  // calls to our own runtime routines via legalizeCustom below.
  getActionDefinitionsBuilder({G_SHL, G_LSHR, G_ASHR}).customFor({s32});

  // LC2K's only compare-and-branch instruction is BEQ: there's no hardware
  // support for any relational comparison (<,<=,>,>=, signed or unsigned).
  // EQ/NE map onto BEQ directly (or its inverse) in a fixed, cheap
  // instruction sequence, so those are left alone by legalizeCustom below
  // (deferred to instruction selection, like G_SUB/G_AND/G_OR/G_XOR above).
  // The 8 relational predicates have no cheap hardware realization at all
  // (would need a bit-serial software comparison), so those are rewritten
  // into calls to just two runtime primitives -- signed and unsigned
  // less-than -- with the other 6 predicates derived via operand-swapping
  // and result negation.
  getActionDefinitionsBuilder(G_ICMP).customFor({{s1, s32}});

  // G_BRCOND and G_SELECT are also cheap to synthesize from BEQ (materialize
  // a zero constant and branch, or a short 2-way branch sequence) in a fixed
  // number of instructions, so like G_SUB/G_AND/G_OR/G_XOR these are left
  // legal and deferred to instruction selection.
  getActionDefinitionsBuilder(G_BRCOND).legalFor({s1});
  getActionDefinitionsBuilder(G_SELECT).legalFor({{s32, s1}});

  // Needed only to convert the s32 value a relational G_ICMP call produces
  // back down to its nominal s1 result type -- not a general reopening of
  // narrow-type support (see the s32-only note above).
  getActionDefinitionsBuilder(G_TRUNC).legalFor({{s1, s32}});

  getLegacyLegalizerInfo().computeTables();
}

bool LC2KLegalizerInfo::legalizeCustom(LegalizerHelper &Helper,
                                       MachineInstr &MI,
                                       LostDebugLocObserver &LocObserver) const {
  switch (MI.getOpcode()) {
  case TargetOpcode::G_SHL:
  case TargetOpcode::G_LSHR:
  case TargetOpcode::G_ASHR:
    return legalizeShift(Helper, MI, LocObserver);
  case TargetOpcode::G_ICMP:
    return legalizeICmp(Helper, MI, LocObserver);
  default:
    return false;
  }
}

bool LC2KLegalizerInfo::legalizeShift(
    LegalizerHelper &Helper, MachineInstr &MI,
    LostDebugLocObserver &LocObserver) const {
  const char *Name;
  switch (MI.getOpcode()) {
  case TargetOpcode::G_SHL:
    Name = "__lc2k_shl";
    break;
  case TargetOpcode::G_LSHR:
    Name = "__lc2k_lshr";
    break;
  case TargetOpcode::G_ASHR:
    Name = "__lc2k_ashr";
    break;
  default:
    llvm_unreachable("Unexpected opcode");
  }

  Type *S32Ty = IntegerType::get(MI.getMF()->getFunction().getContext(), 32);
  CallLowering::ArgInfo Result = {MI.getOperand(0).getReg(), S32Ty, 0};
  SmallVector<CallLowering::ArgInfo, 2> Args = {
      {MI.getOperand(1).getReg(), S32Ty, 0},
      {MI.getOperand(2).getReg(), S32Ty, 0}};

  // Unlike LegalizerHelper::libcall(), the Custom legalization action does
  // not erase MI on success automatically -- that's the custom
  // implementation's own responsibility.
  if (Helper.createLibcall(Name, Result, Args, CallingConv::C, LocObserver,
                           &MI) != LegalizerHelper::Legalized)
    return false;

  MI.eraseFromParent();
  return true;
}

bool LC2KLegalizerInfo::legalizeICmp(
    LegalizerHelper &Helper, MachineInstr &MI,
    LostDebugLocObserver &LocObserver) const {
  auto &Cmp = cast<GICmp>(MI);
  CmpInst::Predicate Pred = Cmp.getCond();

  // EQ/NE map directly onto BEQ (or its inverse); leave them legal and
  // defer synthesis to instruction selection.
  if (Pred == CmpInst::ICMP_EQ || Pred == CmpInst::ICMP_NE)
    return true;

  const char *Name;
  Register LHS = Cmp.getLHSReg();
  Register RHS = Cmp.getRHSReg();
  bool Negate;
  switch (Pred) {
  case CmpInst::ICMP_SLT:
    Name = "__lc2k_slt";
    Negate = false;
    break;
  case CmpInst::ICMP_SGT:
    Name = "__lc2k_slt";
    std::swap(LHS, RHS);
    Negate = false;
    break;
  case CmpInst::ICMP_SLE:
    Name = "__lc2k_slt";
    std::swap(LHS, RHS);
    Negate = true;
    break;
  case CmpInst::ICMP_SGE:
    Name = "__lc2k_slt";
    Negate = true;
    break;
  case CmpInst::ICMP_ULT:
    Name = "__lc2k_ult";
    Negate = false;
    break;
  case CmpInst::ICMP_UGT:
    Name = "__lc2k_ult";
    std::swap(LHS, RHS);
    Negate = false;
    break;
  case CmpInst::ICMP_ULE:
    Name = "__lc2k_ult";
    std::swap(LHS, RHS);
    Negate = true;
    break;
  case CmpInst::ICMP_UGE:
    Name = "__lc2k_ult";
    Negate = true;
    break;
  default:
    llvm_unreachable("Unexpected ICmp predicate");
  }

  MachineIRBuilder &MIRBuilder = Helper.MIRBuilder;
  MachineRegisterInfo &MRI = *MIRBuilder.getMRI();
  LLT S32 = LLT::scalar(32);

  Type *S32Ty = IntegerType::get(MI.getMF()->getFunction().getContext(), 32);
  Register CallResult = MRI.createGenericVirtualRegister(S32);
  CallLowering::ArgInfo Result = {CallResult, S32Ty, 0};
  SmallVector<CallLowering::ArgInfo, 2> Args = {{LHS, S32Ty, 0},
                                                {RHS, S32Ty, 0}};

  if (Helper.createLibcall(Name, Result, Args, CallingConv::C, LocObserver,
                           &MI) != LegalizerHelper::Legalized)
    return false;

  Register FinalValue = CallResult;
  if (Negate) {
    auto One = MIRBuilder.buildConstant(S32, 1);
    FinalValue = MIRBuilder.buildXor(S32, CallResult, One).getReg(0);
  }

  MIRBuilder.buildTrunc(MI.getOperand(0).getReg(), FinalValue);

  MI.eraseFromParent();
  return true;
}
