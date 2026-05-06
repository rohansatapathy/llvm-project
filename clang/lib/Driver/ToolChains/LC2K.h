//===--- LC2K.h - LC2K ToolChain Implementations ----------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_CLANG_LIB_DRIVER_TOOLCHAINS_LC2K_H
#define LLVM_CLANG_LIB_DRIVER_TOOLCHAINS_LC2K_H

#include "clang/Driver/Tool.h"
#include "clang/Driver/ToolChain.h"

namespace clang {
namespace driver {

namespace tools {
namespace lc2k {

class LLVM_LIBRARY_VISIBILITY Linker : public Tool {
public:
  Linker(const ToolChain &TC) : Tool("lc2k::Linker", "linker", TC) {}
  bool hasIntegratedCPP() const override { return false; }
  bool isLinkJob() const override { return true; }
  void ConstructJob(Compilation &C, const JobAction &JA,
                    const InputInfo &Output, const InputInfoList &Inputs,
                    const llvm::opt::ArgList &TCArgs,
                    const char *LinkingOutput) const override;
};

} // namespace lc2k
} // namespace tools

namespace toolchains {

class LLVM_LIBRARY_VISIBILITY LC2KToolChain : public ToolChain {
public:
  LC2KToolChain(const Driver &D, const llvm::Triple &Triple,
                const llvm::opt::ArgList &Args)
      : ToolChain(D, Triple, Args) {}

  const char *getDefaultLinker() const override { return "ld.lld"; }

  bool isPICDefault() const override { return false; }

  bool isPIEDefault(const llvm::opt::ArgList &Args) const override {
    return false;
  }

  bool isPICDefaultForced() const override { return false; }

protected:
  Tool *buildLinker() const override;
};

} // end namespace toolchains
} // end namespace driver
} // end namespace clang

#endif // LLVM_CLANG_LIB_DRIVER_TOOLCHAINS_LC2K_H
