# With no -mcpu, or -mcpu=generic, LC2K must assemble exactly as for eecs470.

# RUN: llvm-mc --arch=lc2k --filetype=obj %s -o %t.default.o
# RUN: llvm-mc --arch=lc2k --filetype=obj -mcpu=generic %s -o %t.generic.o
# RUN: llvm-mc --arch=lc2k --filetype=obj -mcpu=eecs470 %s -o %t.eecs470.o
# RUN: cmp %t.default.o %t.eecs470.o
# RUN: cmp %t.generic.o %t.eecs470.o

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
