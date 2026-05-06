//===-- LC2KAsmParser.cpp - Parse LC2K assembly to MCInst instructions ----===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/LC2KMCTargetDesc.h"
#include "TargetInfo/LC2KTargetInfo.h"

#include "llvm/ADT/StringSwitch.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCAsmMacro.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCDirectives.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCParser/MCParsedAsmOperand.h"
#include "llvm/MC/MCParser/MCTargetAsmParser.h"
#include "llvm/MC/MCRegister.h"
#include "llvm/MC/MCSectionELF.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/Compiler.h"

#include <memory>

using namespace llvm;

namespace {

class LC2KAsmParser : public MCTargetAsmParser {
  enum Section { Text, Data };
  Section CurrentSection = Text;

  bool parseRegister(MCRegister &Reg, SMLoc &StartLoc, SMLoc &EndLoc) override;

  ParseStatus tryParseRegister(MCRegister &Reg, SMLoc &StartLoc,
                               SMLoc &EndLoc) override;

  bool parseInstruction(ParseInstructionInfo &Info, StringRef Name,
                        SMLoc NameLoc, OperandVector &Operands) override;

  bool matchAndEmitInstruction(SMLoc IDLoc, unsigned &Opcode,
                               OperandVector &Operands, MCStreamer &Out,
                               uint64_t &ErrorInfo,
                               bool MatchingInlineAsm) override;

  ParseStatus parseDirective(AsmToken DirectiveID) override;

  // LC2K doesn't currently support inline assembly, so this function is a
  // stub.
  //
  // TODO: Implement this if/when inline asm is supported.
  void convertToMapAndConstraints(unsigned Kind,
                                  const OperandVector &Operands) override {}

  // Handle labels in parseInstruction
  bool isLabel(AsmToken &Token) override { return false; };

public:
  LC2KAsmParser(const MCSubtargetInfo &STI, MCAsmParser &Parser,
                const MCInstrInfo &MII, const MCTargetOptions &Options)
      : MCTargetAsmParser(Options, STI, MII), Parser(Parser),
        Lexer(Parser.getLexer()) {}

private:
  MCAsmParser &Parser;
  AsmLexer &Lexer;
};

class LC2KOperand : public MCParsedAsmOperand {
  friend class std::unique_ptr<LC2KOperand>;

  enum class KindTy {
    Token,
    Register,
    Offset,
  } Kind;

  SMLoc StartLoc, EndLoc;

  union {
    StringRef Token;
    MCRegister Register;
    const MCExpr *Offset;
  };

public:
  // FIXME: Is leaving Token/Register/Offset uninitialized a footgun?
  LC2KOperand(KindTy Kind, SMLoc StartLoc, SMLoc EndLoc)
      : Kind(Kind), StartLoc(StartLoc), EndLoc(EndLoc) {}

  static std::unique_ptr<LC2KOperand> createToken(StringRef Tok, SMLoc Loc) {
    auto Op = std::make_unique<LC2KOperand>(KindTy::Token, Loc, Loc);
    Op->Token = Tok;
    return Op;
  }

  static std::unique_ptr<LC2KOperand> createReg(MCRegister Reg, SMLoc StartLoc,
                                                SMLoc EndLoc) {
    auto Op = std::make_unique<LC2KOperand>(KindTy::Register, StartLoc, EndLoc);
    Op->Register = Reg;
    return Op;
  }

  static std::unique_ptr<LC2KOperand>
  createOffset(const MCExpr *Expr, SMLoc StartLoc, SMLoc EndLoc) {
    auto Op = std::make_unique<LC2KOperand>(KindTy::Offset, StartLoc, EndLoc);
    Op->Offset = Expr;
    return Op;
  }

  // getStartLoc - Gets location of the first token of this operand
  SMLoc getStartLoc() const override { return StartLoc; }

  // getEndLoc - Gets location of the last token of this operand
  SMLoc getEndLoc() const override { return EndLoc; }

  /// isToken - Is this a token operand?
  bool isToken() const override { return Kind == KindTy::Token; }

  /// isImm - Is this an immediate operand?
  bool isImm() const override { return Kind == KindTy::Offset; }

  /// isOffset - equivalent to `isImm`
  bool isOffset() const { return isImm(); }

