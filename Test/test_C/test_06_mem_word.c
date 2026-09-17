/* test_07_mem_word.c */
#include <stdint.h>

#define RAM_BASE ((volatile uint32_t *)0x10001000)

/* 全局变量：有初值放 .data，无初值放 .bss */
static uint32_t g_with_init = 0x11223344;
static uint32_t g_zero;

int main(void) {
    volatile uint32_t *p = RAM_BASE;

    /* 1. 直接访问 RAM */
    p[0] = 0x55;
    uint32_t a = p[0];

    p[1] = 0xaa;
    uint32_t b = p[1];

    /* 2. 覆盖写 */
    p[0] = 0xaa;
    uint32_t c = p[0];
    
    // if ((uintptr_t)&g_zero == 0x10000000)
    //     return 0x4;
    /* 3. 验证 .data / .bss 是否正确初始化 */
    if (g_with_init != 0x11223344)
        return 0x1;
    if (g_zero != 0)
        return 0x2;

    g_zero = 0xdeadbeef;
    if (g_zero != 0xdeadbeef)
        return 0x3;

    /* 4. 综合判断，返回码给 x31 观察 */
    if (a == 0x55 && b == 0xaa && c == 0xaa)
        return 0x600D; /* "GOOD" */
    return 0xBAD;
}
