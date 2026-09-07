`timescale 1ns / 1ps

module top (
    input  logic clk,
    input  logic rst
);

    //==========================================================
    // 顶层连线
    //==========================================================
    logic [31:0] pc;
    logic [31:0] instr;

    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic [31:0] dmem_rdata;
    logic        dmem_we;
    logic [ 3:0] dmem_be;

    //==========================================================
    // CPU 核心
    //==========================================================
    cpu u_cpu (
        .clk         (clk),
        .rst         (rst),

        .pc          (pc),
        .instr       (instr),

        .dmem_addr   (dmem_addr),
        .dmem_wdata  (dmem_wdata),
        .dmem_rdata  (dmem_rdata),
        .dmem_we     (dmem_we),
        .dmem_be     (dmem_be)
    );

    //==========================================================
    // 指令 ROM：只读、异步读
    //==========================================================
    rom #(
        .DEPTH   (2048),
        .HEX_FILE("/home/dbb/Workspace/FPGA/My_frist_CPU_RV32I_20260828/program.hex")
    ) u_rom (
        .addr  (pc),
        .instr (instr)
    );

    //==========================================================
    // 数据 RAM：同步写、异步读、字节使能
    //==========================================================
    ram #(
        .DEPTH(2048)
    ) u_ram (
        .clk   (clk),
        .addr  (dmem_addr),
        .wdata (dmem_wdata),
        .rdata (dmem_rdata),
        .we    (dmem_we),
        .be    (dmem_be)
    );

endmodule