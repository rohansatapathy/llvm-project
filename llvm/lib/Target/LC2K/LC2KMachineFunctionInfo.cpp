//===- LC2KMachineFunctionInfo.cpp - LC2K machine function info ---------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "LC2KMachineFunctionInfo.h"

using namespace llvm;

void LC2KMachineFunctionInfo::anchor() {}

MachineFunctionInfo *LC2KMachineFunctionInfo::clone(
    BumpPtrAllocator &Allocator, MachineFunction &DestMF,
    const DenseMap<MachineBasicBlock *, MachineBasicBlock *> &Src2DstMBB)
    const {
  return DestMF.cloneInfo<LC2KMachineFunctionInfo>(*this);
}
