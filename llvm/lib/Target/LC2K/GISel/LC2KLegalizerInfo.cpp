//===-- LC2KLegalizerInfo.cpp -----------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file implements the targeting of the LegalizerInfo class for LC2K.
///
//===----------------------------------------------------------------------===//

#include "LC2KLegalizerInfo.h"
#include "LC2KMachineFunctionInfo.h"
#include "llvm/CodeGen/GlobalISel/GenericMachineInstrs.h"
#include "llvm/CodeGen/GlobalISel/LegalizerHelper.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineJumpTableInfo.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/RuntimeLibcalls.h"
#include "llvm/Support/MathExtras.h"

#define DEBUG_TYPE "lc2k-legalizer-info"

using namespace llvm;

LC2KLegalizerInfo::LC2KLegalizerInfo(const LC2KSubtarget &ST) {
  using namespace TargetOpcode;

  const LLT s1 = LLT::scalar(1);
  const LLT s16 = LLT::scalar(16);
  const LLT s32 = LLT::scalar(32);
  const LLT s64 = LLT::scalar(64);
  const LLT p0 = LLT::pointer(0, 32);

  // Merge/unmerge values between 64-bit multi-word types and 32-bit words.
  getActionDefinitionsBuilder(G_MERGE_VALUES).legalFor({{s64, s32}});
  getActionDefinitionsBuilder(G_UNMERGE_VALUES).legalFor({{s32, s64}});

  // LC2K's only integer type is a 32-bit word: char/short/int are all 32
  // bits wide at the Clang target level, so the frontend never produces
  // narrower integer types for real source programs. Anything narrower than
  // s32 is deliberately left with no rule below, so legalization fails
  // loudly if it's ever produced instead of being silently miscompiled.

  // p0 is included alongside s32 (like G_IMPLICIT_DEF below): a
  // null-pointer literal (`ptr == 0`, `ptr == NULL`, a default-initialized
  // pointer, ...) is translated directly to `G_CONSTANT p0, 0` by
  // IRTranslator's ConstantPointerNull handling, never routed through
  // G_INTTOPTR. selectConstant already handles this correctly as-is: it
  // never inspects Dst's LLT, just materializes the bit pattern into
  // whatever GPR Dst gets constrained to.
  // Values that fit a single ADDI immediate stay legal (see
  // materializeConstant); wider s32 values are split by legalizeConstant
  // below into a 12-bit high half shifted into position via the __lc2k_shl
  // libcall (see legalizeShift) plus a 20-bit low half, since LC2K has no
  // shift hardware to build them bit-serially inline. p0 is left alone: a
  // null-pointer literal is always G_CONSTANT p0, 0 (see the comment
  // above), so it never needs the wide-value path.
  getActionDefinitionsBuilder(G_CONSTANT)
      .legalFor({p0})
      .customFor({s32})
      .clampScalar(0, s32, s32);

  getActionDefinitionsBuilder(G_IMPLICIT_DEF)
      .legalFor({s32, p0})
      .clampScalar(0, s32, s32);

  getActionDefinitionsBuilder(G_BR).alwaysLegal();

  // The indirect branch a jump-table dispatch bottoms out into (see
  // legalizeBRJT below): the target address is just a plain word address in
  // a GPR, exactly like a computed pointer value anywhere else.
  getActionDefinitionsBuilder(G_BRINDIRECT).legalFor({p0});

  // G_JUMP_TABLE materializes the base address of a jump table, exactly like
  // G_GLOBAL_VALUE materializes a global's address (see selectGlobalValue /
  // the analogous selectJumpTable) -- both are plain word addresses.
  getActionDefinitionsBuilder(G_JUMP_TABLE).legalFor({p0});

  // G_BRJT combines an address computation, a load, and an indirect branch
  // into one generic op; LC2K has no single instruction that does all of
  // that, so it's expanded by legalizeBRJT into the already-legal G_PTR_ADD
  // + G_LOAD + G_BRINDIRECT sequence below instead. Unlike byte-addressed
  // targets, no shift-by-log2(entry size) is needed first: LC2K is
  // word-addressed (see the file header comment in
  // LC2KInstructionSelector.cpp) and every jump table entry is exactly one
  // word (a target block's address), so the case index the switch computes
  // is already the correct word offset into the table.
  getActionDefinitionsBuilder(G_BRJT).customFor({{p0, s32}});

  getActionDefinitionsBuilder(G_PHI).legalFor({s32, p0}).clampScalar(0, s32,
                                                                     s32);

  getActionDefinitionsBuilder(G_FRAME_INDEX).legalFor({p0});

  getActionDefinitionsBuilder(G_GLOBAL_VALUE).legalFor({p0});

  getActionDefinitionsBuilder(G_PTR_ADD).legalFor({{p0, s32}});

  // Pointers and s32 integers are both 32-bit values living in the same
  // (only) register bank/class on LC2K, so converting between them is a
  // pure reinterpretation of the same bits -- no actual instruction is
  // needed (see selectPtrIntCast).
  getActionDefinitionsBuilder(G_PTRTOINT).legalFor({{s32, p0}});
  getActionDefinitionsBuilder(G_INTTOPTR).legalFor({{p0, s32}});

  getActionDefinitionsBuilder({G_ADD, G_SUB})
      .legalFor({s32})
      .clampScalar(0, s32, s32);

  // AND/OR/XOR additionally need to be legal at s1: the generic .lower()
  // expansions for the overflow-arithmetic ops below (G_UADDE/G_USUBE need
  // AND+OR, G_SADDO/G_SSUBO need XOR) combine their boolean carry/borrow/
  // overflow results with plain AND/OR/XOR at the s1 result type, not s32.
  // Instruction selection doesn't care about LLT (LC2K has only one
  // register class), so selectAnd/selectOr/selectXor need no changes.
  getActionDefinitionsBuilder({G_AND, G_OR, G_XOR})
      .legalFor({s32, s1})
      .clampScalar(0, s32, s32);

  getActionDefinitionsBuilder({G_LOAD, G_STORE})
      .legalFor({{s32, p0}, {p0, p0}})
      .clampScalar(0, s32, s32);

  // LC2K has no multiply or divide/remainder hardware. These are lowered to
  // calls to the standard compiler-rt/libgcc runtime routines.
  getActionDefinitionsBuilder({G_MUL, G_SDIV, G_UDIV, G_SREM, G_UREM})
      .libcallFor({s32, s64});

  // LC2K has no shift instructions at all. 32-bit shifts are lowered to
  // calls to LC2K-specific runtime routines via legalizeCustom below. There's
  // no such routine for 64-bit shifts (and no generic Libcall support for
  // shift opcodes in LegalizerHelper either): instead, clampScalar(0, ...)
  // narrows a 64-bit shift into a handful of 32-bit shift/or/select
  // operations (the standard double-shift algorithm -- see
  // LegalizerHelper::narrowScalarShift), each of which re-enters
  // legalization and hits this same customFor(s32) rule. The shift
  // *amount* is clamped to s32 first (clampScalar(1, ...), listed before
  // the value's own clamp) so that expansion's internal comparisons/
  // arithmetic, and the newly-synthesized 32-bit shifts, all start out
  // with an already-s32 amount -- legalizeShift's call-lowering assumes
  // both operands it's handed are exactly s32, which customFor({{s32,s32}})
  // (a pair match, unlike a bare customFor({s32})) enforces.
  getActionDefinitionsBuilder({G_SHL, G_LSHR, G_ASHR})
      .customFor({{s32, s32}})
      .clampScalar(1, s32, s32)
      .clampScalar(0, s32, s32);

  // LC2K's only compare-and-branch instruction is BEQ: there's no hardware
  // support for any relational comparison (<,<=,>,>=, signed or unsigned).
  // EQ/NE map onto BEQ directly (or its inverse) in a fixed, cheap
  // instruction sequence, so those are left alone by legalizeCustom below
  // (deferred to instruction selection, like G_SUB/G_AND/G_OR/G_XOR above).
  // The 8 relational predicates have no cheap hardware realization at all
  // (would need a bit-serial software comparison), so those are rewritten
  // into calls to just two runtime primitives -- signed and unsigned
  // less-than -- with the other 6 predicates derived via operand-swapping
  // and result negation.
  //
  // p0 is included alongside s32 (like G_SELECT below) since pointers and
  // s32 integers are bit-identical values in the same register class on
  // LC2K (see the G_PTRTOINT/G_INTTOPTR comment above) -- null checks and
  // pointer-equality comparisons (`ptr == 0`, `p1 != p2`) hit this same
  // {s1, p0} instance and legalizeICmp's EQ/NE path already handles it
  // correctly as-is, since it never inspects the compared operands' LLT.
  getActionDefinitionsBuilder(G_ICMP)
      .customFor({{s1, s32}, {s1, p0}})
      .clampScalar(1, s32, s32);

  // G_BRCOND and G_SELECT are also cheap to synthesize from BEQ (materialize
  // a zero constant and branch, or a short 2-way branch sequence) in a fixed
  // number of instructions, so like G_SUB/G_AND/G_OR/G_XOR these are left
  // legal and deferred to instruction selection.
  getActionDefinitionsBuilder(G_BRCOND).legalFor({s1});
  getActionDefinitionsBuilder(G_SELECT)
      .legalFor({{s32, s1}, {p0, s1}})
      .clampScalar(0, s32, s32);

  // Needed to convert s32 ICmp results down to nominal s1, or s64 down to s32.
  getActionDefinitionsBuilder(G_TRUNC)
      .legalFor({{s1, s32}})
      .customFor({{s32, s64}});

  // Extending s1 to s32 is deferred to isel; extending to s64 (whether from
  // s32 or straight from s1) is custom-lowered by combining with 0
  // (ZEXT/ANYEXT) or arithmetic sign-shift (SEXT) -- see legalizeExt, which
  // widens an s1 source to s32 first via the legal {s32, s1} case above.
  getActionDefinitionsBuilder({G_ZEXT, G_SEXT, G_ANYEXT})
      .legalFor({{s32, s1}})
      .customFor({{s64, s32}, {s64, s1}});

  // G_FREEZE has no corresponding LC2K instruction -- it's a pure IR/MIR
  // concept (an arbitrary but well-defined value standing in for
  // poison/undef) that's always a no-op copy at selection time, for any
  // type LC2K actually has a register class for.
  getActionDefinitionsBuilder(G_FREEZE).legalFor({s1, s32, p0});

  // No sub-word memory types exist on LC2K (see the s32-only note above),
  // and this target has no GISel combiner pipeline to fold shl+ashr pairs
  // into G_SEXT_INREG, so none of these should ever be generated. Marked
  // explicitly unsupported rather than left with no rule at all so that
  // failure is immediate rather than routed through the (unused) legacy
  // legalizer fallback.
  //
  // G_BITCAST is here too: MachineVerifier hard-rejects any bitcast whose
  // types disagree on pointer-ness (see G_BITCAST handling in
  // MachineVerifier.cpp), so the only pairing LC2K's current type system
  // could offer -- s32 <-> p0 -- can never legally exist. There is no
  // reachable legal use of G_BITCAST until a same-"shape" type (e.g. a
  // future float32) exists to pair with s32.
  getActionDefinitionsBuilder({G_SEXT_INREG, G_SEXTLOAD, G_ZEXTLOAD, G_BITCAST})
      .unsupported();

  // The generic expansions for these all bottom out in G_ADD/G_SUB (already
  // legal) plus a G_ICMP predicate LC2K's legalizeICmp already knows how to
  // handle -- EQ/NE directly, everything else (SLT/SGT/ULT here) via the
  // __lc2k_slt/__lc2k_ult libcalls.
  getActionDefinitionsBuilder(
      {G_SADDO, G_SSUBO, G_SADDE, G_SSUBE, G_UADDO, G_UADDE, G_USUBO, G_USUBE})
      .lower();

  // G_SMULO/G_UMULO and G_SMULH/G_UMULH lower using generic expansions that
  // widen through 64-bit multiplications.
  getActionDefinitionsBuilder({G_SMULO, G_UMULO, G_SMULH, G_UMULH}).lower();

  // Neither G_SMIN/G_UMIN/G_SMAX has a rule (yet), so these always fall to
  // the AddoSubo/ShlSat generic expansions rather than the min/max-based
  // ones. Those expansions bottom out entirely in ops LC2K already handles:
  // G_UADDO/G_SADDO/G_USUBO/G_SSUBO (lowered above), G_SHL/G_LSHR/G_ASHR
  // (customFor -> libcalls), G_ADD/G_CONSTANT (legal), G_SELECT at
  // {s32, s1} (legal), and G_ICMP SLT/NE (SLT -> __lc2k_slt libcall, NE
  // free).
  getActionDefinitionsBuilder(
      {G_SADDSAT, G_UADDSAT, G_SSUBSAT, G_USUBSAT, G_SSHLSAT, G_USHLSAT})
      .lower();

  // G_SMAX/G_SMIN/G_UMAX/G_UMIN lower to a relational G_ICMP + G_SELECT at
  // {s32, s1} -- both already handled. G_SCMP/G_UCMP lower to G_CONSTANT +
  // a relational G_ICMP, then (since LC2KISelLowering never overrides
  // TargetLoweringBase's default BooleanContents of UndefinedBooleanContent)
  // a pair of G_SELECTs rather than a G_ZEXT+G_SUB -- also already handled
  // either way. G_ABS lowers to G_ASHR (customFor -> libcall) + G_ADD +
  // G_XOR. G_ABDS/G_ABDU always take the select-based expansion (the
  // min/max-based alternative only triggers when G_SMIN et al. are legal,
  // not merely lowered), which is G_SUB x2 + a relational G_ICMP + G_SELECT.
  getActionDefinitionsBuilder(
      {G_SMAX, G_SMIN, G_UMAX, G_UMIN, G_SCMP, G_UCMP, G_ABS, G_ABDS, G_ABDU})
      .lower();

  // TODO: G_BSWAP/G_BITREVERSE/G_CTPOP/G_CTLZ/G_CTTZ/G_CTLS all expand into
  // long chains of G_SHL/G_LSHR/G_ASHR (each its own libcall on LC2K, since
  // there's no shift hardware) -- e.g. G_CTLZ's default expansion alone
  // chains into ~11 separate shift libcalls per call, since it falls back
  // to G_CTPOP internally. G_ROTL/G_ROTR/G_FSHL/G_FSHR are cheaper (2-3
  // shift libcalls). Using .lower() for all of them for now is functionally
  // fine but not code-size-friendly; if any of these turn out to be
  // generated often enough to matter (e.g. via __builtin_popcount/clz/ctz,
  // __builtin_bswap*, or InstCombine's byte-swap/bit-reverse/funnel-shift
  // idiom recognition at -O1+), revisit with dedicated single-libcall
  // runtime routines instead, the same way shifts and relational compares
  // are handled.
  getActionDefinitionsBuilder({G_BITREVERSE, G_BSWAP, G_CTLZ,
                               G_CTLZ_ZERO_POISON, G_CTTZ,
                               G_CTTZ_ZERO_POISON, G_CTPOP, G_CTLS, G_ROTL,
                               G_ROTR, G_FSHL, G_FSHR})
      .lower();

  // Trivially splits into G_SDIV+G_SREM / G_UDIV+G_UREM, both already
  // libcalls.
  getActionDefinitionsBuilder({G_SDIVREM, G_UDIVREM}).lower();

  // LC2K has no vector types, so these should never be generated.
  getActionDefinitionsBuilder({G_EXTRACT_VECTOR_ELT, G_INSERT_VECTOR_ELT,
                               G_SHUFFLE_VECTOR, G_VECTOR_COMPRESS})
      .unsupported();

  // LC2K has no atomic/concurrency support, so these should never be
  // generated.
  getActionDefinitionsBuilder({G_ATOMIC_CMPXCHG_WITH_SUCCESS, G_ATOMICRMW_SUB})
      .unsupported();

  // Emitted as calls to the target's memcpy/memmove/memset instead of
  // expanded inline: LC2K's byte is a full 32-bit word (see the DataLayout),
  // so an inline loads/stores expansion would need to speak in words rather
  // than the byte-granular lengths/offsets LegalizerHelper's lower() assumes.
  getActionDefinitionsBuilder({G_MEMCPY, G_MEMMOVE, G_MEMSET}).libcall();

  // G_MEMCPY_INLINE forbids ever being lowered as a call (that's the entire
  // point of __builtin_memcpy_inline), so the libcall action above isn't an
  // option for it, and it always reaches here with a compile-time-constant
  // length (PreISelIntrinsicLowering expands any non-constant-length
  // instance into a real IR loop before this legalizer ever runs). Without
  // an inline loads/stores expansion (same word-vs-byte gap as above), it
  // stays illegal.
  getActionDefinitionsBuilder(G_MEMCPY_INLINE).unsupported();

  // LC2K has no frame pointer (see LC2KFrameLowering::hasFPImpl): every
  // local/spill/outgoing-arg slot is addressed as a compile-time-constant
  // offset from SP, which is only valid because SP moves by one fixed
  // amount in the prologue and nowhere else. A dynamic alloca would need to
  // move SP by a runtime-variable amount mid-function, invalidating every
  // later SP-relative access -- not just a legalizer-level gap. See
  // __STDC_NO_VLA__ in LC2K.cpp.
  getActionDefinitionsBuilder({G_DYN_STACKALLOC, G_STACKSAVE, G_STACKRESTORE})
      .unsupported();

  // Splits into a load/round-up/advance/store/load sequence over G_LOAD,
  // G_STORE, G_CONSTANT, and G_PTR_ADD, all already legal for {s32,p0}/
  // {p0,p0}. The alignment round-up step only emits a G_PTRMASK (which LC2K
  // has no rule for) when the argument's alignment exceeds
  // TLI.getMinStackArgumentAlignment() -- set to 4 above, matching LC2K's
  // always-word-aligned stack, so that never happens for s32/p0 varargs.
  getActionDefinitionsBuilder(G_VAARG).lower();

  // Builds a G_FRAME_INDEX + G_STORE (both already legal for p0) pointing
  // at the fixed-stack slot LC2KCallLowering::lowerFormalArguments recorded
  // as the start of the vararg region. See legalizeVAStart.
  getActionDefinitionsBuilder(G_VASTART).customFor({p0});

  // TLI.getRegisterByName has no LC2K override, and its base implementation
  // is report_fatal_error (not a graceful bail-out), so .lower() would hard
  // crash rather than fail cleanly. LC2K also disallows inline asm entirely
  // (see validateAsmConstraint), and named-register variables are a GNU
  // extension that's only meaningful alongside it, so this is unreachable
  // regardless.
  getActionDefinitionsBuilder({G_READ_REGISTER, G_WRITE_REGISTER})
      .unsupported();

  // float16/float32/float64 softfloat support. f16 has no arithmetic of its
  // own on LC2K -- it's always widened to f32 (computed there, since that's
  // what the libcalls below operate on), and only the fpext/fptrunc at the
  // f16 boundary itself need dedicated libcalls (see G_FPEXT/G_FPTRUNC
  // below). This mirrors how i8/i16 are promoted to i32 in the calling
  // convention (LC2KCallingConv.td), except the widening also has to
  // reach every FP opcode here rather than just argument passing, since
  // f16 has no native representation to compute in at all.

  // G_FNEG/G_FABS/G_FCOPYSIGN are pure sign-bit manipulation -- their
  // generic expansions are G_CONSTANT + G_XOR/G_AND/G_OR, narrowed to s32
  // words. f16 is widened to f32 first so it hits that same expansion.
  getActionDefinitionsBuilder({G_FNEG, G_FABS, G_FCOPYSIGN})
      .widenScalarIf(LegalityPredicates::scalarNarrowerThan(0, 32),
                     LegalizeMutations::changeTo(0, s32))
      .lower();

  // G_FCONSTANT at s32 is materialized directly (see selectFConstant);
  // G_FCONSTANT at s64 is custom-lowered to two 32-bit constants merged;
  // G_FCONSTANT at s16 is widened (preserving its exact bit pattern) to a
  // 32-bit materialization that's then truncated back down.
  getActionDefinitionsBuilder(G_FCONSTANT)
      .legalFor({s32})
      .customFor({s64})
      .clampScalar(0, s32, s32);

  // Soft-float arithmetic, remainder, and comparisons: only s32/s64 have
  // libcalls of their own, so f16 operands are fpext-ed up to f32 first.
  getActionDefinitionsBuilder({G_FADD, G_FSUB, G_FMUL, G_FDIV, G_FREM})
      .libcallFor({s32, s64})
      .clampScalar(0, s32, s64);
  getActionDefinitionsBuilder(G_FCMP)
      .libcallFor({{s1, s32}, {s1, s64}})
      .clampScalar(1, s32, s64);

  // Precision conversions. The f16 <-> f32/f64 boundary itself needs
  // dedicated libcalls (there's no way to "widen out of" the conversion
  // that defines the boundary); f32 <-> f64 conversion was already
  // supported.
  getActionDefinitionsBuilder(G_FPEXT).libcallFor(
      {{s32, s16}, {s64, s32}, {s64, s16}});
  getActionDefinitionsBuilder(G_FPTRUNC).libcallFor(
      {{s16, s32}, {s32, s64}, {s16, s64}});

  // Float <-> integer conversions routing to standard compiler-rt/libgcc
  // routines. The float side is clamped to s32/s64 (an f16 source is
  // fpext-ed up first; an f16 result is computed at f32 then fptrunc-ed
  // down); the integer side is intentionally left at s32/s64 only, same as
  // everywhere else in this file.
  getActionDefinitionsBuilder({G_FPTOSI, G_FPTOUI})
      .libcallFor({{s32, s32}, {s32, s64}, {s64, s32}, {s64, s64}})
      .clampScalar(1, s32, s64);
  getActionDefinitionsBuilder({G_SITOFP, G_UITOFP})
      .libcallFor({{s32, s32}, {s64, s32}, {s32, s64}, {s64, s64}})
      .clampScalar(0, s32, s64);

  getLegacyLegalizerInfo().computeTables();
}

