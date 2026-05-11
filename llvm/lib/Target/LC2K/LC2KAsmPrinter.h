//===-- LC2KAsmPrinter.h - LC2K LLVM Assembly Printer -----------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file contains LC2K assembler printer declarations.
///
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LC2K_LC2KASMPRINTER_H
#define LLVM_LIB_TARGET_LC2K_LC2KASMPRINTER_H

#include "llvm/CodeGen/AsmPrinter.h"

namespace llvm {

class LC2KAsmPrinter : public AsmPrinter {
public:
  static char ID;

public:
  LC2KAsmPrinter(TargetMachine &TM, std::unique_ptr<MCStreamer> Streamer)
      : AsmPrinter(TM, std::move(Streamer), ID) {}

  void emitInstruction(const MachineInstr *MI) override;

private:
  MCOperand lowerOperand(const MachineOperand &MO);

  MCOperand lowerSymbolOperand(const MachineOperand &MO, MCSymbol *Sym) const;
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_LC2K_LC2KASMPRINTER_H
