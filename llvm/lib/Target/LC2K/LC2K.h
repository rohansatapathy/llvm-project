//===-- LC2K.h - Top-level interface for LC2K -------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the entry points for global functions defined in the LLVM
// LC2K back-end.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LC2K_LC2K_H
#define LLVM_LIB_TARGET_LC2K_LC2K_H

namespace llvm {

class FunctionPass;
class ModulePass;
class PassRegistry;
class LC2KTargetMachine;

void initializeLC2KAsmPrinterPass(PassRegistry &);

} // namespace llvm

#endif // LLVM_LIB_TARGET_LC2K_LC2K_H
