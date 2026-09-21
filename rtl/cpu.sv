`timescale 1ns / 1ps

import cpu_pkg::*;

module cpu (
    input  logic        clk,
    input  logic        rst,

    //==========================================================
    // 指令存储器接口（由 top 连到 rom）
    //==========================================================
    output logic [31:0] pc,       // 送给 rom 的地址
    input  logic [31:0] instr,    // rom 返回的指令

    //==========================================================
    // 数据存储器接口（由 top 连到 ram）
    //==========================================================
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    input  logic [31:0] dmem_rdata,
    output logic        dmem_we,
    output logic [ 3:0] dmem_be
);

    //==========================================================
    // decoder 输出
    //==========================================================
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;
    logic [6:0]  opcode;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    instr_type_t instr_type;

    //==========================================================
    // controller 输出
    //==========================================================
    alu_op_t      alu_op;
    alu_a_sel_t   alu_a_sel;
    alu_b_sel_t   alu_b_sel;
    imm_type_t    imm_type;
    logic         reg_write;
    logic         mem_read;
    logic         mem_write;
    mem_size_t    mem_size;
    logic         mem_unsigned;
    wb_sel_t      wb_sel;
    logic         branch;
    branch_type_t branch_type;
    logic         jump;

    //==========================================================
    // Decoder：从指令中提取字段
    //==========================================================
    decoder u_decoder (
        .inst       (instr),
        .rs1        (rs1),
        .rs2        (rs2),
        .rd         (rd),
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7     (funct7),
        .instr_type (instr_type)
    );

    //==========================================================
    // Controller：生成控制信号
    //==========================================================
    controller u_controller (
        .instr_type  (instr_type),
        .funct3      (funct3),
        .funct7      (funct7),

        .alu_op      (alu_op),
        .alu_a_sel   (alu_a_sel),
        .alu_b_sel   (alu_b_sel),

        .imm_type    (imm_type),

        .reg_write   (reg_write),

        .mem_read    (mem_read),
        .mem_write   (mem_write),
        .mem_size    (mem_size),
        .mem_unsigned(mem_unsigned),

        .wb_sel      (wb_sel),

        .branch      (branch),
        .branch_type (branch_type),
        .jump        (jump)
    );

    //==========================================================
    // Datapath：核心数据通路
    //==========================================================
    datapath u_datapath (
        .clk         (clk),
        .rst         (rst),

        .instr       (instr),
        .pc          (pc),

        .rs1         (rs1),
        .rs2         (rs2),
        .rd          (rd),

        .alu_op      (alu_op),
        .alu_a_sel   (alu_a_sel),
        .alu_b_sel   (alu_b_sel),

        .imm_type    (imm_type),

        .reg_write   (reg_write),
        .wb_sel      (wb_sel),

        .branch      (branch),
        .branch_type (branch_type),
        .jump        (jump),

        .mem_read    (mem_read),
        .mem_write   (mem_write),
        .mem_size    (mem_size),
        .mem_unsigned(mem_unsigned),

        .dmem_addr   (dmem_addr),
        .dmem_wdata  (dmem_wdata),
        .dmem_rdata  (dmem_rdata),
        .dmem_we     (dmem_we),
        .dmem_be     (dmem_be)
    );

endmodule