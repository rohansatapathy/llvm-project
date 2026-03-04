#ifndef LLVM_CLANG_LIB_BASIC_TARGETS_LC2K_H
#define LLVM_CLANG_LIB_BASIC_TARGETS_LC2K_H

#include "clang/Basic/TargetInfo.h"
#include "clang/Basic/TargetOptions.h"
#include "llvm/Support/Compiler.h"
#include "llvm/TargetParser/Triple.h"

namespace clang {
namespace targets {

class LLVM_LIBRARY_VISIBILITY LC2KTargetInfo : public TargetInfo {

  static const char *const GCCRegNames[];

public:
  LC2KTargetInfo(const llvm::Triple &Triple, const TargetOptions &)
      : TargetInfo(Triple) {

    resetDataLayout();
  };

  void getTargetDefines(const LangOptions &Opts,
                        MacroBuilder &Builder) const override;

  llvm::SmallVector<Builtin::InfosShard> getTargetBuiltins() const override {
    // LC2K doesn't have any hardware-accelerated builtins.
    return {};
  };

  BuiltinVaListKind getBuiltinVaListKind() const override {
    return TargetInfo::CharPtrBuiltinVaList;
  };

  bool validateAsmConstraint(const char *&Name,
                             TargetInfo::ConstraintInfo &info) const override {
    // Disallow inline asm for now.
    // TODO: Figure out how to support this.
    return false;
  };

  std::string_view getClobbers() const override {
    // No implicit register clobbering in LC2K.
    return "";
  };

  ArrayRef<const char *> getGCCRegNames() const override;

  ArrayRef<TargetInfo::GCCRegAlias> getGCCRegAliases() const override;
};

} // namespace targets
} // namespace clang

#endif // LLVM_CLANG_LIB_BASIC_TARGETS_LC2K_H
