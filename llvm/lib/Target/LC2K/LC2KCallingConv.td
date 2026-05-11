//===- LC2KCallingConv.td - Calling Conventions LC2K ---------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This describes the calling conventions for the LC2K architecture.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Return Value Calling Conventions
//===----------------------------------------------------------------------===//

def CC_LC2K : CallingConv<[
  // Promote i8/i16 args to i32 (this is from Lanai, idk if it's needed)
  CCIfType<[ i8, i16 ], CCPromoteToType<i32>>,

  // Put arguments in registers.
  CCIfNotVarArg<CCIfType<[i32], CCAssignToReg<[ R1, R2, R3, R4 ]>>>,

  // Otherwise they are assigned to the stack in 4-byte aligned units.
  // NOTE: LC2K is word-addressable, so the FrameLowering and RegisterInfo
  // classes will need to convert bytes to words before emitting frame info.
  CCAssignToStack<4, 4>
]>;

def CSR : CalleeSavedRegs<(add (sequence "R%i", 8, 14))>;
