//===-- LC2KTargetStreamer.h - LC2K Target Streamer ------------*- C++ -*--===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LC2K_MCTARGETDESC_LC2KTARGETSTREAMER_H
#define LLVM_LIB_TARGET_LC2K_MCTARGETDESC_LC2KTARGETSTREAMER_H

#include "llvm/MC/MCCodeEmitter.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/FormattedStream.h"

namespace llvm {

class LC2KAsmStreamer : public MCStreamer {
private:
  std::unique_ptr<formatted_raw_ostream> OSOwner;
  formatted_raw_ostream &OS;
  const MCAsmInfo *MAI;
  std::unique_ptr<MCInstPrinter> InstPrinter;

  bool IsVerboseAsm = false;
  SmallString<128> ExplicitCommentToEmit;
  SmallString<128> CommentToEmit;
  raw_svector_ostream CommentStream;

  enum Section { Text, Data };
  Section CurrentSection = Text;

  // For buffering inline labels.
  MCSymbol *CurrentLabel = nullptr;

  void emitPendingLabel();

  void emitCommentsAndEOL();

  // Copied from MCAsmStreamer.cpp
  inline void emitEOL() {
    // Dump Explicit Comments here.
    emitExplicitComments();
    // If we don't have any comments, just emit a \n.
    if (!IsVerboseAsm) {
      OS << '\n';
      return;
    }
    emitCommentsAndEOL();
  }

public:
  LC2KAsmStreamer(MCContext &Context, std::unique_ptr<formatted_raw_ostream> OS,
                  std::unique_ptr<MCInstPrinter> IP,
                  std::unique_ptr<MCCodeEmitter> CE,
                  std::unique_ptr<MCAsmBackend> TAB);

  bool emitSymbolAttribute(MCSymbol *Symbol, MCSymbolAttr Attribute) override;

  void emitCommonSymbol(MCSymbol *Symbol, uint64_t Size,
                        Align ByteAlignment) override {}

  void emitFill(const MCExpr &NumBytes, uint64_t FillValue,
                SMLoc Loc = SMLoc()) override {
    llvm_unreachable("Unsupported override for emitFill");
  }

  void emitFill(const MCExpr &NumValues, int64_t Size, int64_t Expr,
                SMLoc Loc = SMLoc()) override;

  void emitValueImpl(const MCExpr *Value, unsigned Size,
                     SMLoc Loc = SMLoc()) override;

  void emitExplicitComments() override;

  void emitInstruction(const MCInst &Inst, const MCSubtargetInfo &STI) override;

  void emitLabel(MCSymbol *Symbol, SMLoc Loc = SMLoc()) override;

  void finishImpl() override;
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_LC2K_MCTARGETDESC_LC2KTARGETSTREAMER_H
