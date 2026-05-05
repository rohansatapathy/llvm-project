//===-- LC2KAsmBackend.cpp - LC2K Assembler Backend -----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "LC2KFixupKinds.h"
#include "LC2KMCTargetDesc.h"
#include "llvm/MC/MCAsmBackend.h"
#include "llvm/MC/MCAssembler.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/MCValue.h"
#include "llvm/MC/TargetRegistry.h"

using namespace llvm;

namespace {

class LC2KAsmBackend : public MCAsmBackend {
  Triple::OSType OSType;

public:
  LC2KAsmBackend(const Target &T, Triple::OSType OST)
      : MCAsmBackend(llvm::endianness::little), OSType(OST) {}

  virtual std::unique_ptr<MCObjectTargetWriter>
  createObjectTargetWriter() const override;

  virtual void applyFixup(const MCFragment &F, const MCFixup &Fixup,
                          const MCValue &Target, uint8_t *Data, uint64_t Value,
                          bool IsResolved) override;

  virtual bool writeNopData(raw_ostream &OS, uint64_t Count,
                            const MCSubtargetInfo *STI) const override;
};

} // namespace

std::unique_ptr<MCObjectTargetWriter>
LC2KAsmBackend::createObjectTargetWriter() const {
  return createLC2KELFObjectWriter(MCELFObjectTargetWriter::getOSABI(OSType));
}

static uint32_t adjustFixupValue(unsigned Kind, uint64_t Value) {
  int64_t SValue = static_cast<int64_t>(Value);
  switch (Kind) {
  case FK_Data_4:
    return static_cast<uint32_t>(SValue);
  case LC2K::fixup_lc2k_none:
  case LC2K::fixup_lc2k_20:
  case LC2K::fixup_lc2k_32:
    // LC2K is word-addressed, so need to convert given byte address -> word
    // address
    return static_cast<uint32_t>(SValue / 4);
  case LC2K::fixup_lc2k_pcplus1rel:
    // LC2K branches are relative to PC+1, and LLVM gives branch offset
    // relative to just PC, so subtract 1 to compensate.
    return static_cast<uint32_t>(SValue / 4 - 1);
  default:
    llvm_unreachable("Invalid fixup kind!");
  }
}

void LC2KAsmBackend::applyFixup(const MCFragment &F, const MCFixup &Fixup,
                                const MCValue &Target, uint8_t *Data,
                                uint64_t Value, bool IsResolved) {
  if (!IsResolved)
    Asm->getWriter().recordRelocation(F, Fixup, Target, Value);

  MCFixupKind Kind = Fixup.getKind();
  Value = adjustFixupValue(static_cast<unsigned>(Kind), Value);
  if (!Value)
    return; // This value doesn't change the encoding

  uint32_t Inst = 0;
  for (size_t i = 0; i < sizeof(uint32_t); i++) { // NOLINT
    Inst |= static_cast<uint32_t>(Data[i]) << (i * 8);
  }

  uint32_t Mask =
      static_cast<uint32_t>(-1) >> (32 - getFixupKindInfo(Kind).TargetSize);

  // TargetOffset should always be 0, but its here just in case.
  Inst |= (Value & Mask) << getFixupKindInfo(Kind).TargetOffset;

  for (size_t i = 0; i < sizeof(uint32_t); i++) { // NOLINT
    Data[i] = static_cast<uint8_t>((Inst >> (i * 8)) & 0xFF);
  }
}

bool LC2KAsmBackend::writeNopData(raw_ostream &OS, uint64_t Count,
                                  const MCSubtargetInfo *STI) const {
  if ((Count % 4) != 0) {
    return false;
  }

  for (uint64_t i = 0; i < Count; i += 4) { // NOLINT
    OS.write("\x00\x00\x00\x07", 4);
  }

  return true;
}

MCAsmBackend *llvm::createLC2KAsmBackend(const Target &T,
                                         const MCSubtargetInfo &STI,
                                         const MCRegisterInfo & /*MRI*/,
                                         const MCTargetOptions & /*Options*/) {
  const Triple &TT = STI.getTargetTriple();
  if (!TT.isOSBinFormatELF())
    llvm_unreachable("OS not supported");

  return new LC2KAsmBackend(T, TT.getOS());
}
