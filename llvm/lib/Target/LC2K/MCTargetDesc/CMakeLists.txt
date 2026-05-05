add_llvm_component_library(LLVMLC2KDesc
  LC2KMCTargetDesc.cpp
  LC2KInstPrinter.cpp
  LC2KMCAsmInfo.cpp
  LC2KMCCodeEmitter.cpp
  LC2KTargetStreamer.cpp
  LC2KMCAsmBackend.cpp

  LINK_COMPONENTS
  CodeGenTypes
  MC
  LC2KInfo
  Support
  TargetParser

  ADD_TO_COMPONENT
  LC2K
  )
