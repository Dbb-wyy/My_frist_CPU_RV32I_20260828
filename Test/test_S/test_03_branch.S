.section .text
.globl _start

_start:
    addi x10, x0, 0

    # =========================
    # BEQ
    # 5 == 5，应跳转
    # =========================
    addi x1, x0, 5
    addi x2, x0, 5

    beq x1, x2, beq_ok

    # 如果错误地没有跳，这里会执行
    addi x10, x10, 1

beq_ok:

    # =========================
    # BNE
    # 5 != 6，应跳转
    # =========================
    addi x3, x0, 6

    bne x1, x3, bne_ok

    addi x10, x10, 2

bne_ok:

    # =========================
    # BLT
    # -1 < 1，应跳转
    # =========================
    addi x4, x0, -1
    addi x5, x0, 1

    blt x4, x5, blt_ok

    addi x10, x10, 4

blt_ok:

    # =========================
    # BGE
    # 1 >= -1，应跳转
    # =========================
    bge x5, x4, bge_ok

    addi x10, x10, 8

bge_ok:

    # =========================
    # BLTU
    # 0xffffffff < 1
    # 无符号比较：错误，应“不跳”
    # =========================
    bltu x4, x5, bltu_wrong

    # 正确路径
    addi x10, x10, 0

    jal x0, bltu_ok

bltu_wrong:
    addi x10, x10, 16

bltu_ok:

    # =========================
    # BGEU
    # 0xffffffff >= 1
    # 无符号比较：应跳转
    # =========================
    bgeu x4, x5, bgeu_ok

    addi x10, x10, 32

bgeu_ok:

loop:
    jal x0, loop