bool LC2KLegalizerInfo::legalizeCustom(
    LegalizerHelper &Helper, MachineInstr &MI,
    LostDebugLocObserver &LocObserver) const {
  switch (MI.getOpcode()) {
  case TargetOpcode::G_SHL:
  case TargetOpcode::G_LSHR:
  case TargetOpcode::G_ASHR:
    return legalizeShift(Helper, MI, LocObserver);
  case TargetOpcode::G_ICMP:
    return legalizeICmp(Helper, MI, LocObserver);
  case TargetOpcode::G_VASTART:
    return legalizeVAStart(Helper, MI);
  case TargetOpcode::G_ZEXT:
  case TargetOpcode::G_ANYEXT:
  case TargetOpcode::G_SEXT:
    return legalizeExt(Helper, MI);
  case TargetOpcode::G_TRUNC:
    return legalizeTrunc(Helper, MI);
  case TargetOpcode::G_FCONSTANT:
    return legalizeFConstant(Helper, MI);
  case TargetOpcode::G_BRJT:
    return legalizeBRJT(Helper, MI);
  case TargetOpcode::G_CONSTANT:
    return legalizeConstant(Helper, MI, LocObserver);
  default:
    return false;
  }
}

bool LC2KLegalizerInfo::legalizeVAStart(LegalizerHelper &Helper,
                                        MachineInstr &MI) const {
  MachineFunction &MF = *MI.getMF();
  int FI = MF.getInfo<LC2KMachineFunctionInfo>()->getVarArgsFrameIndex();

  MachineIRBuilder &MIRBuilder = Helper.MIRBuilder;
  auto Addr = MIRBuilder.buildFrameIndex(LLT::pointer(0, 32), FI);
  MIRBuilder.buildStore(Addr, MI.getOperand(0).getReg(), MachinePointerInfo(),
                        Align(4));

  MI.eraseFromParent();
  return true;
}

