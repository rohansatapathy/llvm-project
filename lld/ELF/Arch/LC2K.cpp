//===- LC2K.cpp -----------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "InputFiles.h"
#include "Symbols.h"
#include "Target.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/Support/Endian.h"

using namespace llvm;
using namespace llvm::object;
using namespace llvm::ELF;
using namespace llvm::support::endian;
using namespace lld;
using namespace lld::elf;

namespace {
class LC2K final : public TargetInfo {
public:
  LC2K(Ctx &);

  uint32_t calcEFlags() const override;

  RelExpr getRelExpr(RelType type, const Symbol &s,
                     const uint8_t *loc) const override;

  void relocate(uint8_t *loc, const Relocation &rel,
                uint64_t val) const override;
};
} // namespace

LC2K::LC2K(Ctx &ctx) : TargetInfo(ctx) {}

static uint32_t getEFlags(InputFile *f) {
  return cast<ObjFile<ELF32LE>>(f)->getObj().getHeader().e_flags;
}

static StringRef getMachName(uint32_t eflags) {
  switch (eflags & EF_LC2K_MACH) {
  case EF_LC2K_MACH_EECS470:
    return "eecs470";
  case EF_LC2K_MACH_PHOBOS:
    return "phobos";
  default:
    return "unknown";
  }
}

// The CPU variants use different instruction encodings, so all inputs must
// agree on EF_LC2K_MACH. The output gets the common value.
uint32_t LC2K::calcEFlags() const {
  if (ctx.objectFiles.empty())
    return EF_LC2K_MACH_EECS470;

  InputFile *first = ctx.objectFiles.front();
  uint32_t flags = getEFlags(first);
  for (InputFile *f : ArrayRef(ctx.objectFiles).slice(1)) {
    uint32_t objFlags = getEFlags(f);
    if ((objFlags & EF_LC2K_MACH) != (flags & EF_LC2K_MACH))
      ErrAlways(ctx) << f << ": cannot link object files with different LC2K "
                     << "CPUs: " << getMachName(objFlags) << " is incompatible "
                     << "with " << getMachName(flags) << " (" << first << ")";
  }
  return flags;
}

RelExpr LC2K::getRelExpr(RelType type, const Symbol &s,
                         const uint8_t *loc) const {
  switch (type) {
  case R_LC2K_NONE:
    return R_NONE;
  case R_LC2K_20:
  case R_LC2K_21:
  case R_LC2K_32:
    return R_ABS;
  case R_LC2K_20_PCPLUS1REL:
  case R_LC2K_21_PCPLUS1REL:
    return R_PC;
  default:
    Err(ctx) << getErrorLoc(ctx, loc) << "unknown relocation (" << type.v
             << ") against symbol " << &s;
    return R_NONE;
  }
}

// Writes a signed word offset into the low \p bits bits of the instruction at
// \p loc, preserving the opcode and register fields above it.
static void writeImm(Ctx &ctx, uint8_t *loc, const Relocation &rel,
                     int64_t words, unsigned bits) {
  checkInt(ctx, loc, words, bits, rel);
  uint32_t mask = (1u << bits) - 1;
  write32le(loc,
            (read32le(loc) & ~mask) | (static_cast<uint32_t>(words) & mask));
}

void LC2K::relocate(uint8_t *loc, const Relocation &rel, uint64_t val) const {
  // LC2K is word addressed: byte addresses are converted to word addresses.
  int64_t words = static_cast<int64_t>(val) / 4;

  switch (rel.type) {
  case R_LC2K_NONE:
    break;
  case R_LC2K_32:
    write32le(loc, static_cast<uint32_t>(words));
    break;
  case R_LC2K_20:
    writeImm(ctx, loc, rel, words, 20);
    break;
  case R_LC2K_21:
    writeImm(ctx, loc, rel, words, 21);
    break;
  // BEQ's offset is relative to PC + 1.
  case R_LC2K_20_PCPLUS1REL:
    writeImm(ctx, loc, rel, words - 1, 20);
    break;
  case R_LC2K_21_PCPLUS1REL:
    writeImm(ctx, loc, rel, words - 1, 21);
    break;
  default:
    llvm_unreachable("unknown relocation");
  }
}

void elf::setLC2KTargetInfo(Ctx &ctx) { ctx.target.reset(new LC2K(ctx)); }
