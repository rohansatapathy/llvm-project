//===-- LC2KAsmPrinter.cpp - LC2K LLVM assembly writer ---------*- C++ -*--===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains a printer that converts from our internal representation
// of machine-dependent LLVM code to the LC2K assembly language.
//
//===----------------------------------------------------------------------===//

#include "LC2KAsmPrinter.h"

#include "LC2K.h"
#include "LC2KInstrInfo.h"
#include "TargetInfo/LC2KTargetInfo.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineConstantPool.h"
#include "llvm/CodeGen/MachineOperand.h"
#include "llvm/IR/Module.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Pass.h"

using namespace llvm;

#define DEBUG_TYPE "asm-printer"

MCOperand LC2KAsmPrinter::lowerOperand(const MachineOperand &MO) {
  switch (MO.getType()) {
  case MachineOperand::MO_Register:
    return MCOperand::createReg(MO.getReg());
  case MachineOperand::MO_Immediate:
    return MCOperand::createImm(MO.getImm());
  case MachineOperand::MO_MachineBasicBlock:
    return MCOperand::createExpr(
        MCSymbolRefExpr::create(MO.getMBB()->getSymbol(), OutContext));
  case MachineOperand::MO_ExternalSymbol:
    return lowerSymbolOperand(MO, GetExternalSymbolSymbol(MO.getSymbolName()));
  case MachineOperand::MO_GlobalAddress:
    return lowerSymbolOperand(MO, getSymbolPreferLocal(*MO.getGlobal()));
  case MachineOperand::MO_BlockAddress:
    return lowerSymbolOperand(MO, GetBlockAddressSymbol(MO.getBlockAddress()));
  case MachineOperand::MO_JumpTableIndex:
    return lowerSymbolOperand(MO, GetJTISymbol(MO.getIndex()));
  case MachineOperand::MO_ConstantPoolIndex:
    return lowerSymbolOperand(MO, GetCPISymbol(MO.getIndex()));
  default:
    llvm_unreachable("unknown operand type");
  }
}

MCOperand LC2KAsmPrinter::lowerSymbolOperand(const MachineOperand &MO,
                                             MCSymbol *Sym) const {

  const MCExpr *Expr = MCSymbolRefExpr::create(Sym, OutContext);

  if (!MO.isJTI() && !MO.isMBB() && MO.getOffset() != 0) {
    llvm_unreachable("unknown symbol op");
  }

  return MCOperand::createExpr(Expr);
}

void LC2KAsmPrinter::emitInstruction(const MachineInstr *MI) {
  // PSEUDO_LA's wide-address materialization only has a representation in
  // the object-file (-filetype=obj) pipeline: it depends entirely on
  // relocations (fixup_lc2k_hi12/fixup_lc2k_lo20, hand-encoded by
  // LC2KMCCodeEmitter) to express "half of a symbol's address" -- a
  // concept the plain positional text syntax LC2KAsmStreamer emits (meant
  // to be fed to the course's own external assembler) has no way to
  // spell at all, no matter how early it's expanded. On the text-only
  // path (LC2KAsmStreamer::hasRawTextSupport()), fall back to the
  // original single-ADDI form instead -- text output was never able to
  // benefit from wide-address support in the first place (that assembler
  // presumably has the exact same 20-bit-field limitation this whole
  // feature works around, just with no relocations to defer the problem
  // to), so this simply preserves its pre-existing behavior.
  if (MI->getOpcode() == LC2K::PSEUDO_LA && OutStreamer->hasRawTextSupport()) {
    MCInst Inst;
    Inst.setOpcode(LC2K::ADDI);
    Inst.addOperand(lowerOperand(MI->getOperand(0)));
    Inst.addOperand(lowerOperand(MI->getOperand(1)));
    Inst.addOperand(lowerOperand(MI->getOperand(2)));
    EmitToStreamer(*OutStreamer, Inst);
    return;
  }

  MCInst Inst;

  Inst.setOpcode(MI->getOpcode());

  for (const MachineOperand &MO : MI->explicit_operands()) {
    MCOperand MCOp = lowerOperand(MO);
    Inst.addOperand(MCOp);
  }

  EmitToStreamer(*OutStreamer, Inst);
}

void LC2KAsmPrinter::emitConstantPool() {
  const MachineConstantPool *MCP = MF->getConstantPool();
  const std::vector<MachineConstantPoolEntry> &CP = MCP->getConstants();
  for (unsigned I = 0, E = CP.size(); I != E; ++I) {
    const MachineConstantPoolEntry &CPE = CP[I];
    assert(!CPE.isMachineConstantPoolEntry() &&
           "LC2K never creates target-specific constant pool values");
    DeferredConstantPool.push_back({GetCPISymbol(I), CPE.Val.ConstVal});
  }
}

bool LC2KAsmPrinter::doFinalization(Module &M) {
  // Must run before AsmPrinter::doFinalization(M), which ends by calling
  // OutStreamer->finish() -- emitting anything after that point is
  // undefined behavior.
  for (const DeferredConstantPoolEntry &Entry : DeferredConstantPool) {
    OutStreamer->emitLabel(Entry.Sym);
    emitGlobalConstant(M.getDataLayout(), Entry.Val);
  }
  return AsmPrinter::doFinalization(M);
}

char LC2KAsmPrinter::ID = 0;

INITIALIZE_PASS(LC2KAsmPrinter, "lc2k-asm-printer", "LC2K Assembly Printer",
                false, false)

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void
LLVMInitializeLC2KAsmPrinter() { // NOLINT
  RegisterAsmPrinter<LC2KAsmPrinter> X(getTheLC2KTarget());
}
