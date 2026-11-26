//===-- LC2K.td - Describe the LC2K Target Machine ---------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

include "llvm/Target/Target.td"

//===----------------------------------------------------------------------===//
// LC2K subtarget features and instruction predicates.
//===----------------------------------------------------------------------===//

include "LC2KFeatures.td"

//===----------------------------------------------------------------------===//
// Registers, calling conventions, instruction descriptions.
//===----------------------------------------------------------------------===//

include "LC2KRegisterInfo.td"
include "LC2KCallingConv.td"
include "LC2KInstrFormats.td"
include "LC2KInstrInfo.td"
include "GISel/LC2KRegisterBanks.td"

defm : RemapAllTargetPseudoPointerOperands<GPR>;

//===----------------------------------------------------------------------===//
// LC2K processors supported.
//===----------------------------------------------------------------------===//

include "LC2KProcessors.td"

//===----------------------------------------------------------------------===//
// Define the LC2K target.
//===----------------------------------------------------------------------===//

def LC2KInstrInfo : InstrInfo {}

def LC2KInstPrinter : AsmWriter {}

def LC2K : Target {
    let InstructionSet = LC2KInstrInfo;
    let AssemblyWriters = [LC2KInstPrinter];
}