bool LC2KLegalizerInfo::legalizeShift(LegalizerHelper &Helper, MachineInstr &MI,
                                      LostDebugLocObserver &LocObserver) const {
  RTLIB::Libcall Libcall;
  switch (MI.getOpcode()) {
  case TargetOpcode::G_SHL:
    Libcall = RTLIB::SHL_I32;
    break;
  case TargetOpcode::G_LSHR:
    Libcall = RTLIB::SRL_I32;
    break;
  case TargetOpcode::G_ASHR:
    Libcall = RTLIB::SRA_I32;
    break;
  default:
    llvm_unreachable("Unexpected opcode");
  }

  Type *S32Ty = IntegerType::get(MI.getMF()->getFunction().getContext(), 32);
  CallLowering::ArgInfo Result = {MI.getOperand(0).getReg(), S32Ty, 0};
  SmallVector<CallLowering::ArgInfo, 2> Args = {
      {MI.getOperand(1).getReg(), S32Ty, 0},
      {MI.getOperand(2).getReg(), S32Ty, 0}};

  // Unlike LegalizerHelper::libcall(), the Custom legalization action does
  // not erase MI on success automatically -- that's the custom
  // implementation's own responsibility.
  if (Helper.createLibcall(Libcall, Result, Args, LocObserver, &MI) !=
      LegalizerHelper::Legalized)
    return false;

  MI.eraseFromParent();
  return true;
}

