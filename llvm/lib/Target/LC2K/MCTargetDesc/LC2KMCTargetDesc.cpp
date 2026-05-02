//===-- LC2KMCTargetDesc.cpp - LC2K Target Descriptions ---------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file provides LC2K target specific descriptions.
///
//===----------------------------------------------------------------------===//

#include "LC2KMCTargetDesc.h"
#include "LC2KInstPrinter.h"
#include "LC2KMCAsmInfo.h"
#include "LC2KTargetStreamer.h"
#include "TargetInfo/LC2KTargetInfo.h"
#include "llvm/MC/LaneBitmask.h"
#include "llvm/MC/MCAsmBackend.h"
#include "llvm/MC/MCInstPrinter.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/TargetRegistry.h"

#define GET_INSTRINFO_MC_DESC
#define ENABLE_INSTR_PREDICATE_VERIFIER
#include "LC2KGenInstrInfo.inc"

#define GET_REGINFO_MC_DESC
#include "LC2KGenRegisterInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "LC2KGenSubtargetInfo.inc"

using namespace llvm;

static MCInstrInfo *createLC2KMCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitLC2KMCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createLC2KMCRegisterInfo(const Triple &TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  // TODO: Set return address once ABI is stabilized
  InitLC2KMCRegisterInfo(X, LC2K::R15);
  return X;
}

static MCInstPrinter *createLC2KMCInstPrinter(const Triple &T,
                                              unsigned SyntaxVariant,
                                              const MCAsmInfo &MAI,
                                              const MCInstrInfo &MII,
                                              const MCRegisterInfo &MRI) {
  assert(SyntaxVariant == 0);
  return new LC2KInstPrinter(MAI, MII, MRI);
}

static MCAsmInfo *createLC2KMCAsmInfo(const MCRegisterInfo &MRI,
                                      const Triple &TT,
                                      const MCTargetOptions &Options) {
  return new LC2KELFMCAsmInfo(TT);
}

static MCSubtargetInfo *createLC2KMCSubtargetInfo(const Triple &TT,
                                                  StringRef CPU, StringRef FS) {
  MCSubtargetInfo *X = createLC2KMCSubtargetInfoImpl(TT, CPU, CPU, FS);
  return X;
}

static MCStreamer *
createLC2KAsmStreamer(MCContext &Ctx, std::unique_ptr<formatted_raw_ostream> OS,
                      std::unique_ptr<MCInstPrinter> IP,
                      std::unique_ptr<MCCodeEmitter> CE,
                      std::unique_ptr<MCAsmBackend> TAB) {

  return new LC2KAsmStreamer(Ctx, std::move(OS), std::move(IP), std::move(CE),
                             std::move(TAB));
}

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void LLVMInitializeLC2KTargetMC() {
  TargetRegistry::RegisterMCInstrInfo(getTheLC2KTarget(),
                                      createLC2KMCInstrInfo);

  TargetRegistry::RegisterMCRegInfo(getTheLC2KTarget(),
                                    createLC2KMCRegisterInfo);

  TargetRegistry::RegisterMCInstPrinter(getTheLC2KTarget(),
                                        createLC2KMCInstPrinter);

  TargetRegistry::RegisterMCAsmInfo(getTheLC2KTarget(), createLC2KMCAsmInfo);

  TargetRegistry::RegisterMCSubtargetInfo(getTheLC2KTarget(),
                                          createLC2KMCSubtargetInfo);

  TargetRegistry::RegisterAsmStreamer(getTheLC2KTarget(),
                                      createLC2KAsmStreamer);
}
