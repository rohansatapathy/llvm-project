add_llvm_component_group(LC2K)

set(LLVM_TARGET_DEFINITIONS LC2K.td)

tablegen(LLVM LC2KGenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM LC2KGenAsmMatcher.inc -gen-asm-matcher)
tablegen(LLVM LC2KGenDisassemblerTables.inc -gen-disassembler)
tablegen(LLVM LC2KGenGlobalISel.inc -gen-global-isel)
tablegen(LLVM LC2KGenInstrInfo.inc -gen-instr-info)
tablegen(LLVM LC2KGenMCCodeEmitter.inc -gen-emitter)
tablegen(LLVM LC2KGenRegisterBank.inc -gen-register-bank)
tablegen(LLVM LC2KGenRegisterInfo.inc -gen-register-info)
tablegen(LLVM LC2KGenSubtargetInfo.inc -gen-subtarget)
tablegen(LLVM LC2KGenCallingConv.inc -gen-callingconv)

add_public_tablegen_target(LC2KCommonTableGen)

add_llvm_target(LC2KCodeGen
  PARTIAL_SOURCES_INTENDED
  LC2KTargetMachine.cpp
  LC2KAsmPrinter.cpp
  # LC2KRegisterInfo.cpp
  # LC2KSubtarget.cpp
  # LC2KFrameLowering.cpp
  # LC2KInstrInfo.cpp

  LINK_COMPONENTS
  AsmPrinter
  CodeGen
  Core
  LC2KDesc
  LC2KInfo
  Support
  Target

  ADD_TO_COMPONENT
  LC2K
  )

add_subdirectory(AsmParser)
add_subdirectory(Disassembler)
add_subdirectory(MCTargetDesc)
add_subdirectory(TargetInfo)
