//===-- LC2KTargetInfo.h - LC2K Target Implementation -----------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LC2K_TARGETINFO_LC2KTARGETINFO_H
#define LLVM_LIB_TARGET_LC2K_TARGETINFO_LC2KTARGETINFO_H

namespace llvm {

class Target;

Target &getTheLC2KTarget();

} // namespace llvm

#endif // LLVM_LIB_TARGET_LC2K_TARGETINFO_LC2KTARGETINFO_H
