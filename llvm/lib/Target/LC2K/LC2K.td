//===-- LC2K.td - Describe the LC2K Target Machine ---------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

include "llvm/Target/Target.td"

include "LC2KRegisterInfo.td"
include "LC2KCallingConv.td"
include "LC2KInstrFormats.td"
include "LC2KInstrInfo.td"

defm : RemapAllTargetPseudoPointerOperands<GPR>;

def LC2KInstrInfo : InstrInfo {}

def LC2KInstPrinter : AsmWriter {}

def LC2K : Target {
    let InstructionSet = LC2KInstrInfo;
    let AssemblyWriters = [LC2KInstPrinter];
}

def : ProcessorModel<"generic", NoSchedModel, []>;
