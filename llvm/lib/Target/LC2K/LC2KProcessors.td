//===-- LC2KProcessors.td - LC2K Processors ----------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// LC2K processors supported.
//===----------------------------------------------------------------------===//

// Default ISA variant is EECS 470 LC2K.
defvar EECS470Features = [FeatureNOR, FeatureNAND, FeatureADDI,
                          FeatureNOOPInstr, FeatureGPR16, FeatureEnc470];

def : ProcessorModel<"generic", NoSchedModel, EECS470Features>;
def : ProcessorModel<"eecs470", NoSchedModel, EECS470Features>;

// Phobos variant has eight instructions (replace NOOP w/ ADDI) and hardwired
// R0 register.
def : ProcessorModel<"phobos", NoSchedModel,
                     [FeatureNAND, FeatureADDI, FeatureHardwiredR0,
                      FeatureGPR16, FeatureEncPhobos]>;
