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

// JALR is only built directly for a a return (CALL is a separate pseudo).
let isIndirectBranch = true, isTerminator = true, isReturn = true in {
def JALR  : LC2KInstJType<OPC_JALR>;
}  // isIndirectBranch = true, isTerminator = true, isReturn = true

def NOR   : LC2KInstRType<OPC_NOR>;
def NOOP  : LC2KInstOType<OPC_NOOP>;
def NAND  : LC2KInstRType<OPC_NAND>;
def LSR   : LC2KInstJType<OPC_LSR>;
def ASR   : LC2KInstJType<OPC_ASR>;

}  // mayLoad = false, mayStore = false

}  // hasSideEffects = false

//===----------------------------------------------------------------------===//
// Pseudo-instructions
//===----------------------------------------------------------------------===//

// ADJCALLSTACKDOWN/UP implicitly use/def R14 (SP) because prolog-epilog
// rewriting needs to know they may adjust the stack pointer, even though on
// LC2K (which always reserves the call frame, see
// LC2KFrameLowering::hasFPImpl) they end up being erased without emitting
// any real instructions.
let Defs = [R14], Uses = [R14] in {
def ADJCALLSTACKDOWN : LC2KPseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2)>;
def ADJCALLSTACKUP   : LC2KPseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2)>;
} // Defs = [R14], Uses = [R14]

// Puts address of external symbol (e.g. compiler-inserted libcall) into a
// regster -- JALR can't take symbol name as argument. No LLVM-standard
// opcode for this, so need custom pseudo.
def ADDR_ES : LC2KPseudo<(outs GPR:$dst), (ins i32imm:$sym)>;

// Represents a call to $callee. Deliberately not modeled as JALR directly:
// a call falls through to the next instruction in the same block once the
// callee returns, so (unlike JALR's use as a return) it must not be a
// terminator. Implicitly defines RA (R15), since that's where the real
// JALR this eventually lowers to will store the return address. Needs a
// real lowering to JALR R15, $callee once instruction selection exists for
// LC2K.
let isCall = 1, Defs = [R15] in {
def CALL : LC2KPseudo<(outs), (ins GPR:$callee)>;
}

