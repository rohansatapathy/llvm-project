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

  // Put arguments in registers. f16/i64/f64 don't need entries of their own
  // here: TargetLowering::getNumRegistersForCallingConv (see
  // LC2KISelLowering's computeRegisterProperties, which only registers i32
  // as a legal type) already reports each of those as 1-or-2 32-bit
  // "registers" of LocVT i32 before CCState ever sees the original type, so
  // by the time these rules run, an i64/f64 arg already looks like two
  // plain i32 pieces (unmerged via G_UNMERGE_VALUES) and an f16 arg already
  // looks like one i32 piece (its bit pattern extended/truncated via
  // G_ANYEXT/G_TRUNC). This CCIfType<[i32, f32], ...> rule is what actually
  // places every one of those pieces.
  CCIfNotVarArg<CCIfType<[i32, f32], CCAssignToReg<[ R1, R2, R3, R4 ]>>>,

  // Otherwise they are assigned to the stack in 4-byte aligned units.
  // NOTE: LC2K is word-addressable, so the FrameLowering and RegisterInfo
  // classes will need to convert bytes to words before emitting frame info.
  CCAssignToStack<4, 4>
]>;

// NOTE: RA (R15) is technically caller-saved according to the ABI, but we
// include it here so that functions that make calls automatically save RA
// during the prologue/epilogue.
def CSR : CalleeSavedRegs<(add R15, (sequence "R%i", 8, 14))>;

def RetCC_LC2K : CallingConv<[
  // Promote i8/i16 args to i32 (this is from Lanai, idk if it's needed)
  CCIfType<[ i8, i16 ], CCPromoteToType<i32>>,

  // Put return value in register(s). See the comment on CC_LC2K above for
  // why i64/f64/f16 don't need their own rules: they already look like one
  // or two i32 pieces by the time this runs. Unlike argument passing,
  // returns need *two* registers available -- an i64/f64 return value's two
  // 32-bit pieces both have to land in real registers, since there's no
  // return-value stack convention to fall back on.
  // NOTE: Unlike argument passing (CC_LC2K), return value location doesn't
  // depend on whether values are varargs because variadic return values aren't
  // a thing.
  CCIfType<[i32, f32], CCAssignToReg<[ R1, R2 ]>>,
]>;
