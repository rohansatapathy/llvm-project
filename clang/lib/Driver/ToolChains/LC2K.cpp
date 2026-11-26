//===--- LC2K.cpp - LC2K ToolChain Implementations --------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "LC2K.h"
#include "clang/Driver/CommonArgs.h"
#include "clang/Driver/Compilation.h"
#include "clang/Driver/Driver.h"
#include "clang/Driver/InputInfo.h"
#include "clang/Options/Options.h"
#include "llvm/Option/ArgList.h"
#include "llvm/Support/Path.h"

using namespace llvm::opt;
using namespace clang;
using namespace clang::driver;
using namespace clang::driver::tools;
using namespace clang::driver::toolchains;

void lc2k::Linker::ConstructJob(Compilation &C, const JobAction &JA,
                                const InputInfo &Output,
                                const InputInfoList &Inputs,
                                const ArgList &Args,
                                const char *LinkingOutput) const {
  const ToolChain &TC = getToolChain();
  ArgStringList CmdArgs;

  if (Output.isFilename()) {
    CmdArgs.push_back("-o");
    CmdArgs.push_back(Output.getFilename());
  }

  Args.AddAllArgs(CmdArgs, options::OPT_T);
  Args.AddAllArgs(CmdArgs, options::OPT_e);

  AddLinkerInputs(TC, Inputs, Args, CmdArgs, JA);

  AddRunTimeLibs(TC, TC.getDriver(), CmdArgs, Args);

  const char *Exec = Args.MakeArgString(TC.GetLinkerPath());
  C.addCommand(std::make_unique<Command>(JA, *this,
                                         ResponseFileSupport::AtFileCurCP(),
                                         Exec, CmdArgs, Inputs, Output));
}

LC2KToolChain::LC2KToolChain(const Driver &D, const llvm::Triple &Triple,
                             const ArgList &Args)
    : ToolChain(D, Triple, Args) {
  // The CPUs use different instruction encodings and lld refuses to mix them,
  // so the runtime libraries are built once per CPU, into a subdirectory of
  // the per-target runtime directory named after the CPU (see
  // LLVM_BUILTIN_MULTILIBS), e.g. lib/lc2k-unknown-none/phobos/.
  std::string CPU = tools::getCPUName(D, Args, Triple);
  if (CPU.empty() || CPU == "generic")
    CPU = "eecs470";
  if (std::optional<std::string> RuntimePath = getRuntimePath()) {
    for (std::string &Path : getLibraryPaths()) {
      if (Path != *RuntimePath)
        continue;
      SmallString<128> P(Path);
      llvm::sys::path::append(P, CPU);
      Path = std::string(P);
    }
  }
}

Tool *LC2KToolChain::buildLinker() const { return new lc2k::Linker(*this); }
