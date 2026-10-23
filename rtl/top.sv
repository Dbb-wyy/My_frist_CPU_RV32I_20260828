`timescale 1ns / 1ps
module top #(
    parameter string PROGRAM_HEX = ""
) (
    input logic clk,
    input logic rst
);
    localparam logic [31:0] ROM_BASE = 32'h0000_0000;
    localparam logic [31:0] ROM_SIZE = 32'h0000_2000;  // 8 KB
    localparam logic [31:0] RAM_BASE = 32'h1000_0000;
    localparam logic [31:0] RAM_SIZE = 32'h0000_2000;  // 8 KB
    logic [31:0] pc;
    logic [31:0] instr;
    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic [31:0] dmem_rdata;
    logic        dmem_we;
    logic [ 3:0] dmem_be;
    logic [31:0] rom_rdata;
    logic [31:0] ram_rdata;
    logic        rom_sel;
    logic        ram_sel;
    // 地址译码
    assign rom_sel = (dmem_addr >= ROM_BASE) && (dmem_addr < ROM_BASE + ROM_SIZE);
    assign ram_sel = (dmem_addr >= RAM_BASE) && (dmem_addr < RAM_BASE + RAM_SIZE);
    // CPU 读数据选择
    assign dmem_rdata = rom_sel ? rom_rdata : ram_sel ? ram_rdata : 32'b0;
    // CPU
    cpu u_cpu (
        .clk       (clk),
        .rst       (rst),
        .pc        (pc),
        .instr     (instr),
        .dmem_addr (dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_rdata(dmem_rdata),
        .dmem_we   (dmem_we),
        .dmem_be   (dmem_be)
    );
    // ROM：取指端口 + 数据读取端口
    rom #(
        .DEPTH   (2048),
        .HEX_FILE(PROGRAM_HEX)
    ) u_rom (
        .addr      (pc),
        .instr     (instr),
        .data_addr (dmem_addr),
        .data_rdata(rom_rdata)
    );
    // RAM：保持原来的实现
    ram #(
        .DEPTH   (2048),
        .RAM_BASE(RAM_BASE)
    ) u_ram (
        .clk  (clk),
        .addr (dmem_addr),
        .wdata(dmem_wdata),
        .rdata(ram_rdata),
        .we   (dmem_we && ram_sel),
        .be   (dmem_be)
    );
endmodule

