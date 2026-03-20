//===-- LC2KInstrInfo.td - Target Description for LC2K Target -------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the LC2K instructions in TableGen format.
//
//===----------------------------------------------------------------------===//

def OPC_ADD   : LC2KOpcode<"add",   0b0000>;
def OPC_NOR   : LC2KOpcode<"nor",   0b0001>;
def OPC_LW    : LC2KOpcode<"lw",    0b0010>;
def OPC_SW    : LC2KOpcode<"sw",    0b0011>;
def OPC_BEQ   : LC2KOpcode<"beq",   0b0100>;
def OPC_JALR  : LC2KOpcode<"jalr",  0b0101>;
def OPC_HALT  : LC2KOpcode<"halt",  0b0110>;
def OPC_NOOP  : LC2KOpcode<"noop",  0b0111>;
def OPC_ADDI  : LC2KOpcode<"addi",  0b1000>;
def OPC_NAND  : LC2KOpcode<"nand",  0b1001>;
def OPC_BLT   : LC2KOpcode<"blt",   0b1010>;
def OPC_BLTU  : LC2KOpcode<"bltu",  0b1011>;
def OPC_LSR   : LC2KOpcode<"lsr",   0b1100>;
def OPC_ASR   : LC2KOpcode<"asr",   0b1101>;

let 
  mayLoad = false, 
  mayStore = false, 
  hasSideEffects = true, 
  isTerminator = true
  in
def HALT  : LC2KInstOType<OPC_HALT>;

let hasSideEffects = false in {

let mayLoad = true, mayStore = false in {
def LW  : LC2KInstITypeWriteReg<OPC_LW>;
}  // mayLoad = true, mayStore = false

let mayLoad = false, mayStore = true in {
def SW  : LC2KInstITypeReadOnly<OPC_SW>;
}  // mayLoad = false, mayStore = true

let mayLoad = false, mayStore = false in {

let isAdd = true in {
def ADD   : LC2KInstRType<OPC_ADD>;
def ADDI  : LC2KInstITypeWriteReg<OPC_ADDI>;
}  // isAdd = true

let isBranch = true, isTerminator = true in {
def BEQ   : LC2KInstITypeReadOnly<OPC_BEQ>;
def BLT   : LC2KInstITypeReadOnly<OPC_BLT>;
def BLTU  : LC2KInstITypeReadOnly<OPC_BLTU>;
}  // isBranch = true, isTerminator = true

let isIndirectBranch = true, isTerminator = true in {
def JALR  : LC2KInstJType<OPC_JALR>;
}  // isIndirectBranch = true, isTerminator = true

def NOR   : LC2KInstRType<OPC_NOR>;
def NOOP  : LC2KInstOType<OPC_NOOP>;
def NAND  : LC2KInstRType<OPC_NAND>;
def LSR   : LC2KInstJType<OPC_LSR>;
def ASR   : LC2KInstJType<OPC_ASR>;

}  // mayLoad = false, mayStore = false

}  // hasSideEffects = false

