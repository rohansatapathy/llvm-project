# With no -mcpu, or -mcpu=generic, LC2K must assemble exactly as for eecs470.

# RUN: llvm-mc --arch=lc2k --filetype=obj %s -o %t.default.o
# RUN: llvm-mc --arch=lc2k --filetype=obj -mcpu=generic %s -o %t.generic.o
# RUN: llvm-mc --arch=lc2k --filetype=obj -mcpu=eecs470 %s -o %t.eecs470.o
# RUN: cmp %t.default.o %t.eecs470.o
# RUN: cmp %t.generic.o %t.eecs470.o

# Sanity check that the input is CPU-sensitive, so the cmps above are
# meaningful. Compare only .text: the ELF header flags differ between CPUs
# anyway, which would make a whole-object comparison pass trivially. phobos
# has no nor, so drop it from both inputs.
# RUN: grep -v nor %s > %t.no-nor.s
# RUN: llvm-mc --arch=lc2k --filetype=obj -mcpu=eecs470 %t.no-nor.s \
# RUN:   -o %t.no-nor.eecs470.o
# RUN: llvm-mc --arch=lc2k --filetype=obj -mcpu=phobos %t.no-nor.s \
# RUN:   -o %t.no-nor.phobos.o
# RUN: llvm-objcopy -O binary -j .text %t.no-nor.eecs470.o %t.eecs470.text
# RUN: llvm-objcopy -O binary -j .text %t.no-nor.phobos.o %t.phobos.text
# RUN: not cmp %t.eecs470.text %t.phobos.text > /dev/null

start   add     1 2 3
        nor     1 2 3
        nand    1 2 3
        addi    1 2 -5
        lw      0 1 data
        sw      0 1 data
        beq     0 0 done
        noop
done    jalr    15 2
        halt
data    .fill   start
