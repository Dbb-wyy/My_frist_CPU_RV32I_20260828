.section .text
.globl _start

_start:
    addi x10, x0, 0
    addi x1, x0, 0

    jal x5, jal_target

return_point:
    addi x10, x10, 4

    jal x0, done
    addi x1, x1, 2

jal_target:
    # JAL 正确跳到这里
    addi x10, x10, 2

    jalr x0, 0(x5)
    addi x1, x1, 4


done:
    addi x2, x0, 100

loop:
    jal x0, loop
