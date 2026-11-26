//===-- LC2KELFStreamer.cpp - LC2K ELF Target Streamer --------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file records the LC2K CPU in the ELF header of object files.
//
//===----------------------------------------------------------------------===//

#include "LC2KMCTargetDesc.h"

#include "llvm/BinaryFormat/ELF.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/MC/MCELFStreamer.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSubtargetInfo.h"

using namespace llvm;

namespace {

class LC2KTargetELFStreamer : public MCTargetStreamer {
public:
  LC2KTargetELFStreamer(MCStreamer &S, const MCSubtargetInfo &STI)
      : MCTargetStreamer(S) {
    ELFObjectWriter &W = static_cast<MCELFStreamer &>(S).getWriter();
    W.setELFHeaderEFlags(getMachFlag(STI));
  }

private:
  // Each CPU has its own encoding family, so the encoding feature identifies
  // the machine.
  static unsigned getMachFlag(const MCSubtargetInfo &STI) {
    if (STI.hasFeature(LC2K::FeatureEncPhobos))
      return ELF::EF_LC2K_MACH_PHOBOS;
    assert(STI.hasFeature(LC2K::FeatureEncEECS470) &&
           "Unknown LC2K encoding family");
    return ELF::EF_LC2K_MACH_EECS470;
  }
};

} // namespace

MCTargetStreamer *llvm::createLC2KObjectTargetStreamer(
    MCStreamer &S, const MCSubtargetInfo &STI) {
  return new LC2KTargetELFStreamer(S, STI);
}