bool LC2KLegalizerInfo::legalizeConstant(
    LegalizerHelper &Helper, MachineInstr &MI,
    LostDebugLocObserver &LocObserver) const {
  int64_t Val = MI.getOperand(1).getCImm()->getSExtValue();

  // Already a single ADDI in the selector (see materializeConstant) --
  // nothing to do.
  if (isInt<20>(Val))
    return true;

  // No shift hardware exists, so split the 32-bit pattern the same way
  // RISC-V's lui/addi pair does: a signed 20-bit Lo half that always fits a
  // single ADDI immediate on its own, and a 12-bit Hi half rounded to
  // compensate for Lo's sign so that (Hi << 20) + Lo reconstructs Val
  // exactly.
  //
  // Hi is shifted into position by calling the __lc2k_shl runtime routine
  // directly (the same one legalizeShift above routes G_SHL to), rather
  // than building a G_SHL generic op and relying on it to re-legalize:
  // Hi and the shift amount are both compile-time-known constants, and the
  // legalizer's CSEMIRBuilder constant-folds a G_SHL of two constants
  // straight back into the original wide literal (see ConstantFoldBinOp in
  // CSEMIRBuilder.cpp) instead of leaving a real G_SHL to legalize -- an
  // infinite loop, not a real fixed point. Calling createLibcall directly
  // sidesteps that: its result register is opaque to the constant folder,
  // so the final G_ADD with Lo below is never folded away either.
  MachineIRBuilder &MIRBuilder = Helper.MIRBuilder;
  MachineRegisterInfo &MRI = *MIRBuilder.getMRI();
  LLT S32 = LLT::scalar(32);

  uint32_t Bits = static_cast<uint32_t>(Val);
  int32_t Lo = SignExtend32<20>(Bits & 0xFFFFF);
  uint32_t Hi = (Bits - static_cast<uint32_t>(Lo)) >> 20;

  auto HiConst = MIRBuilder.buildConstant(S32, Hi);
  auto ShiftAmt = MIRBuilder.buildConstant(S32, 20);

  Type *S32Ty = IntegerType::get(MI.getMF()->getFunction().getContext(), 32);
  Register Shifted = MRI.createGenericVirtualRegister(S32);
  CallLowering::ArgInfo Result = {Shifted, S32Ty, 0};
  SmallVector<CallLowering::ArgInfo, 2> Args = {
      {HiConst.getReg(0), S32Ty, 0}, {ShiftAmt.getReg(0), S32Ty, 0}};
  if (Helper.createLibcall(RTLIB::SHL_I32, Result, Args, LocObserver, &MI) !=
      LegalizerHelper::Legalized)
    return false;

  auto LoConst = MIRBuilder.buildConstant(S32, Lo);
  MIRBuilder.buildAdd(MI.getOperand(0).getReg(), Shifted, LoConst);

  MI.eraseFromParent();
  return true;
}

