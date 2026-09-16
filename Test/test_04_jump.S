.section .text
.globl _start

_start:
    addi x10, x0, 0
    addi x1, x0, 0
    # =========================================================
    # JAL 测试
    #
    # 如果 JAL 不跳：
    #   顺序执行下面的 addi x10, x10, 4
    #
    # 如果 JAL 正确：
    #   跳到 jal_target
    #   x10 += 2
    #   再通过 JALR 返回到这里
    # =========================================================
    jal x5, jal_target

return_point:
    addi x10, x10, 4

    jal x0, done
    addi x1, x1, 2

jal_target:
    # JAL 正确跳到这里
    addi x10, x10, 2

    # x5 应该保存 JAL 指令的 PC + 4
    # 也就是 return_point
    jalr x0, 0(x5)
    addi x1, x1, 4


done:
    addi x2, x0, 100
    # 正确执行：
    #   JAL 跳到 jal_target  -> +2
    #   JALR 返回            -> +4
    #
    # 最终 x10 = 6

loop:
    jal x0, loop
