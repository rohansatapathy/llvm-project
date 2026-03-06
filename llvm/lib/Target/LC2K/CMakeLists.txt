add_llvm_component_group(LC2K)

add_llvm_target(LC2KCodeGen
  LC2KTargetMachine.cpp

  LINK_COMPONENTS
  CodeGen
  Core
  LC2KInfo
  Support
  Target

  ADD_TO_COMPONENT
  LC2K
  )

add_subdirectory(TargetInfo)
