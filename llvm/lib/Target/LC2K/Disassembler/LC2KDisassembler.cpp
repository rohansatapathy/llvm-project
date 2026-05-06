//===- LC2KDisassembler.cpp - Disassembler for LC2K -------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is part of the LC2K Disassembler.
//
//===----------------------------------------------------------------------===//

#include "LC2KDisassembler.h"

#include "MCTargetDesc/LC2KMCTargetDesc.h"
#include "TargetInfo/LC2KTargetInfo.h"
#include "llvm/MC/MCDecoder.h"
#include "llvm/MC/MCDecoderOps.h"
#include "llvm/MC/MCDisassembler/MCDisassembler.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Endian.h"
#include "llvm/Support/MathExtras.h"

#define DEBUG_TYPE "lc2k-disassembler"

using namespace llvm;
using namespace llvm::MCD;

typedef MCDisassembler::DecodeStatus DecodeStatus;

static MCDisassembler *createLC2KDisassembler(const Target & /*T*/,
                                              const MCSubtargetInfo &STI,
                                              MCContext &Ctx) {
  return new LC2KDisassembler(STI, Ctx);
}

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void
LLVMInitializeLC2KDisassembler() { // NOLINT
  // Register the disassembler
  TargetRegistry::RegisterMCDisassembler(getTheLC2KTarget(),
                                         createLC2KDisassembler);
}

LC2KDisassembler::LC2KDisassembler(const MCSubtargetInfo &STI, MCContext &Ctx)
    : MCDisassembler(STI, Ctx) {}

static const unsigned GPRDecoderTable[] = {
    LC2K::R0,  LC2K::R1,  LC2K::R2,  LC2K::R3,  LC2K::R4,  LC2K::R5,
    LC2K::R6,  LC2K::R7,  LC2K::R8,  LC2K::R9,  LC2K::R10, LC2K::R11,
    LC2K::R12, LC2K::R13, LC2K::R14, LC2K::R15,
};

static DecodeStatus DecodeGPRRegisterClass(MCInst &Inst, // NOLINT
                                           uint32_t RegNo, uint64_t Address,
                                           const MCDisassembler *Decoder) {
  if (RegNo >= std::size(GPRDecoderTable))
    return MCDisassembler::Fail;
  Inst.addOperand(MCOperand::createReg(GPRDecoderTable[RegNo]));
  return MCDisassembler::Success;
}

static DecodeStatus decodeOffset(MCInst &Inst, uint32_t Imm, uint64_t Address,
                                 const MCDisassembler *Decoder) {
  Inst.addOperand(MCOperand::createImm(SignExtend64<20>(Imm)));
  return MCDisassembler::Success;
}

#include "LC2KGenDisassemblerTables.inc"

DecodeStatus LC2KDisassembler::getInstruction(MCInst &Instr, uint64_t &Size,
                                              ArrayRef<uint8_t> Bytes,
                                              uint64_t Address,
                                              raw_ostream &CStream) const {
  if (Bytes.size() < 4) {
    Size = 0;
    return MCDisassembler::Fail;
  }
  Size = 4;

  uint32_t Insn = support::endian::read32le(Bytes.data());
  return decodeInstruction(DecoderTableLC2K32, Instr, Insn, Address, this, STI);
}
