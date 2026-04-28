//===-- LC2KMCAsmInfo.cpp - LC2K Asm Properties -----------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file contains the definitions of the LC2K MCAsmInfo properties.
///
//===----------------------------------------------------------------------===//

#include "LC2KMCAsmInfo.h"

#include "llvm/TargetParser/Triple.h"

using namespace llvm;

void LC2KELFMCAsmInfo::anchor() {}

LC2KELFMCAsmInfo::LC2KELFMCAsmInfo(const Triple &T) {
  CodePointerSize = 4;
  IsLittleEndian = true;

  CommentString = "#";

  // All instructions are 4 bytes.
  MaxInstLength = 4;
  MinInstAlignment = 4;

  SupportsDebugInformation = false;
  AlignmentIsInBytes = false;

  Data8bitsDirective = nullptr;
  Data16bitsDirective = nullptr;
  Data32bitsDirective = "\t.fill\t";
  Data64bitsDirective = nullptr;

  HasFunctionAlignment = false;
  HasPreferredAlignment = false;
  HasDotTypeDotSizeDirective = false;
  HasSingleParameterDotFile = false;

  LabelSuffix = "\t";
}
