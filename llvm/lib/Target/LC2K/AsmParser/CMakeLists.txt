add_llvm_component_library(LLVMLC2KAsmParser
  LC2KAsmParser.cpp

  LINK_COMPONENTS
  LC2KDesc
  LC2KInfo
  MC
  MCParser
  Support
  TargetParser

  ADD_TO_COMPONENT
  LC2K
)
