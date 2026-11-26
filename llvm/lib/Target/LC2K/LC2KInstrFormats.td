//===-- LC2KInstrFormats.td - LC2K Instruction Formats -----*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

def OffsetAsmOperand : AsmOperandClass {
  let Name = "Offset";
  let RenderMethod = "addOffsetOperands";
  let DiagnosticType = "InvalidOffset";
}

// Declared as i32, not a synthetic 20-bit VT: the 20-bit truncation is
// purely an encoding-time concern, handled by EncoderMethod/DecoderMethod
// and the `bits<20> offset` field slicing in the instruction formats below.
// A value type outside the registered MVT set (i1/i8/../i512, see
// llvm/CodeGen/ValueTypes.td) can't be used in patterns -- CodeGenTarget's
// getValueType() looks it up in a fixed StringSwitch over exactly those
// registered names and has no fallback case, so passing it a record with
// any other LLVMName (e.g. a from-scratch `VTInt<20>`) crashes tablegen the
// moment any pattern (see the Pat<>s below) forces type inference over an
// operand declared with it.
def LC2KOffset : Operand<i32> {
  let ParserMatchClass = OffsetAsmOperand;
  let EncoderMethod = "getOffsetValue";
  let DecoderMethod = "decodeOffset";
}

// ValueType for branch target is a basic block name, which pattern matches 
// as OtherVT instead of i32 during instruction selection. Therefore, we need 
// a separate type to represent this argument.
def LC2KBrTarget : Operand<OtherVT> {
  let ParserMatchClass = OffsetAsmOperand;
  let EncoderMethod = "getOffsetValue";
  let DecoderMethod = "decodeOffset";
}

// An LC2K opcode and its value in each encoding family, or -1 if the family
// doesn't have the instruction. Pass the values as named arguments, listing
// only the families that have the opcode:
//
//   def OPC_NOR : LC2KOpcode<"nor", eecs470 = 0b0001>;
//
// To add an encoding family:
// - Add a column here
// - Add a HwMode, subtarget feature, and encoding predicate in 
//   LC2KFeatures.td
// - Add an encoding class per format
// - Add LC2KEncodings<Family> class below
// - List it in LC2KEncodings below
class LC2KOpcode<string name, int eecs470 = -1, int phobos = -1> {
  string Name = name;
  int EECS470Value = eecs470;
  int PhobosValue = phobos;

  assert !lt(eecs470, 0b10000), "EECS 470 opcode of '" # name #
                                 "' must fit in 4 bits";
  assert !lt(phobos, 0b1000), "Phobos opcode of '" # name #
                              "' must fit in 3 bits";
  assert !or(!ge(eecs470, 0), !ge(phobos, 0)),
         "opcode '" # name # "' is not in any encoding family";
}

// Operand layout of an instruction, independent of encoding family.
class LC2KFormat;
def LC2KFormatR : LC2KFormat; // regA, regB, destReg
def LC2KFormatI : LC2KFormat; // regA, regB, offset
def LC2KFormatJ : LC2KFormat; // regA, regB
def LC2KFormatO : LC2KFormat; // no operands

//===----------------------------------------------------------------------===//
// Per-family encodings
//===----------------------------------------------------------------------===//
//
// Each family has one InstructionEncoding class per format, selected by
// HwMode through the instruction's EncodingInfos (see LC2KFeatures.td). The
// field names (regA, regB, destReg, offset) must match the instruction's
// operand names.
//
//            31     28 27   24 23   20 19                    4 3       0
//   EECS 470 [opcode ] [regA ] [regB ] [ offset (20, I-type)  ] [destReg]
//
//            31   29 28   25 24   21 20                      4 3       0
//   Phobos   [opc  ] [regA ] [regB ] [  offset (21, I-type)   ] [destReg]
//
// R-type destReg overlaps the low bits of the (unused) offset field.

class LC2KEncodingBase : InstructionEncoding {
  let Size = 4;
  let DecoderNamespace = "LC2K";
  bits<32> Inst;
  bits<32> SoftFail = 0;
}

// EECS 470

class LC2KEncEECS470<LC2KOpcode opcode> : LC2KEncodingBase {
  let Inst{31-28} = opcode.EECS470Value;
}

class LC2KEncEECS470R<LC2KOpcode opcode> : LC2KEncEECS470<opcode> {
  bits<4> regA;
  bits<4> regB;
  bits<4> destReg;
  let Inst{27-24} = regA;
  let Inst{23-20} = regB;
  let Inst{3-0} = destReg;
}

class LC2KEncEECS470I<LC2KOpcode opcode> : LC2KEncEECS470<opcode> {
  bits<4> regA;
  bits<4> regB;
  bits<20> offset;
  let Inst{27-24} = regA;
  let Inst{23-20} = regB;
  let Inst{19-0} = offset;
}

class LC2KEncEECS470J<LC2KOpcode opcode> : LC2KEncEECS470<opcode> {
  bits<4> regA;
  bits<4> regB;
  let Inst{27-24} = regA;
  let Inst{23-20} = regB;
}

class LC2KEncEECS470O<LC2KOpcode opcode> : LC2KEncEECS470<opcode>;

