//===-- LC2KISelLowering.cpp - LC2K DAG Lowering Impl -----------*- C++ -*-===//
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

#include "LC2KISelLowering.h"
#include "LC2KTargetMachine.h"

using namespace llvm;

LC2KTargetLowering::LC2KTargetLowering(const LC2KTargetMachine &TM,
                                       const LC2KSubtarget &STI)
    : TargetLowering(TM, STI) {
  addRegisterClass(MVT::i32, &LC2K::GPRRegClass);

  // LC2K's stack pointer is always word-aligned, so every stack argument is
  // naturally 1-word aligned (the DataLayout's byte is itself a word, so
  // Align(1) here means word alignment). This also keeps
  // LegalizerHelper::lowerVAArg from emitting a G_PTRMASK for ordinary s32/
  // p0 varargs, which LC2K has no legalizer rule for.
  setMinStackArgumentAlignment(Align(1));

  computeRegisterProperties(STI.getRegisterInfo());
}