bool LC2KLegalizerInfo::legalizeICmp(LegalizerHelper &Helper, MachineInstr &MI,
                                     LostDebugLocObserver &LocObserver) const {
  auto &Cmp = cast<GICmp>(MI);
  CmpInst::Predicate Pred = Cmp.getCond();

  // EQ/NE map directly onto BEQ (or its inverse); leave them legal and
  // defer synthesis to instruction selection.
  if (Pred == CmpInst::ICMP_EQ || Pred == CmpInst::ICMP_NE)
    return true;

  RTLIB::Libcall Libcall;
  Register LHS = Cmp.getLHSReg();
  Register RHS = Cmp.getRHSReg();
  bool Negate;
  switch (Pred) {
  case CmpInst::ICMP_SLT:
    Libcall = RTLIB::LC2K_SLT;
    Negate = false;
    break;
  case CmpInst::ICMP_SGT:
    Libcall = RTLIB::LC2K_SLT;
    std::swap(LHS, RHS);
    Negate = false;
    break;
  case CmpInst::ICMP_SLE:
    Libcall = RTLIB::LC2K_SLT;
    std::swap(LHS, RHS);
    Negate = true;
    break;
  case CmpInst::ICMP_SGE:
    Libcall = RTLIB::LC2K_SLT;
    Negate = true;
    break;
  case CmpInst::ICMP_ULT:
    Libcall = RTLIB::LC2K_ULT;
    Negate = false;
    break;
  case CmpInst::ICMP_UGT:
    Libcall = RTLIB::LC2K_ULT;
    std::swap(LHS, RHS);
    Negate = false;
    break;
  case CmpInst::ICMP_ULE:
    Libcall = RTLIB::LC2K_ULT;
    std::swap(LHS, RHS);
    Negate = true;
    break;
  case CmpInst::ICMP_UGE:
    Libcall = RTLIB::LC2K_ULT;
    Negate = true;
    break;
  default:
    llvm_unreachable("Unexpected ICmp predicate");
  }

  MachineIRBuilder &MIRBuilder = Helper.MIRBuilder;
  MachineRegisterInfo &MRI = *MIRBuilder.getMRI();
  LLT S32 = LLT::scalar(32);

  Type *S32Ty = IntegerType::get(MI.getMF()->getFunction().getContext(), 32);
  Register CallResult = MRI.createGenericVirtualRegister(S32);
  CallLowering::ArgInfo Result = {CallResult, S32Ty, 0};
  SmallVector<CallLowering::ArgInfo, 2> Args = {{LHS, S32Ty, 0},
                                                {RHS, S32Ty, 0}};

  if (Helper.createLibcall(Libcall, Result, Args, LocObserver, &MI) !=
      LegalizerHelper::Legalized)
    return false;

  Register FinalValue = CallResult;
  if (Negate) {
    auto One = MIRBuilder.buildConstant(S32, 1);
    FinalValue = MIRBuilder.buildXor(S32, CallResult, One).getReg(0);
  }

  MIRBuilder.buildTrunc(MI.getOperand(0).getReg(), FinalValue);

  MI.eraseFromParent();
  return true;
}

