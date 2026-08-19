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
}  // isBranch = true, isTerminator = true

// This is equivalent to "beq 0 0 <target>"; need version with isBarrier set
// for branch analysis.
let isBranch = true, isTerminator = true, isBarrier = true, isCodeGenOnly = 1 in
def BEQ_UNCOND : LC2KInstITypeReadOnly<OPC_BEQ>;

// JALR is only built directly for a a return (CALL is a separate pseudo).
let isIndirectBranch = true, isTerminator = true, isReturn = true in {
def JALR  : LC2KInstJType<OPC_JALR>;
}  // isIndirectBranch = true, isTerminator = true, isReturn = true

def NOR   : LC2KInstRType<OPC_NOR>;
def NOOP  : LC2KInstOType<OPC_NOOP>;
def NAND  : LC2KInstRType<OPC_NAND>;

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
// JALR_CALL this lowers to will store the return address.
let isCall = 1, Defs = [R15] in {
def CALL : LC2KPseudo<(outs), (ins GPR:$callee)>;
}

// Real (encoded) form of JALR used specifically for calls, selected from
// the CALL pseudo above. Identical encoding to JALR -- both are simply
// "jump to regA, save return address in regB" -- but unlike JALR this form
// is explicitly not a terminator/return, since a call falls through to the
// next instruction once the callee returns. isCodeGenOnly since assembly
// should only ever spell this encoding as `jalr` (the return/tailcall
// form); the disassembler still decodes it back to plain JALR.
let isCall = 1, isCodeGenOnly = 1 in
def JALR_CALL : LC2KInstJType<OPC_JALR>;

// PSEUDO_SELECT and PSEUDO_CMP01 stand in for G_SELECT and G_ICMP (eq/ne):
// both require real, multi-block control flow to implement on LC2K (no
// conditional move and no compare-into-register instruction), which can't
// safely be built directly inside InstructionSelector::select() -- GISel's
// InstructionSelect pass is itself mid-traversal of the CFG (via
// post_order) while select() runs, so splitting the block being visited
// there corrupts that traversal. Instead these are expanded into the real
// branch/PHI sequences by a dedicated LC2KExpandPseudos pass that runs
// after InstructionSelect has fully finished, once the CFG is safe to
// mutate again. See GISel/LC2KExpandPseudos.cpp.
def PSEUDO_SELECT : LC2KPseudo<(outs GPR:$dst),
                               (ins GPR:$cond, GPR:$true, GPR:$false)>;
def PSEUDO_CMP01 : LC2KPseudo<(outs GPR:$dst),
                              (ins GPR:$lhs, GPR:$rhs, i32imm:$isEq)>;

