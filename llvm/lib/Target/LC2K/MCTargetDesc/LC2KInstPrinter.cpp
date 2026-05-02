//===-- LC2KInstPrinter.cpp - Convert LC2K MCInst to asm --------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file contains definitions for an LC2K MCInst printer.
///
//===----------------------------------------------------------------------===//

#include "LC2KInstPrinter.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCInst.h"
#include "llvm/Support/ErrorHandling.h"

using namespace llvm;

#include "LC2KGenAsmWriter.inc"

void LC2KInstPrinter::printInst(const MCInst *MI, uint64_t Address,
                                StringRef Annot, const MCSubtargetInfo &STI,
                                raw_ostream &O) {
  printInstruction(MI, Address, O);
  printAnnotation(O, Annot);
}

void LC2KInstPrinter::printRegName(raw_ostream &OS, MCRegister Reg) {
  // In LC2K, registers are printed as their raw register number without
  // prefix.
  OS << getRegisterName(Reg);
}

void LC2KInstPrinter::printOperand(const MCInst *MI, unsigned OpNo,
                                   raw_ostream &O) {
  const MCOperand &MO = MI->getOperand(OpNo);

  if (MO.isReg()) {
    printRegName(O, MO.getReg());
    return;
  }

  if (MO.isImm()) {
    printImmediate(O, MO.getImm());
    return;
  }

  if (MO.isExpr()) {
    MAI.printExpr(O, *MO.getExpr());
    return;
  }

  report_fatal_error("unknown operand kind in LC2K printOperand");
}

void LC2KInstPrinter::printImmediate(raw_ostream &O, int64_t Imm) { O << Imm; }