  /// isReg - Is this a register operand?
  bool isReg() const override { return Kind == KindTy::Register; }

  /// isMem - Is this a memory operand?
  bool isMem() const override { return false; }

  MCRegister getReg() const override {
    assert(isReg() && "Invalid type");
    return Register;
  }

  StringRef getToken() const {
    assert(isToken() && "Invalid type");
    return Token;
  };

  const MCExpr *getOffset() const {
    assert(isOffset() && "Invalid type");
    return Offset;
  };

  // From LanaiAsmParser.cpp
  void addExpr(MCInst &Inst, const MCExpr *Expr) const {
    // Add as immediates where possible. Null MCExpr = 0
    if (Expr == nullptr)
      Inst.addOperand(MCOperand::createImm(0));
    else if (const MCConstantExpr *ConstExpr = dyn_cast<MCConstantExpr>(Expr))
      Inst.addOperand(
          MCOperand::createImm(static_cast<int32_t>(ConstExpr->getValue())));
    else
      Inst.addOperand(MCOperand::createExpr(Expr));
  }

  void addRegOperands(MCInst &Inst, unsigned N) const {
    assert(N == 1 && "Invalid number of operands!");
    Inst.addOperand(MCOperand::createReg(getReg()));
  }

  void addOffsetOperands(MCInst &Inst, unsigned N) const {
    assert(N == 1 && "Invalid number of operands!");
    addExpr(Inst, getOffset());
  }

  void print(raw_ostream &OS, const MCAsmInfo &MAI) const override {
    switch (Kind) {
    case KindTy::Token:
      OS << "Token: " << getToken();
      break;
    case KindTy::Register:
      OS << "Reg: " << getReg().id() - LC2K::R0;
      break;
    case KindTy::Offset:
      OS << "Offset: ";
      if (const auto *CE = dyn_cast<MCConstantExpr>(getOffset()))
        OS << CE->getValue();
      else if (const auto *SE = dyn_cast<MCSymbolRefExpr>(getOffset()))
        OS << SE->getSymbol().getName();
      else
        OS << "<expr>";
      break;
    }
  }
};

} // end anonymous namespace

ParseStatus LC2KAsmParser::tryParseRegister(MCRegister &Reg, SMLoc &StartLoc,
                                            SMLoc &EndLoc) {
  const AsmToken &Tok = Parser.getTok();
  StartLoc = Tok.getLoc();
  EndLoc = Tok.getEndLoc();

  if (Tok.isNot(AsmToken::Integer)) {
    return ParseStatus::NoMatch;
  }

  int64_t RegNum = Tok.getIntVal();

  if (!(0 <= RegNum && RegNum <= 15)) {
    return ParseStatus::NoMatch;
  }

  Reg = MCRegister(LC2K::R0 + RegNum); // enum values are offset
  Parser.Lex();

  return ParseStatus::Success;
}

bool LC2KAsmParser::parseRegister(MCRegister &Reg, SMLoc &StartLoc,
                                  SMLoc &EndLoc) {
  if (!tryParseRegister(Reg, StartLoc, EndLoc).isSuccess()) {
    return Error(StartLoc, "expected register (0-15)");
  }
  return false;
}

// Parses an optional minus sign followed by an integer token. Returns the
// signed value and advances the lexer, or returns nullopt on mismatch without
// consuming anything.
static std::optional<int64_t> parseSignedInteger(AsmLexer &Lexer) {
  bool Negative = Lexer.is(AsmToken::Minus);
  if (Negative)
    Lexer.Lex();

  if (Lexer.isNot(AsmToken::Integer)) {
    if (Negative)
      Lexer.UnLex(AsmToken(AsmToken::Minus, "-"));
    return std::nullopt;
  }

  int64_t Value = Lexer.getTok().getIntVal();
  Lexer.Lex();
  return Negative ? -Value : Value;
}

