`timescale 1ns / 1ps
package cpu_pkg;

    typedef enum logic [4:0] {
        ALU_ADD    = 5'd0,
        ALU_SUB    = 5'd1,
        ALU_AND    = 5'd2,
        ALU_OR     = 5'd3,
        ALU_XOR    = 5'd4,
        ALU_SLL    = 5'd5,
        ALU_SRL    = 5'd6,
        ALU_SRA    = 5'd7,
        ALU_SLT    = 5'd8,
        ALU_SLTU   = 5'd9,
        ALU_COPY_A = 5'd10,
        ALU_COPY_B = 5'd11
    } alu_op_t;

    typedef enum logic [2:0] {
        IMM_I = 3'd0,
        IMM_S = 3'd1,
        IMM_B = 3'd2,
        IMM_U = 3'd3,
        IMM_J = 3'd4
    } imm_type_t;

    typedef enum logic [3:0] {
        INST_R       = 4'd0,
        INST_I       = 4'd1,
        INST_LOAD    = 4'd2,
        INST_STORE   = 4'd3,
        INST_BRANCH  = 4'd4,
        INST_JAL     = 4'd5,
        INST_JALR    = 4'd6,
        INST_LUI     = 4'd7,
        INST_AUIPC   = 4'd8,
        INST_INVALID = 4'd9
    } instr_type_t;

    typedef enum logic {  // ALU 第一输入源
        ALU_A_RS1 = 1'b0,  // R/I/Load/Store/Branch 比较、JALR 目标
        ALU_A_PC  = 1'b1   // AUIPC / JAL(若走 ALU)
    } alu_a_sel_t;

    typedef enum logic {  // ALU 第二输入源
        ALU_B_RS2 = 1'b0,  // R-type
        ALU_B_IMM = 1'b1   // I/Load/Store/Branch/JAL/JALR/LUI/AUIPC
    } alu_b_sel_t;

    typedef enum logic [1:0] {
        MEM_BYTE = 2'd0,  // funct3 000 / 100
        MEM_HALF = 2'd1,  // funct3 001 / 101
        MEM_WORD = 2'd2   // funct3 010
    } mem_size_t;

    typedef enum logic [1:0] {
        WB_ALU = 2'd0,  // 绝大多数 ALU 结果
        WB_MEM = 2'd1,  // Load
        WB_PC4 = 2'd2   // JAL/JALR 的 link 到 rd
        // 若 LUI 不通过 ALU：再加 WB_IMM = 2'd3
    } wb_sel_t;

    typedef enum logic [2:0] {
        BR_EQ  = 3'd0,
        BR_NE  = 3'd1,
        BR_LT  = 3'd4,
        BR_GE  = 3'd5,
        BR_LTU = 3'd6,
        BR_GEU = 3'd7   // 建议直接与 funct3 对齐，省一次翻译
    } branch_type_t;
endpackage

