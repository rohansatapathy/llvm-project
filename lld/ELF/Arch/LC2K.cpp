//===- LC2K.cpp -----------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "InputFiles.h"
#include "OutputSections.h"
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

  bool relaxOnce(int pass) const override;
  void finalizeRelax(int passes) const override;
};

} // namespace

// Internal-only relocation type for the lo-ADDI that survives shrinking a
// PSEUDO_LA wide-address sequence back down to a single instruction (see
// relax() below): unlike a real R_LC2K_LO20, its value is the *whole*
// absolute word address (not just the low 20 bits of a hi/lo split, since
// there's no longer a paired hi-ADDI contributing the rest), and applying
// it also has to rewrite the instruction's own base-register field from
// the (now-unused) hi accumulator register to R0 -- an ordinary
// relocation only ever patches the immediate field, never a register
// field, so this needs its own code path in relocate() below. Never
// written to an object file (chosen well outside the real ELF_RELOC
// range), exactly like RISC-V's INTERNAL_R_RISCV_X0REL_I/_S. A plain
// #define (not a typed constant) because RelType's switch case labels
// need a literal constant-expression.
#define INTERNAL_R_LC2K_X0REL 256

LC2K::LC2K(Ctx &ctx) : TargetInfo(ctx) {}

RelExpr LC2K::getRelExpr(RelType type, const Symbol &s,
                         const uint8_t *loc) const {
  switch (type) {
  case ELF::R_LC2K_NONE:
    return RelExpr::R_NONE;
  case ELF::R_LC2K_20:
  case ELF::R_LC2K_32:
  case ELF::R_LC2K_HI12:
  case ELF::R_LC2K_LO20:
    return RelExpr::R_ABS;
  case ELF::R_LC2K_20_PCPLUS1REL:
    return RelExpr::R_PC;
  default:
    llvm_unreachable("Invalid LC2K relocation type");
  }
}

// Same rounding-compensated hi12/lo20 split as
// LC2KAsmBackend::splitWideAddress (llvm/lib/Target/LC2K/MCTargetDesc/
// LC2KAsmBackend.cpp) -- necessarily duplicated rather than shared, since
// lld and LLVM's MC layer are separate libraries/binaries.
static std::pair<uint32_t, int32_t> splitWideAddress(uint32_t wordAddr) {
  int32_t lo = SignExtend32<20>(wordAddr & 0xFFFFF);
  uint32_t hi = (wordAddr - static_cast<uint32_t>(lo)) >> 20;
  return {hi, lo};
}

void LC2K::relocate(uint8_t *loc, const Relocation &rel, uint64_t val) const {
  int64_t sval = static_cast<int64_t>(val);
  uint32_t writeval = 0;

  switch (rel.type) {
  case R_LC2K_32:
    writeval = static_cast<uint32_t>(sval / 4);
    break;
  case R_LC2K_20:
    checkInt(ctx, loc, sval / 4, 20, rel);
    writeval = static_cast<uint32_t>((read32le(loc) & ~0xFFFFF) |
                                     ((sval / 4) & 0xFFFFF));
    break;
  case R_LC2K_20_PCPLUS1REL:
    checkInt(ctx, loc, sval / 4 - 1, 20, rel);
    writeval = static_cast<uint32_t>((read32le(loc) & ~0xFFFFF) |
                                     (((sval / 4) - 1) & 0xFFFFF));
    break;
  case R_LC2K_HI12: {
    auto [hi, lo] = splitWideAddress(static_cast<uint32_t>(sval / 4));
    (void)lo;
    writeval = static_cast<uint32_t>((read32le(loc) & ~0xFFFFF) | hi);
    break;
  }
  case R_LC2K_LO20: {
    auto [hi, lo] = splitWideAddress(static_cast<uint32_t>(sval / 4));
    (void)hi;
    writeval = static_cast<uint32_t>((read32le(loc) & ~0xFFFFF) |
                                     (static_cast<uint32_t>(lo) & 0xFFFFF));
    break;
  }
  case INTERNAL_R_LC2K_X0REL:
    // The shrunk lo-ADDI: full absolute word address (not a lo20 split --
    // there's no paired hi-ADDI anymore), and the base-register field
    // (bits 27-24, see LC2KInstITypeWriteReg in LC2KInstrFormats.td)
    // rewritten from the hi accumulator register to R0 (encoding 0).
    checkInt(ctx, loc, sval / 4, 20, rel);
    writeval = static_cast<uint32_t>(
        (read32le(loc) & ~0xFFFFF & ~(0xFu << 24)) | ((sval / 4) & 0xFFFFF));
    break;
  case R_LC2K_NONE:
    writeval = read32le(loc);
    break;
  default:
    llvm_unreachable("Invalid LC2K relocation type");
  }

  write32le(loc, writeval);
}

