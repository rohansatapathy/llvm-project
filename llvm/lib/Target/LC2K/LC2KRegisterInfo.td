//===-- LC2KRegisterInfo.td - LC2K Register defs -----------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
//  Declarations that describe the LC2K register file.
//
//===----------------------------------------------------------------------===//

class LC2KReg<bits<4> num, string n> : Register<n> {
    field bits<4> Num;
    let Num = num;
    let Namespace = "LC2K";
    let HWEncoding{3-0} = num;
}

// R0 always reads as zero. On phobos the hardware guarantees it, so codegen
// also writes R0 to discard values (e.g. JALR's return address). On eecs470
// it is a software convention: R0 is reserved and codegen never writes it.
// Either way it is constant within a function. Without isConstant, the R0
// defs on phobos would make MachineRegisterInfo::isConstantPhysReg(R0) false,
// so passes that rely on it (MachineLICM, MachineCSE, ...) would stop treating
// reads of R0 as constant.
foreach i = 0-15 in {
    let isConstant = !eq(i, 0) in
    def R#i : LC2KReg<i, ""#i>, DwarfRegNum<[i]>;
}

// TODO: Fix register order once ABI is well-defined for better
// register allocation.
def GPR : RegisterClass<"LC2K", [i32], 32, (add (sequence "R%i", 0, 15))>;
