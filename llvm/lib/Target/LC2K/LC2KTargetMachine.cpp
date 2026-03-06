//===- LC2KTargetMachine.cpp - Define TargetMachine for LC2K ----*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Implements the info about LC2K target spec.
//
//===----------------------------------------------------------------------===//

#include "LC2KTargetMachine.h"
#include "TargetInfo/LC2KTargetInfo.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/CodeGen.h"
#include "llvm/Support/Compiler.h"

using namespace llvm;

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeLC2KTarget() {
  RegisterTargetMachine<LC2KTargetMachine> X(getTheLC2KTarget());
}

static Reloc::Model getEffectiveRelocModel(std::optional<Reloc::Model> RM) {
  if (RM && *RM != Reloc::Static)
    reportFatalUsageError("LC2K only supports the static relocation model");
  return Reloc::Static;
}

static CodeModel::Model
getLC2KEffectiveCodeModel(std::optional<CodeModel::Model> CM) {
  if (CM && *CM != CodeModel::Small)
    reportFatalUsageError("LC2K only supports the small code model");
  return CodeModel::Small;
}

LC2KTargetMachine::LC2KTargetMachine(const Target &T, const Triple &TT,
                                     StringRef CPU, StringRef FS,
                                     const TargetOptions &Options,
                                     std::optional<Reloc::Model> RM,
                                     std::optional<CodeModel::Model> CM,
                                     CodeGenOptLevel OL, bool JIT)
    : CodeGenTargetMachineImpl(T, TT.computeDataLayout(), TT, CPU, FS, Options,
                               getEffectiveRelocModel(RM),
                               getLC2KEffectiveCodeModel(CM), OL),
      TLOF(std::make_unique<TargetLoweringObjectFileELF>()) {
  initAsmInfo();
}

namespace {
// LC2K Code Generator Pass Configuration Options.
class LC2KPassConfig : public TargetPassConfig {
public:
  LC2KPassConfig(LC2KTargetMachine &TM, PassManagerBase &PM)
      : TargetPassConfig(TM, PM) {}

  LC2KTargetMachine &getLC2KTargetMachine() const {
    return getTM<LC2KTargetMachine>();
  }
};
} // namespace

TargetPassConfig *LC2KTargetMachine::createPassConfig(PassManagerBase &PM) {
  return new LC2KPassConfig(*this, PM);
}
