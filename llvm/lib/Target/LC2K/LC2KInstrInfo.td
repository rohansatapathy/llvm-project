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

def OPC_ADD  : LC2KOpcode<"add",  eecs470 = 0b0000, phobos = 0b000>;
def OPC_NOR  : LC2KOpcode<"nor",  eecs470 = 0b0001>;
def OPC_LW   : LC2KOpcode<"lw",   eecs470 = 0b0010, phobos = 0b010>;
def OPC_SW   : LC2KOpcode<"sw",   eecs470 = 0b0011, phobos = 0b011>;
def OPC_BEQ  : LC2KOpcode<"beq",  eecs470 = 0b0100, phobos = 0b100>;
def OPC_JALR : LC2KOpcode<"jalr", eecs470 = 0b0101, phobos = 0b101>;
def OPC_HALT : LC2KOpcode<"halt", eecs470 = 0b0110, phobos = 0b110>;
def OPC_NOOP : LC2KOpcode<"noop", eecs470 = 0b0111>;
def OPC_ADDI : LC2KOpcode<"addi", eecs470 = 0b1000, phobos = 0b111>;
def OPC_NAND : LC2KOpcode<"nand", eecs470 = 0b1001, phobos = 0b001>;

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
def BEQ   : LC2KInstITypeReadOnly<OPC_BEQ, LC2KBrTarget>;
}  // isBranch = true, isTerminator = true

// This is equivalent to "beq 0 0 <target>"; need version with isBarrier set
// for branch analysis.
let isBranch = true, isTerminator = true, isBarrier = true, isCodeGenOnly = 1 in
def BEQ_UNCOND : LC2KInstITypeReadOnly<OPC_BEQ, LC2KBrTarget>;

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

// Real (encoded) form of JALR used for the indirect branch a jump-table
// dispatch (G_BRJT/G_BRINDIRECT, see LC2KLegalizerInfo::legalizeBRJT and
// LC2KInstructionSelector::selectBrIndirect) bottoms out into. Identical
// encoding to JALR -- again "jump to regA, save return address in regB" --
// but unlike JALR this form is not a return: it's a mid-function branch
// with real successors (the switch's case blocks), so it must not carry
// isReturn (which would make later passes treat it as having no
// successors) or isCall (it doesn't fall through). The discarded
// return-address write goes to R0 (hardwired zero), exactly like the real
// JALR return sequence discards its own equivalent write (see
// LC2KCallLowering::lowerReturn). isCodeGenOnly for the same reason as
// JALR_CALL: assembly should only ever spell this encoding as `jalr`, and
// the disassembler decodes it back to plain JALR.
let isIndirectBranch = true, isTerminator = true, isBarrier = true,
    isCodeGenOnly = 1 in
def JALR_IND : LC2KInstJType<OPC_JALR>;

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

//===----------------------------------------------------------------------===//
// GlobalISel selection patterns
//===----------------------------------------------------------------------===//

// NOTE:
// - ImmLeaf can't query subtarget, so each immediate width gets its own
//   leaf type. Make sure to keep in sync w/ LC2KSubtarget::getImmBits().
// - Large constants are split during legalization, so no need to handle
//   here.
// - Null pointers handled by selectConstant since p0 != s32.
def simm20 : ImmLeaf<i32, [{ return isInt<20>(Imm); }]>;
def simm21 : ImmLeaf<i32, [{ return isInt<21>(Imm); }]>;

let Predicates = [HasEncEECS470] in
def : Pat<(i32 simm20:$imm), (ADDI (i32 R0), simm20:$imm)>;
let Predicates = [HasEncPhobos] in
def : Pat<(i32 simm21:$imm), (ADDI (i32 R0), simm21:$imm)>;

// to_tframeindex (and its GlobalISel renderer, renderFrameIndex) come from
// common code: TargetSelectionDAG.td / GlobalISel/SelectionDAGCompat.td.
def : Pat<(frameindex:$fi), (ADDI (iPTR (to_tframeindex $fi)), 0)>;

def : Pat<(br bb:$target), (BEQ_UNCOND (i32 R0), (i32 R0), bb:$target)>;

def : Pat<(add GPR:$lhs, GPR:$rhs), (ADD GPR:$lhs, GPR:$rhs)>;

let Predicates = [HasNAND] in {
// a - b == a + (~b + 1); ~b via NAND(b,b).
def : Pat<(sub GPR:$lhs, GPR:$rhs),
          (ADD GPR:$lhs, (ADDI (NAND GPR:$rhs, GPR:$rhs), 1))>;

// a & b == ~NAND(a,b) == NAND(t,t) with t = NAND(a,b). Two instructions once
// MachineCSE merges the duplicated NAND(a,b).
def : Pat<(and GPR:$lhs, GPR:$rhs),
          (NAND (NAND GPR:$lhs, GPR:$rhs), (NAND GPR:$lhs, GPR:$rhs))>;

// a ^ b == (a NAND t) NAND (b NAND t) with t = a NAND b. Four instructions
// once MachineCSE merges the duplicated NAND(a,b).
def : Pat<(xor GPR:$lhs, GPR:$rhs),
          (NAND (NAND GPR:$lhs, (NAND GPR:$lhs, GPR:$rhs)),
                (NAND GPR:$rhs, (NAND GPR:$lhs, GPR:$rhs)))>;

// ~a = a NAND a. Takes priority over the general XOR pattern above, which would
// otherwise materialize -1 and spend four NANDs on it.
def : Pat<(not GPR:$src), (NAND GPR:$src, GPR:$src)>;

// a | b == ~a NAND ~b. Three instructions; the NOR form below is preferred
// when available.
def : Pat<(or GPR:$lhs, GPR:$rhs),
          (NAND (NAND GPR:$lhs, GPR:$lhs), (NAND GPR:$rhs, GPR:$rhs))>;
} // Predicates = [HasNAND]

let Predicates = [HasNOR] in {
// a | b == NOT(NOR(a,b)) == NOR(NOR(a,b), NOR(a,b)). Two instructions once
// MachineCSE merges the duplicated NOR(a,b).
let AddedComplexity = 1 in
def : Pat<(or GPR:$lhs, GPR:$rhs),
          (NOR (NOR GPR:$lhs, GPR:$rhs), (NOR GPR:$lhs, GPR:$rhs))>;

// ~(a | b) = a NOR b
def : Pat<(not (or GPR:$lhs, GPR:$rhs)), (NOR GPR:$lhs, GPR:$rhs)>;
} // Predicates = [HasNOR]
