add_llvm_component_library(LC2KAsmParser
  LC2KAsmParser.cpp

  LINK_COMPONENTS
  CodeGenTypes
  LC2KCodeGen
  LC2KInfo
  MC
  MCParser
  Support

  ADD_TO_COMPONENT
  LC2K
)
