.section .text
.globl _start

_start:
    # ADDI
    addi x1, x0, -1
    addi x2, x0, 2047

    # SLTI / SLTIU
    slti  x3, x1, 0
    slti  x4, x2, 2047

    sltiu x5, x1, 0
    sltiu x6, x0, 1

    # XORI / ORI / ANDI
    xori x7, x1, 0x0f
    ori  x8, x0, 0x55
    andi x9, x8, 0x0f

    # Shift immediate
    addi x10, x0, 1
    slli x11, x10, 4
    srli x12, x11, 2

    # SRAI
    addi x13, x0, -16
    srai x14, x13, 2

loop:
    jal x0, loop
