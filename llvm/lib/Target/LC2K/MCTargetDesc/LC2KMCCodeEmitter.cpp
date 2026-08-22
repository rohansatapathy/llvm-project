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
#include "llvm/MC/MCRegister.h"
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

  /// Hand-encodes PSEUDO_LA (see the doc comment on its TableGen def) into
  /// a real hi-ADDI + 20 doubling-ADDs + lo-ADDI sequence, bypassing
  /// getBinaryCodeForInstr entirely -- PSEUDO_LA has no single-instruction
  /// encoding of its own to generate.
  void encodePseudoLA(const MCInst &Inst, SmallVectorImpl<char> &CB,
                      SmallVectorImpl<MCFixup> &Fixups) const;
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

  if (Inst.getOpcode() == LC2K::PSEUDO_LA) {
    encodePseudoLA(Inst, CB, Fixups);
    return;
  }

  unsigned Value = getBinaryCodeForInstr(Inst, Fixups, SubtargetInfo);
  support::endian::write<uint32_t>(CB, Value, llvm::endianness::little);
}

void LC2KMCCodeEmitter::encodePseudoLA(const MCInst &Inst,
                                       SmallVectorImpl<char> &CB,
                                       SmallVectorImpl<MCFixup> &Fixups) const {
  MCRegister Dst = Inst.getOperand(0).getReg();
  MCRegister Base = Inst.getOperand(1).getReg();
  const MCExpr *Sym = Inst.getOperand(2).getExpr();

  // Raw 4-bit hardware opcode field values -- mirrors OPC_ADD/OPC_ADDI in
  // LC2KInstrInfo.td, which (being TableGen LC2KOpcode records, not real
  // MC opcodes) aren't otherwise visible as C++ constants.
  constexpr uint32_t OpcAdd = 0b0000;
  constexpr uint32_t OpcAddi = 0b1000;

  auto RegNum = [](MCRegister Reg) { return Reg.id() - LC2K::R0; };
  // ADDI's encoding (LC2KInstITypeWriteReg): Inst{27-24}=regA (base),
  // Inst{23-20}=regB (dest), Inst{19-0}=offset (left as 0 here; the
  // attached fixup patches it in later).
  auto EmitADDI = [&](unsigned RegA, unsigned RegB) {
    uint32_t Word = (OpcAddi << 28) | (RegA << 24) | (RegB << 20);
    support::endian::write<uint32_t>(CB, Word, llvm::endianness::little);
  };
  // ADD's encoding (LC2KInstRType): Inst{27-24}=regA, Inst{23-20}=regB,
  // Inst{3-0}=destReg.
  auto EmitADD = [&](unsigned RegA, unsigned RegB, unsigned Dest) {
    uint32_t Word = (OpcAdd << 28) | (RegA << 24) | (RegB << 20) | Dest;
    support::endian::write<uint32_t>(CB, Word, llvm::endianness::little);
  };

  // ADDI Dst, Base, hi(sym) -- word address's rounding-compensated high 12
  // bits (see LC2KAsmBackend.cpp's splitWideAddress).
  Fixups.push_back(
      MCFixup::create(CB.size(), Sym, LC2K::fixup_lc2k_hi12, /*PCRel=*/false));
  EmitADDI(RegNum(Base), RegNum(Dst));

  // No shift hardware exists, so shift Dst left by the fixed, compile-time-
  // known amount of 20 via 20 doublings -- unlike materializeConstant's
  // bit-serial constant builder, this needs no libcall and no scratch
  // register beyond Dst itself, since a shift by a *known* amount doesn't
  // depend on knowing the (link-time-resolved) value being shifted.
  for (int I = 0; I < 20; ++I)
    EmitADD(RegNum(Dst), RegNum(Dst), RegNum(Dst));

  // ADDI Dst, Dst, lo(sym) -- the low 20 bits, reinterpreted as signed so
  // it always independently fits (see splitWideAddress); this is what
  // combines the shifted high bits with the low bits, since ADDI's base
  // register is now Dst (holding Hi << 20) rather than Base.
  Fixups.push_back(
      MCFixup::create(CB.size(), Sym, LC2K::fixup_lc2k_lo20, /*PCRel=*/false));
  EmitADDI(RegNum(Dst), RegNum(Dst));
}

MCCodeEmitter *llvm::createLC2KMCCodeEmitter(const MCInstrInfo &InstrInfo,
                                             MCContext &Context) {
  return new LC2KMCCodeEmitter(InstrInfo, Context);
}
