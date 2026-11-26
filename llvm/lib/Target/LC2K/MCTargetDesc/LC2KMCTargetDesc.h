//===-- LC2KMCTargetDesc.h - LC2K Target Descriptions -----------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file provides LC2K specific target descriptions.
///
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LC2K_MCTARGETDESC_LC2KMCTARGETDESC_H
#define LLVM_LIB_TARGET_LC2K_MCTARGETDESC_LC2KMCTARGETDESC_H

#include "llvm/ADT/StringRef.h"
#include "llvm/Support/DataTypes.h"

#include <memory>

namespace llvm {

class MCAsmBackend;
class MCCodeEmitter;
class MCContext;
class MCInstrInfo;
class Target;
class MCObjectTargetWriter;
class MCStreamer;
class MCSubtargetInfo;
class MCRegisterInfo;
class MCTargetOptions;
class MCTargetStreamer;

MCCodeEmitter *createLC2KMCCodeEmitter(const MCInstrInfo &MCII, MCContext &Ctx);

MCAsmBackend *createLC2KAsmBackend(const Target &T, const MCSubtargetInfo &STI,
                                   const MCRegisterInfo &MRI,
                                   const MCTargetOptions &Options);

std::unique_ptr<MCObjectTargetWriter> createLC2KELFObjectWriter(uint8_t OSABI);

/// Create the target streamer for object files, which records the CPU in the
/// ELF header flags.
MCTargetStreamer *createLC2KObjectTargetStreamer(MCStreamer &S,
                                                 const MCSubtargetInfo &STI);

namespace LC2K {

/// Map an empty or "generic" CPU name to the default CPU ("eecs470").
///
/// LLVM gives an empty or unrecognized CPU no features at all, so every place
/// that builds an LC2K subtarget must normalize the CPU first.
StringRef normalizeCPU(StringRef CPU);

/// Report a fatal error unless STI's CPU is a known LC2K CPU and its feature
/// set is exactly that CPU's preset.
///
/// LC2K features describe fixed hardware variants and are not independent,
/// so the only supported configurations are the ones selected by -mcpu.
/// Feature strings that restate preset features are accepted; ones that
/// change the preset are rejected. FnName names the function whose
/// "target-features" are being checked, if any, for the error message.
void validateFeatures(const MCSubtargetInfo &STI, StringRef FnName = "");

/// Width in bits of the signed immediate field of I-type instructions under
/// STI's instruction encoding.
unsigned getImmBits(const MCSubtargetInfo &STI);

} // namespace LC2K

} // namespace llvm

// Defines symbolic names for LC2K registers. This defines a mapping from
// register name to register number.
#define GET_REGINFO_ENUM
#include "LC2KGenRegisterInfo.inc"

// Defines symbolic names for the LC2K subtarget features (LC2K::FeatureNOR,
// ...). Must precede the instruction info, whose predicate checks use them.
#define GET_SUBTARGETINFO_ENUM
#include "LC2KGenSubtargetInfo.inc"

// Defines symbolic names for the LC2K instructions.
#define GET_INSTRINFO_ENUM
#define GET_INSTRINFO_MC_HELPER_DECLS
#include "LC2KGenInstrInfo.inc"

#endif // LLVM_LIB_TARGET_LC2K_MCTARGETDESC_LC2KMCTARGETDESC_H
