//===- LC2KMachineFunctionInfo.h - LC2K machine func info -------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file declares LC2K-specific per-machine-function information.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LC2K_LC2KMACHINEFUNCTIONINFO_H
#define LLVM_LIB_TARGET_LC2K_LC2KMACHINEFUNCTIONINFO_H

#include "llvm/CodeGen/MachineFunction.h"

namespace llvm {

class LC2KMachineFunctionInfo : public MachineFunctionInfo {
  virtual void anchor();

  // Frame index of the stack slot where the first vararg would be, for
  // variadic functions. Every argument of a variadic function -- named or
  // not -- is passed on the stack (see CC_LC2K's CCIfNotVarArg guard), so
  // this is simply the stack offset immediately after the last named
  // argument. Set by LC2KCallLowering::lowerFormalArguments, consumed by
  // LC2KLegalizerInfo's G_VASTART custom lowering.
  int VarArgsFrameIndex = 0;

public:
  LC2KMachineFunctionInfo(const Function &F, const TargetSubtargetInfo *STI) {}

  MachineFunctionInfo *
  clone(BumpPtrAllocator &Allocator, MachineFunction &DestMF,
        const DenseMap<MachineBasicBlock *, MachineBasicBlock *> &Src2DstMBB)
      const override;

  int getVarArgsFrameIndex() const { return VarArgsFrameIndex; }
  void setVarArgsFrameIndex(int Index) { VarArgsFrameIndex = Index; }
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_LC2K_LC2KMACHINEFUNCTIONINFO_H
