add_llvm_component_library(LLVMLC2KDisassembler
  LC2KDisassembler.cpp

  LINK_COMPONENTS
  CodeGenTypes
  LC2KDesc
  LC2KInfo
  MCDisassembler
  Support

  ADD_TO_COMPONENT
  LC2K
  )
