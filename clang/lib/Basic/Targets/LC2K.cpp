#include "LC2K.h"
#include "clang/Basic/Diagnostic.h"
#include "clang/Basic/MacroBuilder.h"
#include "llvm/ADT/StringSwitch.h"

using namespace clang;
using namespace clang::targets;

void LC2KTargetInfo::getTargetDefines(const LangOptions &Opts,
                                      MacroBuilder &Builder) const {
  Builder.defineMacro("__LC2K__");
  Builder.defineMacro("__lc2k__");

  if (CPU == "eecs470")
    Builder.defineMacro("__LC2K_CPU_EECS470__");
  else if (CPU == "phobos")
    Builder.defineMacro("__LC2K_CPU_PHOBOS__");
  else
    llvm_unreachable("setCPU accepted an unknown LC2K CPU");

  // LC2K has no frame pointer, so dynamically-sized stack allocations
  // (VLAs, and by extension alloca()) can't be lowered correctly -- see
  // the G_DYN_STACKALLOC/G_STACKSAVE/G_STACKRESTORE handling in
  // LC2KLegalizerInfo.cpp. VLAs are an optional C11+ feature signaled by
  // this macro; alloca() has no ISO C or compiler-predefined-macro
  // equivalent to signal its absence, so it isn't defined here.
  Builder.defineMacro("__STDC_NO_VLA__", "1");
}

StringRef LC2KTargetInfo::normalizeCPU(StringRef Name) {
  if (Name.empty() || Name == "generic")
    return "eecs470";
  return Name;
}

bool LC2KTargetInfo::isValidCPUName(StringRef Name) const {
  return llvm::StringSwitch<bool>(normalizeCPU(Name))
      .Cases({"eecs470", "phobos"}, true)
      .Default(false);
}

void LC2KTargetInfo::fillValidCPUList(
    SmallVectorImpl<StringRef> &Values) const {
  Values.append({"eecs470", "phobos"});
}

bool LC2KTargetInfo::setCPU(StringRef Name) {
  if (!isValidCPUName(Name))
    return false;
  CPU = normalizeCPU(Name).str();
  return true;
}

bool LC2KTargetInfo::handleTargetFeatures(std::vector<std::string> &Features,
                                          DiagnosticsEngine &Diags) {
  if (Features.empty())
    return true;
  Diags.Report(diag::err_target_feature_unsupported) << Features.front();
  return false;
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
