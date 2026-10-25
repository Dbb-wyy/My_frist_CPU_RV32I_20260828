#include <stdint.h>

/*
 * RV32I FPGA Board Bring-up Test
 *
 * Clock:       50 MHz
 * UART baud:   115200
 * UART format: 8-N-1
 *
 * UART_TXDATA: 0x30000000
 * UART_STATUS: 0x30000004
 * STATUS bit 0: TXE
 * STATUS bit 1: TC
 */

#define UART_TXDATA_ADDR  ((uintptr_t)0x30000000u)
#define UART_STATUS_ADDR  ((uintptr_t)0x30000004u)

#define UART_STATUS_TXE   (1u << 0)
#define UART_STATUS_TC    (1u << 1)

#define MMIO32(addr) \
    (*(volatile uint32_t *)(uintptr_t)(addr))

static const char hello_message[] = "Hello World!\r\n";


/* Send one character through UART. */
static void uart_putc(char ch)
{
    /* Wait until UART can accept a byte. */
    while ((MMIO32(UART_STATUS_ADDR) &
            UART_STATUS_TXE) == 0u) {
    }

    /* Write the character to UART_TXDATA. */
    MMIO32(UART_TXDATA_ADDR) = (uint32_t)(uint8_t)ch;
}


/* Send a null-terminated string. */
static void uart_puts(const char *s)
{
    while (*s != '\0') {
        uart_putc(*s);
        ++s;
    }
}


/* Wait for the complete UART frame to finish transmitting. */
static void uart_wait_complete(void)
{
    while ((MMIO32(UART_STATUS_ADDR) &
            UART_STATUS_TC) == 0u) {
    }
}


/*
 * Approximately compensate for the time spent transmitting
 * "Hello World!\r\n", so successive messages start about
 * one second apart.
 *
 * The loop uses two RV32I instructions per iteration:
 *   addi t0, t0, -1
 *   bne  t0, zero, loop
 *
 * Assumptions:
 *   - CPU executes one instruction per clock cycle.
 *   - Clock frequency is 50 MHz.
 *   - UART uses 434 clock cycles per bit at 115200 baud.
 */
static void delay_approximately_one_second(void)
{
    __asm__ volatile (
        "li   t0, 24969600\n\t"
        "1:\n\t"
        "addi t0, t0, -1\n\t"
        "bne  t0, zero, 1b\n\t"
        :
        :
        : "t0", "memory"
    );
}


int main(void)
{
    for (;;) {
        uart_puts(hello_message);

        /* Ensure the last character has finished transmitting. */
        uart_wait_complete();

        /* Wait for approximately one second before the next message. */
        delay_approximately_one_second();
    }

    return 0;
}