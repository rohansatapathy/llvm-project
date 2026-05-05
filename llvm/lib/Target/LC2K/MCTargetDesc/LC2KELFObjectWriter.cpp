//===-- LC2KELFObjectWriter.cpp - LC2K ELF Writer -------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "LC2KFixupKinds.h"
#include "LC2KMCTargetDesc.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/MC/MCFixup.h"
#include "llvm/MC/MCObjectWriter.h"
#include "llvm/Support/ErrorHandling.h"

using namespace llvm;

namespace {

class LC2KELFObjectWriter : public MCELFObjectTargetWriter {
public:
  explicit LC2KELFObjectWriter(uint8_t OSABI);

  ~LC2KELFObjectWriter() override = default;

protected:
  unsigned getRelocType(const MCFixup &Fixup, const MCValue &Target,
                        bool IsPCRel) const override;
};

} // namespace

LC2KELFObjectWriter::LC2KELFObjectWriter(uint8_t OSABI)
    : MCELFObjectTargetWriter(/*Is64Bit_=*/false, OSABI, ELF::EM_LC2K,
                              /*HasRelocationAddend_=*/true) {}

unsigned LC2KELFObjectWriter::getRelocType(const MCFixup &Fixup,
                                           const MCValue &Target,
                                           bool IsPCRel) const {
  unsigned Type;
  unsigned Kind = static_cast<unsigned>(Fixup.getKind());
  switch (Kind) {
  case LC2K::fixup_lc2k_none:
    Type = ELF::R_LC2K_NONE;
    break;
  case LC2K::fixup_lc2k_20:
    Type = ELF::R_LC2K_20;
    break;
  case LC2K::fixup_lc2k_pcplus1rel:
    Type = ELF::R_LC2K_20_PCPLUS1REL;
    break;
  case LC2K::fixup_lc2k_32:
  case FK_Data_4:
    Type = ELF::R_LC2K_32;
    break;
  default:
    llvm_unreachable("Invalid fixup kind!");
  }
  return Type;
}

std::unique_ptr<MCObjectTargetWriter>
llvm::createLC2KELFObjectWriter(uint8_t OSABI) {
  return std::make_unique<LC2KELFObjectWriter>(OSABI);
}
