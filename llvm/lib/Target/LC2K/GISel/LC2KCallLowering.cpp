//===-- LC2KCallLowering.cpp - Call lowering for GlobalISel -----*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file implements the lowering of LLVM calls to machine code calls for
/// GlobalISel.
///
//===----------------------------------------------------------------------===//

#include "LC2KCallLowering.h"
#include "LC2KISelLowering.h"
#include "LC2KInstrInfo.h"
#include "LC2KMachineFunctionInfo.h"
#include "LC2KRegisterInfo.h"
#include "LC2KSubtarget.h"
#include "llvm/CodeGen/FunctionLoweringInfo.h"
#include "llvm/CodeGen/GlobalISel/MachineIRBuilder.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/IR/Attributes.h"
#include "llvm/Support/Alignment.h"
#include "llvm/Support/MathExtras.h"

#define DEBUG_TYPE "lck2-call-lowering"

using namespace llvm;

#include "LC2KGenCallingConv.inc"

namespace {

struct LC2KOutgoingValueAssigner : public CallLowering::OutgoingValueAssigner {
  LC2KOutgoingValueAssigner(CCAssignFn *AssignFn)
      : CallLowering::OutgoingValueAssigner(AssignFn) {}
};

struct LC2KOutgoingArgHandler : public CallLowering::OutgoingValueHandler {

  /// Construct the LC2KOutgoingArgHandler.
  ///
  /// This constructor assumes that the MIB is pointing to the about-to-be
  /// -added call or return instruction.
  LC2KOutgoingArgHandler(MachineIRBuilder &B, MachineRegisterInfo &MRI,
                         MachineInstrBuilder MIB)
      : CallLowering::OutgoingValueHandler(B, MRI), MIB(MIB) {}

  Register getStackAddress(uint64_t MemSize, int64_t Offset,
                           MachinePointerInfo &MPO,
                           ISD::ArgFlagsTy Flags) override {
    MachineFunction &MF = MIRBuilder.getMF();
    LLT AddrDest = LLT::pointer(0, 32);
    LLT OffsetDest = LLT::scalar(32);

    assert(isInt<32>(Offset) && "stack offset should fit in 32 bits");

    // SP is a physical register, so it has no LLT recorded in MRI -- it
    // can't be used directly as a generic G_PTR_ADD operand. Copy it into a
    // properly-typed vreg first (once per handler instance, since a call
    // can have multiple stack-passed arguments).
    if (!SPReg)
      SPReg = MIRBuilder.buildCopy(AddrDest, Register(LC2K::SP)).getReg(0);

    auto OffsetReg = MIRBuilder.buildConstant(OffsetDest, Offset);

    auto AddrReg = MIRBuilder.buildPtrAdd(AddrDest, SPReg, OffsetReg);

    MPO = MachinePointerInfo::getStack(MF, Offset);

    return AddrReg.getReg(0);
  }

  void assignValueToAddress(Register ValVReg, Register Addr, LLT MemTy,
                            const MachinePointerInfo &MPO,
                            const CCValAssign &VA) override {
    MachineFunction &MF = MIRBuilder.getMF();
    uint64_t LocMemOffset = VA.getLocMemOffset();

    auto *MMO =
        MF.getMachineMemOperand(MPO, MachineMemOperand::MOStore, MemTy,
                                commonAlignment(Align(4), LocMemOffset));

    Register ExtReg = extendRegister(ValVReg, VA);
    MIRBuilder.buildStore(ExtReg, Addr, *MMO);
  }

  void assignValueToReg(Register ValVReg, Register PhysReg,
                        const CCValAssign &VA,
                        ISD::ArgFlagsTy Flags) override {
    Register ExtReg = extendRegister(ValVReg, VA);
    MIRBuilder.buildCopy(PhysReg, ExtReg);
    // NOTE: Call args are implicit b/c args are not encoded within actual
    // assembly call instruction (i.e. JALR).
    MIB.addUse(PhysReg, RegState::Implicit);
  }

private:
  MachineInstrBuilder MIB;