static std::optional<unsigned> mnemonicToOpcode(StringRef Name) {
  return StringSwitch<std::optional<unsigned>>(Name)
      .Case("add", LC2K::ADD)
      .Case("nor", LC2K::NOR)
      .Case("lw", LC2K::LW)
      .Case("sw", LC2K::SW)
      .Case("beq", LC2K::BEQ)
      .Case("jalr", LC2K::JALR)
      .Case("halt", LC2K::HALT)
      .Case("noop", LC2K::NOOP)
      .Case("addi", LC2K::ADDI)
      .Case("nand", LC2K::NAND)
      .Case("blt", LC2K::BLT)
      .Case("bltu", LC2K::BLTU)
      .Case("lsr", LC2K::LSR)
      .Case("asr", LC2K::ASR)
      .Default(std::nullopt);
}

bool LC2KAsmParser::parseInstruction(ParseInstructionInfo &Info, StringRef Name,
                                     SMLoc NameLoc, OperandVector &Operands) {
  // Check if the name field is an opcode.
  //
  // NOTE: This diverges from the original LC2K assembly spec since
  // *technically* the original spec allows labels to have opcodes as names.
  // This parser disallows that condition because (1) handling that case
  // is AFAIK impossible without writing a new AsmParser subclass (e.g.
  // HLASMAsmParser) and (2) having a label be the name of an opcode is
  // silly anyways.
  std::optional<unsigned> MaybeOpcode = mnemonicToOpcode(Name);

  if (!MaybeOpcode.has_value()) {
    // The "Name" field is actually a label, emit the label first, then
    // get the opcode.
    StringRef OriginalName(NameLoc.getPointer(), Name.size());
    MCSymbol *Sym = getContext().getOrCreateSymbol(OriginalName);

    if (Sym->isDefined())
      return Error(NameLoc, "label '" + Name + "' already defined");

    // Now, get the actual opcode from the lexer.
    AsmToken OpcodeToken = Lexer.getTok();

    if (OpcodeToken.isNot(AsmToken::Identifier)) {
      std::string ErrorMsgStart = "expected opcode after label, found ";
      std::string ErrorMsg;
      if (OpcodeToken.is(AsmToken::EndOfStatement) ||
          OpcodeToken.is(AsmToken::Eof)) {
        ErrorMsg = ErrorMsgStart + "nothing";
      } else {
        ErrorMsg = (ErrorMsgStart + "'" + OpcodeToken.getString() + "'").str();
      }

      return Error(OpcodeToken.getLoc(), ErrorMsg);
    }

    MaybeOpcode = mnemonicToOpcode(OpcodeToken.getIdentifier());

    if (!MaybeOpcode.has_value()) {
      if (OpcodeToken.getIdentifier() == ".fill") {
        Lexer.Lex();

        // Switch to .data before emitting the label so the symbol is placed
        // in the correct section.
        if (CurrentSection != Section::Data) {
          MCSection *DataSection = getContext().getELFSection(
              ".data", ELF::SHT_PROGBITS, ELF::SHF_ALLOC | ELF::SHF_WRITE);
          getStreamer().switchSection(DataSection);
          CurrentSection = Section::Data;
        }

        getStreamer().emitLabel(Sym, NameLoc);

        if (parseDirective(OpcodeToken).isFailure())
          return true;

        Operands.push_back(
            LC2KOperand::createToken(".fill", OpcodeToken.getLoc()));

        return false;
      }

      return Error(OpcodeToken.getLoc(),
                   "expected opcode after label, found '" +
                       OpcodeToken.getIdentifier() + "'");
    }

    if (CurrentSection != Section::Text) {
      return Error(OpcodeToken.getLoc(), "found instruction after .fill");
    }

    // Emit label after checking for section error to ensure no "double
    // label" error occurs when parser recovers from error.
    getStreamer().emitLabel(Sym, NameLoc);

    // Add opcode to operand list
    Operands.push_back(LC2KOperand::createToken(OpcodeToken.getIdentifier(),
                                                OpcodeToken.getLoc()));
    Lexer.Lex();
  } else {
    if (CurrentSection != Section::Text) {
      return Error(NameLoc, "found instruction after .fill");
    }

    // Add opcode to operand list
    Operands.push_back(LC2KOperand::createToken(Name, NameLoc));
  }

  unsigned Opcode = MaybeOpcode.value();

  switch (Opcode) {
  case LC2K::ADD:
  case LC2K::NOR:
  case LC2K::NAND: {
    // R-type instructions have three register operands

    MCRegister RegA, RegB, DestReg;
    SMLoc RegAStartLoc, RegAEndLoc, RegBStartLoc, RegBEndLoc, DestRegStartLoc,
        DestRegEndLoc;

    bool Status = parseRegister(RegA, RegAStartLoc, RegAEndLoc);
    if (Status)
      return Status;

    Status = parseRegister(RegB, RegBStartLoc, RegBEndLoc);
    if (Status)
      return Status;

    Status = parseRegister(DestReg, DestRegStartLoc, DestRegEndLoc);
    if (Status)
      return Status;

    // Tablegen'erated InstPrinter requires operands to be in the same
    // order as the outs and ins dag in LC2KInstrFormats.td.
    Operands.push_back(
        LC2KOperand::createReg(DestReg, DestRegStartLoc, DestRegEndLoc));
    Operands.push_back(LC2KOperand::createReg(RegA, RegAStartLoc, RegAEndLoc));
    Operands.push_back(LC2KOperand::createReg(RegB, RegBStartLoc, RegBEndLoc));

    break;
  }
  case LC2K::LW:
  case LC2K::SW:
  case LC2K::BEQ:
  case LC2K::BLT:
  case LC2K::BLTU:
  case LC2K::ADDI: {
    // I-type instructions have two register operands and one either integer
    // or label operand for offset field
    MCRegister RegA, RegB;
    SMLoc RegAStartLoc, RegAEndLoc, RegBStartLoc, RegBEndLoc;

    bool Status = parseRegister(RegA, RegAStartLoc, RegAEndLoc);
    if (Status)
      return Status;

    Status = parseRegister(RegB, RegBStartLoc, RegBEndLoc);
    if (Status)
      return Status;

    // Tablegen'erated InstPrinter requires operands to be in the same
    // order as the outs and ins dag in LC2KInstrFormats.td.
    Operands.push_back(LC2KOperand::createReg(RegB, RegBStartLoc, RegBEndLoc));
    Operands.push_back(LC2KOperand::createReg(RegA, RegAStartLoc, RegAEndLoc));

    // Parse offset operand
    SMLoc OffsetLoc = Lexer.getLoc();
    const MCExpr *OffsetExpr;

    if (auto MaybeInt = parseSignedInteger(Lexer)) {
      int64_t OffsetValue = *MaybeInt;
      if (!isInt<20>(OffsetValue))
        return Error(OffsetLoc, "value '" + std::to_string(OffsetValue) +
                                    "' too large for 20-bit offset field");
      OffsetExpr = MCConstantExpr::create(OffsetValue, getContext());
    } else if (Lexer.is(AsmToken::Identifier)) {
      AsmToken OffsetToken = Lexer.getTok();
      MCSymbol *Sym =
          getContext().getOrCreateSymbol(OffsetToken.getIdentifier());
      OffsetExpr = MCSymbolRefExpr::create(Sym, getContext());
      Lexer.Lex();
    } else {
      return Error(OffsetLoc, "expected integer or label for I-type offset");
    }

    Operands.push_back(
        LC2KOperand::createOffset(OffsetExpr, OffsetLoc, Lexer.getLoc()));

    break;
  }
  case LC2K::JALR:
  case LC2K::LSR:
  case LC2K::ASR: {
    // J-type instructions have two register operands
    MCRegister RegA, RegB;
    SMLoc RegAStartLoc, RegAEndLoc, RegBStartLoc, RegBEndLoc;

    bool Status = parseRegister(RegA, RegAStartLoc, RegAEndLoc);
    if (Status)
      return Status;

    Status = parseRegister(RegB, RegBStartLoc, RegBEndLoc);
    if (Status)
      return Status;

    // Tablegen'erated InstPrinter requires operands to be in the same
    // order as the outs and ins dag in LC2KInstrFormats.td.
    Operands.push_back(LC2KOperand::createReg(RegB, RegBStartLoc, RegBEndLoc));
    Operands.push_back(LC2KOperand::createReg(RegA, RegAStartLoc, RegAEndLoc));

    break;
  }
  case LC2K::NOOP:
  case LC2K::HALT:
    // O-type instructions don't have any operands
    break;
  default:
    llvm_unreachable("invalid LC2K instruction");
  }

  // In LC2K, anything after the end of the instruction is considered a
  // comment and can be ignored.
  Parser.eatToEndOfStatement();

  return false;
}

