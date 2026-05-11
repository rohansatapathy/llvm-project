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
#include "TargetInfo/LC2KTargetInfo.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineOperand.h"
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
  MCInst Inst;

  Inst.setOpcode(MI->getOpcode());

  for (const MachineOperand &MO : MI->explicit_operands()) {
    MCOperand MCOp = lowerOperand(MO);
    Inst.addOperand(MCOp);
  }

  EmitToStreamer(*OutStreamer, Inst);
}

char LC2KAsmPrinter::ID = 0;

INITIALIZE_PASS(LC2KAsmPrinter, "lc2k-asm-printer", "LC2K Assembly Printer",
                false, false)

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void
LLVMInitializeLC2KAsmPrinter() { // NOLINT
  RegisterAsmPrinter<LC2KAsmPrinter> X(getTheLC2KTarget());
}
