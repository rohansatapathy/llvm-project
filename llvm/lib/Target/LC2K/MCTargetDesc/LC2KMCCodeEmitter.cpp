//===-- LC2KMCCodeEmitter.cpp - Convert LC2K code emitter -------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file contains definitions for LC2K code emitter.
///
//===----------------------------------------------------------------------===//

#include "LC2KFixupKinds.h"
#include "LC2KInstrInfo.h"
#include "LC2KMCTargetDesc.h"
#include "llvm/MC/MCCodeEmitter.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCFixup.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/EndianStream.h"
#include "llvm/Support/ErrorHandling.h"

#define DEBUG_TYPE "mccodeemitter"

using namespace llvm;

namespace {

class LC2KMCCodeEmitter : public MCCodeEmitter {

public:
  LC2KMCCodeEmitter(const MCInstrInfo &MCII, MCContext &C) {}
  LC2KMCCodeEmitter(const LC2KMCCodeEmitter &) = delete;
  void operator=(const LC2KMCCodeEmitter &) = delete;
  ~LC2KMCCodeEmitter() override = default;

  // The functions below are called by TableGen generated functions for getting
  // the binary encoding of instructions/opereands.

  // getBinaryCodeForInstr - TableGen'erated function for getting the
  // binary encoding for an instruction.
  uint64_t getBinaryCodeForInstr(const MCInst &Inst,
                                 SmallVectorImpl<MCFixup> &Fixups,
                                 const MCSubtargetInfo &SubtargetInfo) const;

  // getMachineOpValue - Return binary encoding of operand. If the machine
  // operand requires relocation, record the relocation and return zero.
  unsigned getMachineOpValue(const MCInst &Inst, const MCOperand &MCOp,
                             SmallVectorImpl<MCFixup> &Fixups,
                             const MCSubtargetInfo &SubtargetInfo) const;

  /// getOffsetValue - Return offset value from I-type instruction.
  unsigned getOffsetValue(const MCInst &Inst, unsigned OpNo,
                          SmallVectorImpl<MCFixup> &Fixups,
                          const MCSubtargetInfo &SubtargetInfo) const;

  void encodeInstruction(const MCInst &Inst, SmallVectorImpl<char> &CB,
                         SmallVectorImpl<MCFixup> &Fixups,
                         const MCSubtargetInfo &SubtargetInfo) const override;
};

} // end anonymous namespace

#include "LC2KGenMCCodeEmitter.inc"

static void addFixup(SmallVectorImpl<MCFixup> &Fixups, const MCExpr *Expr,
                     const MCInst &Inst) {
  bool PCRel = false;
  uint16_t FixupKind = LC2K::fixup_lc2k_none;

  switch (Inst.getOpcode()) {
  case LC2K::LW:
  case LC2K::SW:
  case LC2K::ADDI:
    FixupKind = LC2K::fixup_lc2k_20;
    break;
  case LC2K::BEQ:
  case LC2K::BLT:
  case LC2K::BLTU:
    FixupKind = LC2K::fixup_lc2k_pcplus1rel;
    PCRel = true;
    break;
  }

  Fixups.push_back(MCFixup::create(0, Expr, FixupKind, PCRel));
}

unsigned LC2KMCCodeEmitter::getMachineOpValue(
    const MCInst &Inst, const MCOperand &Op, SmallVectorImpl<MCFixup> &Fixups,
    const MCSubtargetInfo &SubtargetInfo) const {
  if (Op.isReg()) {
    return Op.getReg().id() - LC2K::R0;
  }

  llvm_unreachable("Unsupported operand type");
}

unsigned
LC2KMCCodeEmitter::getOffsetValue(const MCInst &Inst, unsigned OpNo,
                                  SmallVectorImpl<MCFixup> &Fixups,
                                  const MCSubtargetInfo &SubtargetInfo) const {
  const MCOperand Op = Inst.getOperand(OpNo);

  if (Op.isImm()) {
    return static_cast<unsigned>(Op.getImm());
  }

  if (Op.isExpr()) {
    const MCExpr *Expr = Op.getExpr();

    if (Expr->getKind() == MCExpr::Constant) {
      int64_t Val;

      assert(Expr->evaluateAsAbsolute(Val) && "Expr should be constant");

      return static_cast<unsigned>(Val);
    }

    if (Expr->getKind() == MCExpr::SymbolRef) {
      addFixup(Fixups, Expr, Inst);
      return 0;
    }

    llvm_unreachable("Unsupported MCExpr kind");
  }

  llvm_unreachable("Unsupported offset operand type");
}

void LC2KMCCodeEmitter::encodeInstruction(
    const MCInst &Inst, SmallVectorImpl<char> &CB,
    SmallVectorImpl<MCFixup> &Fixups,
    const MCSubtargetInfo &SubtargetInfo) const {

  unsigned Value = getBinaryCodeForInstr(Inst, Fixups, SubtargetInfo);
  support::endian::write<uint32_t>(CB, Value, llvm::endianness::little);
}

MCCodeEmitter *llvm::createLC2KMCCodeEmitter(const MCInstrInfo &InstrInfo,
                                             MCContext &Context) {
  return new LC2KMCCodeEmitter(InstrInfo, Context);
}