// All the real error handling happens in parseInstruction, so this method
// simply passes the instruction onto the MCStreamer.
bool LC2KAsmParser::matchAndEmitInstruction(SMLoc IDLoc, unsigned &Opcode,
                                            OperandVector &Operands,
                                            MCStreamer &Out,
                                            uint64_t &ErrorInfo,
                                            bool MatchingInlineAsm) {
  assert(!MatchingInlineAsm && "LC2K doesn't support inline asm");

  // Directives handled in parseInstruction leave a sentinel token — nothing
  // left to emit here.
  auto &OpcodeOperand = static_cast<LC2KOperand &>(*Operands[0]);
  if (OpcodeOperand.isToken() && OpcodeOperand.getToken().starts_with("."))
    return false;
  Opcode = mnemonicToOpcode(OpcodeOperand.getToken()).value();

  MCInst Inst;
  Inst.setOpcode(Opcode);
  for (unsigned i = 1; i < Operands.size(); i++) { // NOLINT
    auto &Op = static_cast<LC2KOperand &>(*Operands[i]);
    if (Op.isReg())
      Op.addRegOperands(Inst, 1);
    else if (Op.isOffset())
      Op.addOffsetOperands(Inst, 1);
  }
  Out.emitInstruction(Inst, getSTI());
  return false;
}

