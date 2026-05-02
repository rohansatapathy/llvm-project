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

#include "llvm/Support/DataTypes.h"

namespace llvm {

class MCAsmBackend;
class MCCodeEmitter;
class MCContext;
class MCInstrInfo;
class Target;
class MCSubtargetInfo;
class MCRegisterInfo;
class MCTargetOptions;

MCCodeEmitter *createLC2KMCCodeEmitter(const MCInstrInfo &MCII, MCContext &Ctx);

MCAsmBackend *createLC2KAsmBackend(const Target &T, const MCSubtargetInfo &STI,
                                   const MCRegisterInfo &MRI,
                                   const MCTargetOptions &Options);

} // namespace llvm

// Defines symbolic names for LC2K registers. This defines a mapping from
// register name to register number.
#define GET_REGINFO_ENUM
#include "LC2KGenRegisterInfo.inc"

// Defines symbolic names for the LC2K instructions.
#define GET_INSTRINFO_ENUM
#define GET_INSTRINFO_MC_HELPER_DECLS
#include "LC2KGenInstrInfo.inc"

// NOTE: LC2K has no subtargets, so not including the enum here.

#endif // LLVM_LIB_TARGET_LC2K_MCTARGETDESC_LC2KMCTARGETDESC_H