  // Cache the SP register vreg if we need it more than once in this call
  // site.
  Register SPReg;
};

struct LC2KIncomingValueAssigner : public CallLowering::IncomingValueAssigner {
  LC2KIncomingValueAssigner(CCAssignFn *AssignFn)
      : CallLowering::IncomingValueAssigner(AssignFn) {}
};

struct LC2KIncomingArgHandler : public CallLowering::IncomingValueHandler {

  LC2KIncomingArgHandler(MachineIRBuilder &B, MachineRegisterInfo &MRI)
      : CallLowering::IncomingValueHandler(B, MRI) {}

  Register getStackAddress(uint64_t MemSize, int64_t Offset,
                           MachinePointerInfo &MPO,
                           ISD::ArgFlagsTy Flags) override {
    auto &MFI = MIRBuilder.getMF().getFrameInfo();

    // Byval is assumed to be writable memory, but other stack passed arguments
    // are not.
    const bool IsImmutable = !Flags.isByVal();

    int FI = MFI.CreateFixedObject(MemSize, Offset, IsImmutable);
    MPO = MachinePointerInfo::getFixedStack(MIRBuilder.getMF(), FI);
    auto AddrReg = MIRBuilder.buildFrameIndex(LLT::pointer(0, 32), FI);

    return AddrReg.getReg(0);
  }

  void assignValueToAddress(Register ValVReg, Register Addr, LLT MemTy,
                            const MachinePointerInfo &MPO,
                            const CCValAssign &VA) override {
    MachineFunction &MF = MIRBuilder.getMF();
    auto *MMO = MF.getMachineMemOperand(MPO, MachineMemOperand::MOLoad, MemTy,
                                        inferAlignFromPtrInfo(MF, MPO));
    MIRBuilder.buildLoad(ValVReg, Addr, *MMO);
  }

  void assignValueToReg(Register ValVReg, Register PhysReg,
                        const CCValAssign &VA,
                        ISD::ArgFlagsTy Flags) override {
    markRegUsed(PhysReg);
    IncomingValueHandler::assignValueToReg(ValVReg, PhysReg, VA, Flags);
  }

  /// How the physical register gets marked varies between formal
  /// parameters (it's a basic-block live-in), and a call instruction
  /// (it's an implicit-def of the call).
  virtual void markRegUsed(Register Reg) = 0;
};

struct LC2KFormalArgHandler : public LC2KIncomingArgHandler {
  LC2KFormalArgHandler(MachineIRBuilder &B, MachineRegisterInfo &MRI)
      : LC2KIncomingArgHandler(B, MRI) {}

  void markRegUsed(Register Reg) override {
    MIRBuilder.getMRI()->addLiveIn(Reg.asMCReg());
    MIRBuilder.getMBB().addLiveIn(Reg.asMCReg());
  }
};

struct LC2KCallReturnHandler : public LC2KIncomingArgHandler {
  LC2KCallReturnHandler(MachineIRBuilder &B, MachineRegisterInfo &MRI,
                        MachineInstrBuilder MIB)
      : LC2KIncomingArgHandler(B, MRI), MIB(MIB) {}

  void markRegUsed(Register Reg) override {
    MIB.addDef(Reg, RegState::Implicit);
  }

private:
  MachineInstrBuilder MIB;
};

} // namespace

LC2KCallLowering::LC2KCallLowering(const LC2KTargetLowering &TLI)
    : CallLowering(&TLI) {}

bool LC2KCallLowering::canLowerReturn(MachineFunction &MF,
                                      CallingConv::ID CallConv,
                                      SmallVectorImpl<BaseArgInfo> &Outs,
                                      bool IsVarArg) const {
  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, IsVarArg, MF, ArgLocs,
                 MF.getFunction().getContext());
  return checkReturn(CCInfo, Outs, RetCC_LC2K);
}