ParseStatus LC2KAsmParser::parseDirective(AsmToken DirectiveID) {
  StringRef IDVal = DirectiveID.getIdentifier();
  SMLoc IDLoc = DirectiveID.getLoc();

  if (IDVal == ".fill") {
    SMLoc ValueLoc = Lexer.getLoc();
    const MCExpr *ValueExpr;

    if (auto MaybeValue = parseSignedInteger(Lexer)) {
      int64_t Value = *MaybeValue;
      if (!isInt<32>(Value))
        return Error(ValueLoc, ".fill value '" + std::to_string(Value) +
                                   "' does not fit in a signed 32-bit integer"),
               ParseStatus::Failure;
      ValueExpr = MCConstantExpr::create(Value, getContext());
    } else if (Lexer.is(AsmToken::Identifier)) {
      MCSymbol *Sym =
          getContext().getOrCreateSymbol(Lexer.getTok().getIdentifier());
      ValueExpr = MCSymbolRefExpr::create(Sym, getContext());
      Lexer.Lex();
    } else {
      return Error(ValueLoc, "expected integer or label for .fill value"),
             ParseStatus::Failure;
    }

    if (CurrentSection != Section::Data) {
      MCSection *DataSection = getContext().getELFSection(
          ".data", ELF::SHT_PROGBITS, ELF::SHF_ALLOC | ELF::SHF_WRITE);
      getStreamer().switchSection(DataSection);
      CurrentSection = Section::Data;
    }

    Parser.eatToEndOfStatement();
    getStreamer().emitValue(ValueExpr, 4, ValueLoc);

    return ParseStatus::Success;
  }

  if (IDVal ==
      StringRef(getContext().getAsmInfo()->getGlobalDirective()).trim()) {
    AsmToken LabelToken = Lexer.getTok();
    SMLoc LabelLoc = LabelToken.getLoc();

    if (LabelToken.isNot(AsmToken::Identifier))
      return Error(LabelLoc, "expected label after " + IDVal),
             ParseStatus::Failure;

    MCSymbol *Sym = getContext().getOrCreateSymbol(LabelToken.getIdentifier());
    Lexer.Lex();
    Parser.eatToEndOfStatement();
    getStreamer().emitSymbolAttribute(Sym, MCSA_Global);
    return ParseStatus::Success;
  }

  // LC2K doesn't support any directives except .fill and .globl, so return
  // failure to suppress fallthrough paths in AsmParser.
  return Error(IDLoc, "unsupported directive '" + IDVal + "'"),
         ParseStatus::Failure;
}

extern "C" LLVM_ABI LLVM_EXTERNAL_VISIBILITY void
LLVMInitializeLC2KAsmParser() { // NOLINT
  RegisterMCAsmParser<LC2KAsmParser> X(getTheLC2KTarget());
}