// The EECS 470 mode and encoding of an instruction, or empty lists if
// EECS 470 doesn't have its opcode.
class LC2KEncodingsEECS470<LC2KOpcode opcode, LC2KFormat format> {
  defvar Has = !ge(opcode.EECS470Value, 0);
  list<HwMode> Modes = !if(Has, [ModeEECS470], []);
  list<InstructionEncoding> Encodings =
      !if(Has, [!cond(!eq(format, LC2KFormatR) : LC2KEncEECS470R<opcode>,
                      !eq(format, LC2KFormatI) : LC2KEncEECS470I<opcode>,
                      !eq(format, LC2KFormatJ) : LC2KEncEECS470J<opcode>,
                      !eq(format, LC2KFormatO) : LC2KEncEECS470O<opcode>)],
          []);
}

// Phobos

class LC2KEncPhobos<LC2KOpcode opcode> : LC2KEncodingBase {
  let Inst{31-29} = opcode.PhobosValue;
}

class LC2KEncPhobosR<LC2KOpcode opcode> : LC2KEncPhobos<opcode> {
  bits<4> regA;
  bits<4> regB;
  bits<4> destReg;
  let Inst{28-25} = regA;
  let Inst{24-21} = regB;
  let Inst{3-0} = destReg;
}

class LC2KEncPhobosI<LC2KOpcode opcode> : LC2KEncPhobos<opcode> {
  bits<4> regA;
  bits<4> regB;
  bits<21> offset;
  let Inst{28-25} = regA;
  let Inst{24-21} = regB;
  let Inst{20-0} = offset;
}

class LC2KEncPhobosJ<LC2KOpcode opcode> : LC2KEncPhobos<opcode> {
  bits<4> regA;
  bits<4> regB;
  let Inst{28-25} = regA;
  let Inst{24-21} = regB;
}

class LC2KEncPhobosO<LC2KOpcode opcode> : LC2KEncPhobos<opcode>;

// The Phobos mode and encoding of an instruction, or empty lists if Phobos
// doesn't have its opcode.
class LC2KEncodingsPhobos<LC2KOpcode opcode, LC2KFormat format> {
  defvar Has = !ge(opcode.PhobosValue, 0);
  list<HwMode> Modes = !if(Has, [ModePhobos], []);
  list<InstructionEncoding> Encodings =
      !if(Has, [!cond(!eq(format, LC2KFormatR) : LC2KEncPhobosR<opcode>,
                      !eq(format, LC2KFormatI) : LC2KEncPhobosI<opcode>,
                      !eq(format, LC2KFormatJ) : LC2KEncPhobosJ<opcode>,
                      !eq(format, LC2KFormatO) : LC2KEncPhobosO<opcode>)],
          []);
}

// The EncodingInfos of an instruction: its encoding in every family that has
// its opcode. An instruction has no encoding in the other families' modes
// and must never reach their encoder (it is gated by a predicate instead).
class LC2KEncodings<LC2KOpcode opcode, LC2KFormat format>
  : EncodingByHwMode<
        !listconcat(LC2KEncodingsEECS470<opcode, format>.Modes,
                    LC2KEncodingsPhobos<opcode, format>.Modes),
        !listconcat(LC2KEncodingsEECS470<opcode, format>.Encodings,
                    LC2KEncodingsPhobos<opcode, format>.Encodings)>;

//===----------------------------------------------------------------------===//
// Instruction formats
//===----------------------------------------------------------------------===//

class LC2KInst<LC2KOpcode opcode, LC2KFormat format, dag outs, dag ins,
               string operands>
  : Instruction {
  let Namespace = "LC2K";
  let DecoderNamespace = "LC2K";
  let Size = 4;

  LC2KOpcode Opcode = opcode;
  let EncodingInfos = LC2KEncodings<opcode, format>;

  dag OutOperandList = outs;
  dag InOperandList = ins;
  let Pattern = [];
  let AsmString = opcode.Name # operands;
}

class LC2KInstRType<LC2KOpcode opcode>
  : LC2KInst<opcode, LC2KFormatR, (outs GPR:$destReg),
             (ins GPR:$regA, GPR:$regB), "\t$regA\t$regB\t$destReg">;

// Applies to lw and addi since they write to a destination register
class LC2KInstITypeWriteReg<LC2KOpcode opcode>
  : LC2KInst<opcode, LC2KFormatI, (outs GPR:$regB),
             (ins GPR:$regA, LC2KOffset:$offset), "\t$regA\t$regB\t$offset">;

// Applies to sw and all branches because they don't write to a register
//
// IMPORTANT: regA comes after regB in the ins definition so that when
// doing FrameIndex elimination, the base and offset are in the same place
// within the MachineInstr.
class LC2KInstITypeReadOnly<LC2KOpcode opcode, Operand offsetOp = LC2KOffset>
  : LC2KInst<opcode, LC2KFormatI, (outs),
             (ins GPR:$regB, GPR:$regA, offsetOp:$offset),
             "\t$regA\t$regB\t$offset">;

class LC2KInstJType<LC2KOpcode opcode>
  : LC2KInst<opcode, LC2KFormatJ, (outs GPR:$regB), (ins GPR:$regA),
             "\t$regA\t$regB">;

class LC2KInstOType<LC2KOpcode opcode>
  : LC2KInst<opcode, LC2KFormatO, (outs), (ins), "">;

// Base class for pseudo-instructions: they have no real LC2K encoding and
// are always expanded or eliminated before final instruction emission, so
// (unlike LC2KInst) they don't carry an LC2KOpcode.
class LC2KPseudo<dag outs, dag ins, list<dag> pattern = []>
  : Instruction {
  let Namespace = "LC2K";

  // No real encoding, so no meaningful size.
  let Size = 0;

  dag OutOperandList = outs;
  dag InOperandList = ins;
  let Pattern = pattern;

  let isPseudo = 1;
  let isCodeGenOnly = 1;
}
