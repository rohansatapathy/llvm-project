add_llvm_component_group(LC2K)

set(LLVM_TARGET_DEFINITIONS LC2K.td)

tablegen(LLVM LC2KGenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM LC2KGenGlobalISel.inc -gen-global-isel)
tablegen(LLVM LC2KGenInstrInfo.inc -gen-instr-info)
tablegen(LLVM LC2KGenMCCodeEmitter.inc -gen-emitter)
tablegen(LLVM LC2KGenRegisterBank.inc -gen-register-bank)
tablegen(LLVM LC2KGenRegisterInfo.inc -gen-register-info)
tablegen(LLVM LC2KGenSubtargetInfo.inc -gen-subtarget)

add_public_tablegen_target(LC2KCommonTableGen)

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
