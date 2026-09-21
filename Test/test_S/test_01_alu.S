.section .text
.globl _start

_start:
    # ADD / SUB
    addi x1, x0, 10
    addi x2, x0, 3

    add  x3, x1, x2       # 13
    sub  x4, x1, x2       # 7

    # AND / OR / XOR
    and  x5, x1, x2       # 2
    or   x6, x1, x2       # 11
    xor  x7, x1, x2       # 9

    # SLL / SRL / SRA
    addi x8, x0, 2
    sll  x9, x1, x8       # 40
    srl  x10, x1, x8      # 2

    # 负数
    addi x11, x0, -8
    sra  x12, x11, x8     # -2
    srl  x13, x11, x8     # 大正数

    # SLT / SLTU
    addi x14, x0, -1
    addi x15, x0, 1

    slt  x16, x14, x15    # 1
    sltu x17, x14, x15    # 0

loop:
    jal x0, loop
