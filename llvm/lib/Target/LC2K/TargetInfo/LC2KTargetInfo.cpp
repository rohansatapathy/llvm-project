//===-- LC2KTargetInfo.cpp - LC2K Target Implementation -------*- C++ -*---===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "TargetInfo/LC2KTargetInfo.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Compiler.h"

using namespace llvm;

Target &llvm::getTheLC2KTarget() {
  static Target TheLC2KTarget;
  return TheLC2KTarget;
}

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void
LLVMInitializeLC2KTargetInfo() {
  RegisterTarget<Triple::lc2k> X(getTheLC2KTarget(), "lc2k", "LC2K", "LC2K");
}