bool LC2KCallLowering::lowerReturn(MachineIRBuilder &MIRBuilder,
                                   const Value *Val, ArrayRef<Register> VRegs,
                                   FunctionLoweringInfo &FLI,
                                   Register SwiftErrorVReg) const {
  assert(!SwiftErrorVReg && "attempt to use unsupported swifterror");
  assert(!Val == VRegs.empty() && "Return value without a vreg");

  MachineInstrBuilder Ret = MIRBuilder.buildInstrNoInsert(LC2K::JALR)
                                .addReg(LC2K::R0, RegState::Define)
                                .addReg(LC2K::RA, RegState::Kill);

  if (!FLI.CanLowerReturn) {
    // Too many values to lower in registers alone. Return values are stored in
    // caller-allocated region pointed to by implicit sret arg.
    insertSRetStores(MIRBuilder, Val->getType(), VRegs, FLI.DemoteRegister);
  } else if (!VRegs.empty()) {
    MachineFunction &MF = MIRBuilder.getMF();
    const DataLayout &DL = MF.getDataLayout();
    const Function &F = MF.getFunction();
    CallingConv::ID CC = F.getCallingConv();

    ArgInfo OrigRetInfo(VRegs, Val->getType(), 0);
    setArgFlags(OrigRetInfo, AttributeList::ReturnIndex, DL, F);

    SmallVector<ArgInfo, 4> SplitRetInfos;
    splitToValueTypes(OrigRetInfo, SplitRetInfos, DL, CC);

    LC2KOutgoingValueAssigner Assigner(RetCC_LC2K);
    LC2KOutgoingArgHandler Handler(MIRBuilder, MF.getRegInfo(), Ret);
    if (!determineAndHandleAssignments(Handler, Assigner, SplitRetInfos,
                                       MIRBuilder, CC, F.isVarArg()))
      return false;
  }

  MIRBuilder.insertInstr(Ret);
  return true;
}

bool LC2KCallLowering::lowerFormalArguments(MachineIRBuilder &MIRBuilder,
                                            const Function &F,
                                            ArrayRef<ArrayRef<Register>> VRegs,
                                            FunctionLoweringInfo &FLI) const {
  MachineFunction &MF = MIRBuilder.getMF();
  MachineRegisterInfo &MRI = MF.getRegInfo();
  const DataLayout &DL = MF.getDataLayout();
  CallingConv::ID CC = F.getCallingConv();

  SmallVector<ArgInfo, 32> SplitArgInfos;

  // Insert the hidden sret parameter if the return value won't fit in the
  // return register.
  if (!FLI.CanLowerReturn)
    insertSRetIncomingArgument(F, SplitArgInfos, FLI.DemoteRegister, MRI, DL);

  unsigned Index = 0;
  for (auto &Arg : F.args()) {
    // Construct the ArgInfo object from the destination vregs and the
    // argument's IR type.
    ArgInfo AInfo(VRegs[Index], Arg.getType(), Index);
    setArgFlags(AInfo, Index + AttributeList::FirstArgIndex, DL, F);

    // Handle any required splitting of aggregate/multi-part argument types
    // into the individual pieces CC_LC2K assigns locations to.
    splitToValueTypes(AInfo, SplitArgInfos, DL, CC);

    ++Index;
  }

  LC2KIncomingValueAssigner Assigner(CC_LC2K);
  LC2KFormalArgHandler Handler(MIRBuilder, MRI);
  if (!determineAndHandleAssignments(Handler, Assigner, SplitArgInfos,
                                     MIRBuilder, CC, F.isVarArg()))
    return false;

  if (F.isVarArg()) {
    // Every argument of a variadic function -- named or not -- is passed on
    // the stack (see CC_LC2K's CCIfNotVarArg guard), so Assigner.StackSize
    // at this point (after only the named arguments above have been
    // assigned) is exactly the offset where the first vararg would land.
    // Create a marker fixed-stack object there for G_VASTART to find later.
    MachineFrameInfo &MFI = MF.getFrameInfo();
    int FI = MFI.CreateFixedObject(4, Assigner.StackSize,
                                   /*IsImmutable=*/true);
    MF.getInfo<LC2KMachineFunctionInfo>()->setVarArgsFrameIndex(FI);
  }

  return true;
}

