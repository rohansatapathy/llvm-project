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

  RelExpr getRelExpr(RelType type, const Symbol &s,
                     const uint8_t *loc) const override;

  void relocate(uint8_t *loc, const Relocation &rel,
                uint64_t val) const override;
};

} // namespace

LC2K::LC2K(Ctx &ctx) : TargetInfo(ctx) {}

RelExpr LC2K::getRelExpr(RelType type, const Symbol &s,
                         const uint8_t *loc) const {
  switch (type) {
  case ELF::R_LC2K_NONE:
    return RelExpr::R_NONE;
  case ELF::R_LC2K_20:
  case ELF::R_LC2K_32:
    return RelExpr::R_ABS;
  case ELF::R_LC2K_20_PCPLUS1REL:
    return RelExpr::R_PC;
  default:
    llvm_unreachable("Invalid LC2K relocation type");
  }
}

void LC2K::relocate(uint8_t *loc, const Relocation &rel, uint64_t val) const {
  int64_t sval = static_cast<int64_t>(val);
  uint32_t writeval = 0;

  switch (rel.type) {
  case R_LC2K_32:
    writeval = static_cast<uint32_t>(sval / 4);
    break;
  case R_LC2K_20:
    // OR the 20-bit word address into the instruction, same bit-packing as
    // applyFixup
    writeval = static_cast<uint32_t>((read32le(loc) & ~0xFFFFF) |
                                     ((sval / 4) & 0xFFFFF));
    break;
  case R_LC2K_20_PCPLUS1REL:
    // R_PC means LLD gives val = S - P + A; convert to LC2K's (target - (PC+1))
    // / 4 which is (val / 4) - 1, identical to adjustFixupValue's pcplus1rel
    // case
    writeval = static_cast<uint32_t>((read32le(loc) & ~0xFFFFF) |
                                     (((sval / 4) - 1) & 0xFFFFF));
    break;
  case R_LC2K_NONE:
    writeval = read32le(loc);
    break;
  default:
    llvm_unreachable("Invalid LC2K relocation type");
  }

  write32le(loc, writeval);
}

void elf::setLC2KTargetInfo(Ctx &ctx) { ctx.target.reset(new LC2K(ctx)); }
