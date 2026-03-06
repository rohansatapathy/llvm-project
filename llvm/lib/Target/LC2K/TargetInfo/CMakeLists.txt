add_llvm_component_library(LLVMLC2KInfo
  LC2KTargetInfo.cpp

  LINK_COMPONENTS
  MC
  Support

  ADD_TO_COMPONENT
  LC2K
  )
