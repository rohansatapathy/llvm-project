#include "LC2K.h"
#include "clang/Basic/MacroBuilder.h"

using namespace clang;
using namespace clang::targets;

void LC2KTargetInfo::getTargetDefines(const LangOptions &Opts,
                                      MacroBuilder &Builder) const {
  Builder.defineMacro("__LC2K__");
  Builder.defineMacro("__lc2k__");

  // LC2K has no frame pointer, so dynamically-sized stack allocations
  // (VLAs, and by extension alloca()) can't be lowered correctly -- see
  // the G_DYN_STACKALLOC/G_STACKSAVE/G_STACKRESTORE handling in
  // LC2KLegalizerInfo.cpp. VLAs are an optional C11+ feature signaled by
  // this macro; alloca() has no ISO C or compiler-predefined-macro
  // equivalent to signal its absence, so it isn't defined here.
  Builder.defineMacro("__STDC_NO_VLA__", "1");
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