bool LC2KLegalizerInfo::legalizeExt(LegalizerHelper &Helper,
                                    MachineInstr &MI) const {
  MachineIRBuilder &MIRBuilder = Helper.MIRBuilder;
  MachineRegisterInfo &MRI = *MIRBuilder.getMRI();
  LLT S32 = LLT::scalar(32);
  Register Dst = MI.getOperand(0).getReg();
  Register Src = MI.getOperand(1).getReg();
  unsigned Opc = MI.getOpcode();

  // A source narrower than s32 (i.e. s1, from e.g. an i1->i64 zext/sext)
  // needs widening to s32 first: {s32, s1} is legal (handled directly by
  // instruction selection), but the merge below assumes both halves it's
  // combining are already s32.
  if (MRI.getType(Src) != S32) {
    Register Widened = MRI.createGenericVirtualRegister(S32);
    MIRBuilder.buildInstr(Opc, {Widened}, {Src});
    Src = Widened;
  }

  Register Hi;
  if (Opc == TargetOpcode::G_SEXT) {
    auto ShiftAmt = MIRBuilder.buildConstant(S32, 31);
    Hi = MIRBuilder.buildAShr(S32, Src, ShiftAmt).getReg(0);
  } else {
    // G_ZEXT / G_ANYEXT
    Hi = MIRBuilder.buildConstant(S32, 0).getReg(0);
  }

  MIRBuilder.buildMergeLikeInstr(Dst, {Src, Hi});
  MI.eraseFromParent();
  return true;
}

