//===-- LC2KInstrFormats.td - LC2K Instruction Formats -----*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

def OffsetVT : VTInt<20>;  // NOTE: VTInt transitively included from Target.td

def OffsetAsmOperand : AsmOperandClass {
  let Name = "Offset";
  let RenderMethod = "addOffsetOperands";
  let DiagnosticType = "InvalidOffset";
}

def LC2KOffset : Operand<OffsetVT> {
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
