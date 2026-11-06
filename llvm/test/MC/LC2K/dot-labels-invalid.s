# RUN: not llvm-mc --arch=lc2k --filetype=obj %s -o /dev/null 2>&1 | FileCheck %s

# A dot-prefixed word that isn't a directive follows the same rules as any
# other label.

# CHECK: [[@LINE+1]]:6: error: expected opcode after label, found nothing
.Lbad
# CHECK: [[@LINE+1]]:7: error: expected opcode after label, found '5'
.fil  5
# CHECK: [[@LINE+1]]:7: error: expected opcode after label, found 'main'
.gobl main
.Ldup noop
# CHECK: [[@LINE+1]]:1: error: label '.Ldup' already defined
.Ldup noop
