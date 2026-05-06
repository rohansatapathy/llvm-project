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

#ifndef LLVM_LIB_TARGET_LC2K_DISASSEMBLER_LC2KDISASSEMBLER_H
#define LLVM_LIB_TARGET_LC2K_DISASSEMBLER_LC2KDISASSEMBLER_H

#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCDisassembler/MCDisassembler.h"
#include "llvm/MC/MCSubtargetInfo.h"

namespace llvm {

class LC2KDisassembler : public MCDisassembler {
public:
  LC2KDisassembler(const MCSubtargetInfo &STI, MCContext &Ctx);

  ~LC2KDisassembler() override = default;

  DecodeStatus getInstruction(MCInst &Instr, uint64_t &Size,
                              ArrayRef<uint8_t> Bytes, uint64_t Address,
                              raw_ostream &CStream) const override;
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_LC2K_DISASSEMBLER_LC2KDISASSEMBLER_H