bool LC2KCallLowering::lowerCall(MachineIRBuilder &MIRBuilder,
                                 CallLoweringInfo &Info) const {
  MachineFunction &MF = MIRBuilder.getMF();
  const DataLayout &DL = MF.getDataLayout();
  CallingConv::ID CC = Info.CallConv;

  // TODO: Support tail calls.
  Info.IsTailCall = false;

  // CALL only takes a register operand, so a direct call to a global
  // function, or a call to a compiler-inserted runtime helper (e.g. a
  // libcall) by external symbol name, needs its address materialized into
  // a register first.
  MachineRegisterInfo &MRI = MF.getRegInfo();
  Register CalleeReg;
  if (Info.Callee.isReg()) {
    CalleeReg = Info.Callee.getReg();
  } else if (Info.Callee.isGlobal()) {
    LLT PtrTy = LLT::pointer(0, 32);
    CalleeReg =
        MIRBuilder.buildGlobalValue(PtrTy, Info.Callee.getGlobal()).getReg(0);
  } else if (Info.Callee.isSymbol()) {
    // ADDR_ES is a real (non-generic) pseudo whose def is already declared
    // GPR-class, so its destination register must be created as such
    // directly rather than as a generic vreg.
    CalleeReg = MRI.createVirtualRegister(&LC2K::GPRRegClass);
    MIRBuilder.buildInstr(LC2K::ADDR_ES)
        .addDef(CalleeReg)
        .addExternalSymbol(Info.Callee.getSymbolName());
  } else {
    return false;
  }

  const TargetInstrInfo *TII = MF.getSubtarget().getInstrInfo();
  MachineInstrBuilder CallSeqStart =
      MIRBuilder.buildInstr(TII->getCallFrameSetupOpcode());

  // CalleeReg is still a generic (register-class-unconstrained) vreg at
  // this point. CALL is a real (non-generic) pseudo, so its $callee operand
  // needs a concrete register class -- there's no RegisterBankInfo for
  // LC2K yet to do this via constrainOperandRegClass, but since we already
  // know we want GPR, a plain COPY into a GPR-class vreg does the same job.
  Register GPRCalleeReg = MRI.createVirtualRegister(&LC2K::GPRRegClass);
  MIRBuilder.buildCopy(GPRCalleeReg, CalleeReg);

  MachineInstrBuilder Call =
      MIRBuilder.buildInstrNoInsert(LC2K::CALL).addReg(GPRCalleeReg);

  const TargetRegisterInfo *TRI = MF.getSubtarget().getRegisterInfo();
  Call.addRegMask(TRI->getCallPreservedMask(MF, CC));

  SmallVector<ArgInfo, 32> SplitArgInfos;
  for (auto &AInfo : Info.OrigArgs) {
    // Handle any required unmerging of split value types from a given VReg
    // into physical registers. ArgInfo objects are constructed
    // correspondingly and appended to SplitArgInfos.
    splitToValueTypes(AInfo, SplitArgInfos, DL, CC);
  }

  LC2KOutgoingValueAssigner ArgAssigner(CC_LC2K);
  LC2KOutgoingArgHandler ArgHandler(MIRBuilder, MF.getRegInfo(), Call);
  if (!determineAndHandleAssignments(ArgHandler, ArgAssigner, SplitArgInfos,
                                     MIRBuilder, CC, Info.IsVarArg))
    return false;

  MIRBuilder.insertInstr(Call);

  CallSeqStart.addImm(ArgAssigner.StackSize).addImm(0);
  MIRBuilder.buildInstr(TII->getCallFrameDestroyOpcode())
      .addImm(ArgAssigner.StackSize)
      .addImm(0);

  if (Info.CanLowerReturn && !Info.OrigRet.Ty->isVoidTy()) {
    SmallVector<ArgInfo, 4> SplitRetInfos;
    splitToValueTypes(Info.OrigRet, SplitRetInfos, DL, CC);

    LC2KIncomingValueAssigner RetAssigner(RetCC_LC2K);
    LC2KCallReturnHandler RetHandler(MIRBuilder, MF.getRegInfo(), Call);
    if (!determineAndHandleAssignments(RetHandler, RetAssigner, SplitRetInfos,
                                       MIRBuilder, CC, Info.IsVarArg))
      return false;
  }

  if (!Info.CanLowerReturn)
    insertSRetLoads(MIRBuilder, Info.OrigRet.Ty, Info.OrigRet.Regs,
                    Info.DemoteRegister, Info.DemoteStackIndex);

  return true;
}