// Shrinks a PSEUDO_LA-expanded wide-address sequence (hi-ADDI + 20 doubling
// ADDs + lo-ADDI, see LC2KMCCodeEmitter::encodePseudoLA) back down to a
// single ADDI once the linker can see the symbol's final address fits.
// Unlike RISC-V's relaxHi20Lo12, no marker relocation is needed to pair
// the hi/lo relocations: PSEUDO_LA's expansion is always the same fixed
// 88-byte shape, so an R_LC2K_HI12 is always immediately followed (84
// bytes later) by the R_LC2K_LO20 for the same symbol.
static bool relax(InputSection &sec) {
  const MutableArrayRef<Relocation> relocs = sec.relocs();
  RelaxAux &aux = *sec.relaxAux;
  bool changed = false;
  ArrayRef<SymbolAnchor> sa = ArrayRef(aux.anchors);
  uint64_t delta = 0;

  std::fill_n(aux.relocTypes.get(), relocs.size(), R_LC2K_NONE);
  for (auto [i, r] : llvm::enumerate(relocs)) {
    uint32_t &cur = aux.relocDeltas[i];
    uint32_t remove = 0;
    bool fits = isInt<20>(r.sym->getVA(sec.file->ctx, r.addend) / 4);
    if (r.type == R_LC2K_HI12 && fits) {
      // The lo-ADDI 84 bytes later absorbs the whole address; delete the
      // hi-ADDI and all 20 doubling ADDs in between.
      remove = 84;
    } else if (r.type == R_LC2K_LO20 && fits) {
      aux.relocTypes[i] = INTERNAL_R_LC2K_X0REL;
    }

    // For all anchors whose offsets are <= r.offset, they're preceded by
    // the previous relocation's delta -- decrease their st_value/st_size.
    for (; sa.size() && sa[0].offset <= r.offset; sa = sa.slice(1)) {
      if (sa[0].end)
        sa[0].d->size = sa[0].offset - delta - sa[0].d->value;
      else
        sa[0].d->value = sa[0].offset - delta;
    }
    delta += remove;
    if (delta != cur) {
      cur = delta;
      changed = true;
    }
  }

  for (const SymbolAnchor &a : sa) {
    if (a.end)
      a.d->size = a.offset - delta - a.d->value;
    else
      a.d->value = a.offset - delta;
  }
  sec.bytesDropped = delta;
  return changed;
}

// Shrinking one wide-address sequence changes later addresses in this
// (executable) section, which can bring a different, farther-away symbol
// within range on a later pass -- so, like RISC-V, this iterates to a
// fixed point rather than relying on a single pass.
bool LC2K::relaxOnce(int pass) const {
  if (pass == 0)
    initSymbolAnchors(ctx);

  SmallVector<InputSection *, 0> storage;
  bool changed = false;
  for (OutputSection *osec : ctx.outputSections) {
    if (!(osec->flags & SHF_EXECINSTR))
      continue;
    for (InputSection *sec : getInputSections(*osec, storage))
      if (sec->relaxAux)
        changed |= relax(*sec);
  }
  return changed;
}

void LC2K::finalizeRelax(int passes) const {
  SmallVector<InputSection *, 0> storage;
  for (OutputSection *osec : ctx.outputSections) {
    if (!(osec->flags & SHF_EXECINSTR))
      continue;
    for (InputSection *sec : getInputSections(*osec, storage)) {
      if (!sec->relaxAux || !sec->relaxAux->relocDeltas)
        continue;
      RelaxAux &aux = *sec->relaxAux;

      MutableArrayRef<Relocation> rels = sec->relocs();
      ArrayRef<uint8_t> old = sec->content();
      size_t newSize = old.size() - aux.relocDeltas[rels.size() - 1];
      uint8_t *p = ctx.bAlloc.Allocate<uint8_t>(newSize);
      uint64_t offset = 0;
      int64_t delta = 0;
      sec->content_ = p;
      sec->size = newSize;
      sec->bytesDropped = 0;

      for (size_t i = 0, e = rels.size(); i != e; ++i) {
        uint32_t remove = aux.relocDeltas[i] - delta;
        delta = aux.relocDeltas[i];
        if (remove == 0 && aux.relocTypes[i] == R_LC2K_NONE)
          continue;

        const Relocation &r = rels[i];
        uint64_t size = r.offset - offset;
        memcpy(p, old.data() + offset, size);
        p += size;
        offset = r.offset + remove;
      }
      memcpy(p, old.data() + offset, old.size() - offset);

      // Subtract the previous relocDeltas value from the relocation
      // offset, and apply any retyping relax() recorded.
      delta = 0;
      for (size_t i = 0, e = rels.size(); i != e;) {
        uint64_t cur = rels[i].offset;
        do {
          rels[i].offset -= delta;
          if (aux.relocTypes[i] != R_LC2K_NONE)
            rels[i].type = aux.relocTypes[i];
        } while (++i != e && rels[i].offset == cur);
        delta = aux.relocDeltas[i - 1];
      }
    }
  }
}

void elf::setLC2KTargetInfo(Ctx &ctx) { ctx.target.reset(new LC2K(ctx)); }
