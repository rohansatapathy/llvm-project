//===-- LC2KFeatures.td - LC2K Features and Extensions -----*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Subtarget features
//===----------------------------------------------------------------------===//

def FeatureNOR : SubtargetFeature<"nor", "HasNOR", "true",
                                  "Has the NOR instruction">;

def FeatureNAND : SubtargetFeature<"nand", "HasNAND", "true",
                                   "Has the NAND instruction">;

def FeatureADDI : SubtargetFeature<"addi", "HasADDI", "true",
                                   "Has the ADDI instruction">;

def FeatureNOOPInstr : SubtargetFeature<"noop-instr", "HasNOOPInstr", "true",
                                        "Has a dedicated NOOP opcode (rather "
                                        "than an assembler pseudo)">;

def FeatureHardwiredR0 : SubtargetFeature<"hardwired-r0", "HasHardwiredR0",
                                          "true",
                                          "Register 0 always reads 0 and "
                                          "discards writes">;

// NOTE: This is for when EECS 370 LC2K support gets added
def FeatureGPR16 : SubtargetFeature<"gpr16", "HasGPR16", "true",
                                    "Has 16 general-purpose registers "
                                    "instead of 8">;

// EECS 470 and Phobos use different instruction encodings, enable exactly
// one.
def FeatureEncEECS470 : SubtargetFeature<"enc-eecs470", "HasEncEECS470",
                                         "true",
                                         "Use the EECS 470 instruction "
                                         "encoding">;

def FeatureEncPhobos : SubtargetFeature<"enc-phobos", "HasEncPhobos", "true",
                                        "Use the Phobos instruction encoding">;

//===----------------------------------------------------------------------===//
// Predicates
//===----------------------------------------------------------------------===//

def HasNOR : Predicate<"Subtarget->hasNOR()">,
             AssemblerPredicate<(all_of FeatureNOR), "nor">;
def HasNAND : Predicate<"Subtarget->hasNAND()">,
              AssemblerPredicate<(all_of FeatureNAND), "nand">;
def HasADDI : Predicate<"Subtarget->hasADDI()">,
              AssemblerPredicate<(all_of FeatureADDI), "addi">;
def HasNOOPInstr : Predicate<"Subtarget->hasNOOPInstr()">,
                   AssemblerPredicate<(all_of FeatureNOOPInstr), "noop-instr">;

// Encoding predicates double as AssemblerPredicates so MC-layer HwMode
// computation (which only sees feature bits) can use them.
def HasEncEECS470 : Predicate<"Subtarget->hasEncEECS470()">,
                    AssemblerPredicate<(all_of FeatureEncEECS470),
                                       "enc-eecs470">;
def HasEncPhobos : Predicate<"Subtarget->hasEncPhobos()">,
                   AssemblerPredicate<(all_of FeatureEncPhobos), "enc-phobos">;

//===----------------------------------------------------------------------===//
// Hardware modes
//===----------------------------------------------------------------------===//

// HwMode used to select between instruction encodings based on `-mcpu`
// (see LC2KInstrFormats.td).
def ModeEECS470 : HwMode<[HasEncEECS470]>;
def ModePhobos : HwMode<[HasEncPhobos]>;
