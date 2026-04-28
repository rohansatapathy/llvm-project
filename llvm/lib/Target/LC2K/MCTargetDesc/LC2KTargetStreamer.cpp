//===-- LC2KTargetStreamer.cpp - LC2K Target Streamer Methods -------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file provides LC2K specific target streamer methods.
//
//===----------------------------------------------------------------------===//

#include "LC2KTargetStreamer.h"

#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInstPrinter.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/FormattedStream.h"
#include "llvm/Support/MathExtras.h"

using namespace llvm;

LC2KAsmStreamer::LC2KAsmStreamer(MCContext &Context,
                                 std::unique_ptr<formatted_raw_ostream> OS,
                                 std::unique_ptr<MCInstPrinter> Printer,
                                 std::unique_ptr<MCCodeEmitter> Emitter,
                                 std::unique_ptr<MCAsmBackend> Backend)
    : MCStreamer(Context), OSOwner(std::move(OS)), OS(*OSOwner),
      MAI(Context.getAsmInfo()), InstPrinter(std::move(Printer)),
      CommentStream(CommentToEmit) {
  auto *TO = Context.getTargetOptions();
  if (!TO)
    return;
  IsVerboseAsm = TO->AsmVerbose;
  if (IsVerboseAsm)
    InstPrinter->setCommentStream(CommentStream);
  // TODO: Use CodeEmitter to add instruction encoding comments.
}

bool LC2KAsmStreamer::emitSymbolAttribute(MCSymbol *Symbol,
                                          MCSymbolAttr Attribute) {
  if (Attribute != MCSA_Global)
    return false;

  OS << MAI->getGlobalDirective();
  Symbol->print(OS, MAI);
  emitEOL();

  return true;
}

void LC2KAsmStreamer::emitFill(const MCExpr &NumValues, int64_t Size,
                               int64_t Expr, SMLoc Loc) {
  int64_t NumValuesRes;

  if (!NumValues.evaluateAsAbsolute(NumValuesRes)) {
    llvm_unreachable("LC2K only supports constant-multiple fills");
  }

  if (NumValuesRes < 0) {
    llvm_unreachable("Negative fill count");
  }

  if (Size != 4) {
    llvm_unreachable("LC2K only supports word-size fills (Size == 4)");
  }

  if (!isInt<32>(Expr)) {
    llvm_unreachable("LC2K fill value must fit within int32_t");
  }

  CurrentSection = Section::Data;

  for (int64_t i = 0; i < NumValuesRes; i++) {
    emitPendingLabel();
    OS << "\t.fill\t" << Expr;
    emitEOL();
  }
}

void LC2KAsmStreamer::emitValueImpl(const MCExpr *Value, unsigned Size,
                                    SMLoc Loc) {
  if (Size != 4) {
    llvm_unreachable("Invalid size for value");
  }

  if (!Value) {
    llvm_unreachable("Expected value (found none)");
  }

  if (!(Value->getKind() == MCExpr::ExprKind::Constant ||
        Value->getKind() == MCExpr::ExprKind::SymbolRef)) {
    llvm_unreachable("Invalid value kind for LC2K");
  }

  CurrentSection = Section::Data;

  emitPendingLabel();
  OS << "\t.fill\t";
  MAI->printExpr(OS, *Value);
  emitEOL();
}

// Copied from MCAsmStreamer.cpp
void LC2KAsmStreamer::emitExplicitComments() {
  StringRef Comments = ExplicitCommentToEmit;
  if (!Comments.empty())
    OS << Comments;
  ExplicitCommentToEmit.clear();
}

// Copied from MCAsmStreamer.cpp
void LC2KAsmStreamer::emitCommentsAndEOL() {
  if (CommentToEmit.empty() && CommentStream.GetNumBytesInBuffer() == 0) {
    OS << '\n';
    return;
  }

  StringRef Comments = CommentToEmit;

  assert(Comments.back() == '\n' && "Comment array not newline terminated");
  do {
    // Emit a line of comments.
    OS.PadToColumn(MAI->getCommentColumn());
    size_t Position = Comments.find('\n');
    OS << MAI->getCommentString() << ' ' << Comments.substr(0, Position)
       << '\n';

    Comments = Comments.substr(Position + 1);
  } while (!Comments.empty());

  CommentToEmit.clear();
}

void LC2KAsmStreamer::emitInstruction(const MCInst &Inst,
                                      const MCSubtargetInfo &STI) {
  if (CurrentSection != Section::Text)
    report_fatal_error("Instructions must come before .fills");

  emitPendingLabel();
  InstPrinter->printInst(&Inst, 0, "", STI, OS);
  emitEOL();
}

void LC2KAsmStreamer::emitLabel(MCSymbol *Symbol, SMLoc Loc) {
  if (CurrentLabel != nullptr)
    report_fatal_error("Cannot emit two labels in a row");

  MCStreamer::emitLabel(Symbol, Loc);
  CurrentLabel = Symbol;
}

void LC2KAsmStreamer::emitPendingLabel() {
  if (CurrentLabel == nullptr)
    return;

  CurrentLabel->print(OS, MAI);
  OS << MAI->getLabelSuffix(); // suffix set to '\t' in LC2KMCAsmInfo

  CurrentLabel = nullptr;
}

void LC2KAsmStreamer::finishImpl() {
  if (CurrentLabel != nullptr)
    report_fatal_error("Dangling label");
}
