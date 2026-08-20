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

#include "llvm/ADT/SmallVector.h"
#include "llvm/CodeGen/AsmPrinter.h"

namespace llvm {

class Constant;

class LC2KAsmPrinter : public AsmPrinter {
public:
  static char ID;

public:
  LC2KAsmPrinter(TargetMachine &TM, std::unique_ptr<MCStreamer> Streamer)
      : AsmPrinter(TM, std::move(Streamer), ID) {}

  void emitInstruction(const MachineInstr *MI) override;

  /// Overridden as a capture-only step instead of emitting immediately.
  /// The generic AsmPrinter emits each function's constant pool inline,
  /// right before that function's own instructions (see
  /// AsmPrinter::emitFunctionHeader) -- but LC2KAsmStreamer enforces a
  /// whole-module invariant that every instruction must precede every
  /// .fill directive, mirroring the flat, single-pass listing format of
  /// the real LC2K assembler (all code, then all constant data). Entries
  /// are recorded here and actually emitted once, after every function's
  /// code, from doFinalization.
  void emitConstantPool() override;

  bool doFinalization(Module &M) override;

private:
  MCOperand lowerOperand(const MachineOperand &MO);

  MCOperand lowerSymbolOperand(const MachineOperand &MO, MCSymbol *Sym) const;

  struct DeferredConstantPoolEntry {
    MCSymbol *Sym;
    const Constant *Val;
  };
  SmallVector<DeferredConstantPoolEntry, 8> DeferredConstantPool;
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_LC2K_LC2KASMPRINTER_H