bool LC2KLegalizerInfo::legalizeTrunc(LegalizerHelper &Helper,
                                      MachineInstr &MI) const {
  MachineIRBuilder &MIRBuilder = Helper.MIRBuilder;
  MachineRegisterInfo &MRI = *MIRBuilder.getMRI();
  LLT S32 = LLT::scalar(32);
  Register Dst = MI.getOperand(0).getReg();
  Register Src = MI.getOperand(1).getReg();

  Register DeadHi = MRI.createGenericVirtualRegister(S32);
  MIRBuilder.buildUnmerge({Dst, DeadHi}, Src);
  MI.eraseFromParent();
  return true;
}

bool LC2KLegalizerInfo::legalizeBRJT(LegalizerHelper &Helper,
                                     MachineInstr &MI) const {
  MachineIRBuilder &MIRBuilder = Helper.MIRBuilder;
  MachineFunction &MF = *MI.getMF();
  LLT P0 = LLT::pointer(0, 32);

  assert(MF.getJumpTableInfo()->getEntryKind() ==
             MachineJumpTableInfo::EK_BlockAddress &&
         "LC2K never overrides getJumpTableEncoding, so jump tables should "
         "always use the default (plain block address) entry kind");

  Register TblReg = MI.getOperand(0).getReg();
  Register IdxReg = MI.getOperand(2).getReg();

  // See the G_BRJT legalizer-rule comment above: the index is already a
  // word offset, so this is a plain pointer add, not a scaled one.
  auto Addr = MIRBuilder.buildPtrAdd(P0, TblReg, IdxReg);

  MachineMemOperand *MMO = MF.getMachineMemOperand(
      MachinePointerInfo::getJumpTable(MF), MachineMemOperand::MOLoad, P0,
      Align(4));
  auto Target = MIRBuilder.buildLoad(P0, Addr, *MMO);

  MIRBuilder.buildBrIndirect(Target.getReg(0));

  MI.eraseFromParent();
  return true;
}

bool LC2KLegalizerInfo::legalizeFConstant(LegalizerHelper &Helper,
                                          MachineInstr &MI) const {
  MachineIRBuilder &MIRBuilder = Helper.MIRBuilder;
  Register Dst = MI.getOperand(0).getReg();
  const ConstantFP *CFP = MI.getOperand(1).getFPImm();
  APInt Bits = CFP->getValueAPF().bitcastToAPInt();
  LLT S32 = LLT::scalar(32);
  auto Lo =
      MIRBuilder.buildConstant(S32, Bits.extractBits(32, 0).getZExtValue());
  auto Hi =
      MIRBuilder.buildConstant(S32, Bits.extractBits(32, 32).getZExtValue());
  MIRBuilder.buildMergeLikeInstr(Dst, {Lo, Hi});
  MI.eraseFromParent();
  return true;
}
