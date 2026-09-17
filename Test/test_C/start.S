.section .text.init
.globl _start

_start:
    # 1. 设置栈指针
    la      sp, _stack_top

    # 2. 将 .data 从 ROM 拷贝到 RAM
    la      a0, _data_lma
    la      a1, _data_start
    la      a2, _data_end
1:
    bgeu    a1, a2, 2f
    lw      t0, 0(a0)
    sw      t0, 0(a1)
    addi    a0, a0, 4
    addi    a1, a1, 4
    j       1b
2:

    # 3. 清零 .bss
    la      a1, _bss_start
    la      a2, _bss_end
3:
    bgeu    a1, a2, 4f
    sw      x0, 0(a1)
    addi    a1, a1, 4
    j       3b
4:

    # 4. 调用 main
    call    main

    # 5. main 返回：把返回值放到一个易观察的位置，然后死循环
    #    （a0 已保存 main 的返回值）
    mv      x31, a0        # x31 作为“返回码”，方便 $monitor 观察
loop:
    jal     x0, loop
