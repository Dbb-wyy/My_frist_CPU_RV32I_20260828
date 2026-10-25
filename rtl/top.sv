`timescale 1ns / 1ps

module top #(
    parameter string PROGRAM_HEX = "/home/dbb/Workspace/FPGA/My_frist_CPU_RV32I_20260828/Test/test_C/HEXS/test_board-bringup.hex"
) (
    input  logic clk,
    input  logic rst_n,       // 外部低电平有效复位
    output logic uart_tx      // UART 串行发送引脚
);

    //============================================================
    // 1. 复位信号
    //============================================================

    // CPU 和 UART 内部使用高电平有效复位
    logic rst;
    assign rst = ~rst_n;


    //============================================================
    // 2. 存储器与 UART 地址映射
    //============================================================

    // ROM 地址范围：[0x0000_0000, 0x0000_2000)
    localparam logic [31:0] ROM_BASE = 32'h0000_0000;
    localparam logic [31:0] ROM_SIZE = 32'h0000_2000;

    // RAM 地址范围：[0x1000_0000, 0x1000_2000)
    localparam logic [31:0] RAM_BASE = 32'h1000_0000;
    localparam logic [31:0] RAM_SIZE = 32'h0000_2000;

    // UART 发送数据寄存器：写入低 8 位即可发送一个字节
    localparam logic [31:0] UART_TXDATA_ADDR = 32'h3000_0000;

    // UART 状态寄存器：读取 TXE 和 TC 状态
    localparam logic [31:0] UART_STATUS_ADDR = 32'h3000_0004;

    // UART 工作参数：假设系统时钟为 50 MHz
    localparam integer UART_CLK_FREQ_HZ = 50_000_000;
    localparam integer UART_BAUD_RATE   = 115_200;


    //============================================================
    // 3. CPU 与存储器接口信号
    //============================================================

    logic [31:0] pc;
    logic [31:0] instr;

    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic [31:0] dmem_rdata;

    logic        dmem_we;
    logic [3:0]  dmem_be;

    logic [31:0] rom_rdata;
    logic [31:0] ram_rdata;

    logic        rom_sel;
    logic        ram_sel;


    //============================================================
    // 4. UART 内部连接信号
    //============================================================

    logic        uart_txdata_sel;
    logic        uart_status_sel;

    logic        uart_txdata_we;
    logic [7:0]  uart_txdata;

    logic        uart_txe;
    logic        uart_tc;
    logic [31:0] uart_status;


    //============================================================
    // 5. 地址译码
    //============================================================

    // 判断 CPU 当前访问的地址是否在 ROM 范围内
    assign rom_sel =
        (dmem_addr >= ROM_BASE) &&
        (dmem_addr <  ROM_BASE + ROM_SIZE);

    // 判断 CPU 当前访问的地址是否在 RAM 范围内
    assign ram_sel =
        (dmem_addr >= RAM_BASE) &&
        (dmem_addr <  RAM_BASE + RAM_SIZE);

    // 判断 CPU 当前访问的地址是否为 UART_TXDATA
    assign uart_txdata_sel =
        (dmem_addr == UART_TXDATA_ADDR);

    // 判断 CPU 当前访问的地址是否为 UART_STATUS
    assign uart_status_sel =
        (dmem_addr == UART_STATUS_ADDR);


    //============================================================
    // 6. UART 发送数据寄存器写入逻辑
    //============================================================

    // CPU 写 TXDATA 地址、最低字节有效，并且 UART 已准备好，
    // 才向 UART 发出写使能。
    //
    // 软件仍应先读取 UART_STATUS，确认 TXE=1，再执行写入。
    assign uart_txdata_we =
        dmem_we &&
        uart_txdata_sel &&
        dmem_be[0] &&
        uart_txe;

    // 发送内容取自 CPU 写数据的最低 8 位。
    // 对 SB 指令，datapath 会将待写字节放在相应的 byte lane；
    // 当目标地址为 UART_TXDATA_ADDR 时，低字节就是 dmem_wdata[7:0]。
    assign uart_txdata = dmem_wdata[7:0];


    //============================================================
    // 7. UART 状态寄存器
    //============================================================

    // bit 0：TXE，1 表示发送数据寄存器可接收新字节
    // bit 1：TC， 1 表示当前发送已全部完成
    // bit 31:2：保留，读回 0
    assign uart_status = {30'b0, uart_tc, uart_txe};


    //============================================================
    // 8. CPU 读数据选择
    //============================================================

    // 当 CPU 访问 UART_STATUS_ADDR 时，必须返回 UART 状态，
    // 否则将落入默认分支并读回 0。
    assign dmem_rdata =
        rom_sel         ? rom_rdata   :
        ram_sel         ? ram_rdata   :
        uart_status_sel ? uart_status :
                          32'b0;


    //============================================================
    // 9. CPU
    //============================================================

    cpu u_cpu (
        .clk        (clk),
        .rst        (rst),

        .pc         (pc),
        .instr      (instr),

        .dmem_addr  (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_rdata (dmem_rdata),
        .dmem_we    (dmem_we),
        .dmem_be    (dmem_be)
    );


    //============================================================
    // 10. ROM：取指端口 + 数据读取端口
    //============================================================

    rom #(
        .DEPTH    (2048),
        .HEX_FILE (PROGRAM_HEX)
    ) u_rom (
        .addr       (pc),
        .instr      (instr),
        .data_addr  (dmem_addr),
        .data_rdata (rom_rdata)
    );


    //============================================================
    // 11. RAM
    //============================================================

    ram #(
        .DEPTH   (2048),
        .RAM_BASE (RAM_BASE)
    ) u_ram (
        .clk   (clk),
        .addr  (dmem_addr),
        .wdata (dmem_wdata),
        .rdata (ram_rdata),

        // 只有地址属于 RAM 且 CPU 正在执行写操作时才写 RAM
        .we    (dmem_we && ram_sel),
        .be    (dmem_be)
    );


    //============================================================
    // 12. UART TX
    //============================================================

    uart_tx #(
        .CLK_FREQ_HZ (UART_CLK_FREQ_HZ),
        .BAUD_RATE   (UART_BAUD_RATE)
    ) u_uart_tx (
        .clk        (clk),
        .rst        (rst),

        .txdata_we  (uart_txdata_we),
        .txdata     (uart_txdata),

        .txe        (uart_txe),
        .tc         (uart_tc),

        // 直接连接到 top 的物理输出端口
        .tx         (uart_tx)
    );

endmodule
