#include "LC2K.h"
#include "clang/Basic/MacroBuilder.h"

using namespace clang;
using namespace clang::targets;

void LC2KTargetInfo::getTargetDefines(const LangOptions &Opts,
                                      MacroBuilder &Builder) const {
  Builder.defineMacro("__LC2K__");
  Builder.defineMacro("__lc2k__");
}

const char *const LC2KTargetInfo::GCCRegNames[] = {
    "0", "1", "2",  "3",  "4",  "5",  "6",  "7",
    "8", "9", "10", "11", "12", "13", "14", "15"};

ArrayRef<const char *> LC2KTargetInfo::getGCCRegNames() const {
  return llvm::ArrayRef(GCCRegNames);
}

ArrayRef<TargetInfo::GCCRegAlias> LC2KTargetInfo::getGCCRegAliases() const {
  return llvm::ArrayRef<TargetInfo::GCCRegAlias>();
}
