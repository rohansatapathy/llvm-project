//===-- LC2KISelLowering.h - LC2K DAG Lowering Interface --------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file defines the interfaces that LC2K uses to lower LLVM code into a
/// selection DAG.
///
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LC2K_LC2KISELLOWERING_H
#define LLVM_LIB_TARGET_LC2K_LC2KISELLOWERING_H

#include "LC2K.h"

#include "llvm/CodeGen/TargetLowering.h"

namespace llvm {

class LC2KSubtarget;

class LC2KTargetLowering : public TargetLowering {
public:
  explicit LC2KTargetLowering(const LC2KTargetMachine &TM,
                              const LC2KSubtarget &STI);
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_LC2K_LC2KISELLOWERING_H
