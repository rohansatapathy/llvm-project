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
#include "LC2K.h"
#include "LC2KMachineFunctionInfo.h"
#include "MCTargetDesc/LC2KMCTargetDesc.h"
#include "TargetInfo/LC2KTargetInfo.h"
#include "llvm/CodeGen/GlobalISel/IRTranslator.h"
#include "llvm/CodeGen/GlobalISel/InstructionSelect.h"
#include "llvm/CodeGen/GlobalISel/Legalizer.h"
#include "llvm/CodeGen/GlobalISel/RegBankSelect.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/IR/Function.h"
#include "llvm/InitializePasses.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/PassRegistry.h"
#include "llvm/Support/CodeGen.h"
#include "llvm/Support/Compiler.h"

using namespace llvm;

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeLC2KTarget() {
  RegisterTargetMachine<LC2KTargetMachine> X(getTheLC2KTarget());
  auto *PR = PassRegistry::getPassRegistry();

  initializeGlobalISel(*PR);
  initializeLC2KAsmPrinterPass(*PR);
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
    : CodeGenTargetMachineImpl(T, TT, CPU, FS, Options,
                               getEffectiveRelocModel(RM),
                               getLC2KEffectiveCodeModel(CM), OL),
      TLOF(std::make_unique<TargetLoweringObjectFileELF>()),
      Subtarget(TT, CPU.str(), FS.str(), *this) {
  // LC2K only implements the GlobalISel pipeline; there is no
  // SelectionDAGISel, so GlobalISel must be selected unconditionally rather
  // than relying on the -global-isel command-line flag.
  this->Options.EnableGlobalISel = true;
  initAsmInfo();
}

const LC2KSubtarget *
LC2KTargetMachine::getSubtargetImpl(const Function &F) const {
  Attribute CPUAttr = F.getFnAttribute("target-cpu");
  if (CPUAttr.isValid()) {
    StringRef FnCPU = LC2K::normalizeCPU(CPUAttr.getValueAsString());
    if (FnCPU != Subtarget.getCPU())
      reportFatalUsageError("LC2K: function '" + F.getName() +
                            "' has target-cpu '" + FnCPU +
                            "', but the module is being compiled for '" +
                            Subtarget.getCPU() +
                            "'; mixing CPUs in one module is not supported");
  }

  Attribute FSAttr = F.getFnAttribute("target-features");
  if (!FSAttr.isValid())
    return &Subtarget;
  StringRef FnFS = FSAttr.getValueAsString();
  if (FnFS == Subtarget.getFeatureString() ||
      CheckedFeatureStrings.contains(FnFS))
    return &Subtarget;

  MCSubtargetInfo FnSTI(Subtarget);
  FnSTI.setDefaultFeatures(Subtarget.getCPU(), Subtarget.getCPU(), FnFS);
  LC2K::validateFeatures(FnSTI, F.getName());
  CheckedFeatureStrings.insert(FnFS);
  return &Subtarget;
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

  bool addIRTranslator() override;
  bool addLegalizeMachineIR() override;
  bool addRegBankSelect() override;
  bool addGlobalInstructionSelect() override;
  void addPreRegAlloc() override;
};
} // namespace

TargetPassConfig *LC2KTargetMachine::createPassConfig(PassManagerBase &PM) {
  return new LC2KPassConfig(*this, PM);
}

MachineFunctionInfo *LC2KTargetMachine::createMachineFunctionInfo(
    BumpPtrAllocator &Allocator, const Function &F,
    const TargetSubtargetInfo *STI) const {
  return LC2KMachineFunctionInfo::create<LC2KMachineFunctionInfo>(Allocator, F,
                                                                  STI);
}

bool LC2KPassConfig::addIRTranslator() {
  addPass(new IRTranslatorLegacy());
  return false;
}

bool LC2KPassConfig::addLegalizeMachineIR() {
  addPass(new LegalizerLegacy());
  return false;
}

bool LC2KPassConfig::addRegBankSelect() {
  addPass(new RegBankSelectLegacy());
  return false;
}

bool LC2KPassConfig::addGlobalInstructionSelect() {
  addPass(new InstructionSelectLegacy(getOptLevel()));
  return false;
}

void LC2KPassConfig::addPreRegAlloc() {
  // Expands the PSEUDO_SELECT/PSEUDO_CMP01 placeholders InstructionSelect
  // leaves behind for G_SELECT/G_ICMP into real branch/PHI sequences; see
  // GISel/LC2KExpandPseudos.cpp for why this can't happen during selection
  // itself.
  addPass(createLC2KExpandPseudosPass());
}
