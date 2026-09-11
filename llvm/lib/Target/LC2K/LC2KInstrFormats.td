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

class LC2KOpcode<string name, bits<4> value> {
  string Name = name;
  bits<4> Value = value;
}

class LC2KInst<dag outs, dag ins, list<dag> pattern = []>
  : Instruction {

  bits<32> Inst;

  let Namespace = "LC2K";
  let DecoderNamespace = "LC2K";
  let Size = 4;

  LC2KOpcode Opcode;
  let Inst{31-28} = Opcode.Value;

  dag OutOperandList = outs;
  dag InOperandList = ins;
  let Pattern = pattern;
}

class LC2KInstRType<LC2KOpcode opcode> : 
  LC2KInst<(outs GPR:$destReg), (ins GPR:$regA, GPR:$regB)> {
  bits<4> regA;
  bits<4> regB;
  bits<4> destReg;

  let Inst{27-24} = regA;
  let Inst{23-20} = regB;
  let Inst{3-0} = destReg;

  let Opcode = opcode;

  let AsmString = opcode.Name#"\t$regA\t$regB\t$destReg";
}

// Applies to lw and addi since they write to a destination register
class LC2KInstITypeWriteReg<LC2KOpcode opcode> : 
  LC2KInst<(outs GPR:$regB), (ins GPR:$regA, LC2KOffset:$offset)> {
  bits<4> regA;
  bits<4> regB;
  bits<20> offset;

  let Inst{27-24} = regA;
  let Inst{23-20} = regB;
  let Inst{19-0} = offset;

  let Opcode = opcode;

  let AsmString = opcode.Name#"\t$regA\t$regB\t$offset";
}

// Applies to sw and all branches because they don't write to a register
//
// IMPORTANT: regA comes after regB in the ins definition so that when
// doing FrameIndex elimination, the base and offset are in the same place
// within the MachineInstr.
class LC2KInstITypeReadOnly<LC2KOpcode opcode> : 
  LC2KInst<(outs), (ins GPR:$regB, GPR:$regA, LC2KOffset:$offset)> {
  bits<4> regA;
  bits<4> regB;
  bits<20> offset;

  let Inst{27-24} = regA;
  let Inst{23-20} = regB;
  let Inst{19-0} = offset;

  let Opcode = opcode;

  let AsmString = opcode.Name#"\t$regA\t$regB\t$offset";
}

class LC2KInstJType<LC2KOpcode opcode> :
  LC2KInst<(outs GPR:$regB), (ins GPR:$regA)> {
  bits<4> regA;
  bits<4> regB;

  let Inst{27-24} = regA;
  let Inst{23-20} = regB;

  let Opcode = opcode;

  let AsmString = opcode.Name#"\t$regA\t$regB";
}

class LC2KInstOType<LC2KOpcode opcode> :
  LC2KInst<(outs), (ins)> {
  let Opcode = opcode;

  let AsmString = opcode.Name;
}

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
