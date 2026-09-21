`timescale 1ns / 1ps

import cpu_pkg::*;

module controller_tb;

    //==========================================================
    // DUT Inputs
    //==========================================================
    instr_type_t instr_type;
    logic [2:0]  funct3;
    logic [6:0]  funct7;

    //==========================================================
    // DUT Outputs
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
    // DUT
    //==========================================================
    controller dut (
        .instr_type   (instr_type),
        .funct3       (funct3),
        .funct7       (funct7),

        .alu_op       (alu_op),
        .alu_a_sel    (alu_a_sel),
        .alu_b_sel    (alu_b_sel),

        .imm_type     (imm_type),

        .reg_write    (reg_write),

        .mem_read     (mem_read),
        .mem_write    (mem_write),
        .mem_size     (mem_size),
        .mem_unsigned (mem_unsigned),

        .wb_sel       (wb_sel),

        .branch       (branch),
        .branch_type  (branch_type),
        .jump         (jump)
    );

    //==========================================================
    // 统计与检查任务
    //==========================================================
    int pass_count = 0;
    int fail_count = 0;

    // 为了统一，把所有信号都当成 32-bit 比较。
    // enum 会自动扩展成对应数值，1-bit 信号也会零扩展。
    task check(
        input string         name,
        input logic [31:0]   actual,
        input logic [31:0]   expected
    );
        if (actual === expected) begin
            pass_count++;
            $display("[PASS] %-28s => %h", name, actual);
        end else begin
            fail_count++;
            $display("[FAIL] %-28s => actual=%h, expected=%h",
                     name, actual, expected);
        end
    endtask

    //==========================================================
    // 主测试流程
    //==========================================================
    initial begin
        $display("========== Controller Testbench Start ==========");

        //------------------------------------------------------
        // 1. INVALID：应保持所有默认值
        //------------------------------------------------------
        instr_type = INST_INVALID;
        funct3     = 3'b000;
        funct7     = 7'b0000000;
        #1;

        check("INV alu_op",      alu_op,      ALU_ADD);
        check("INV alu_a_sel",   alu_a_sel,   ALU_A_RS1);
        check("INV alu_b_sel",   alu_b_sel,   ALU_B_IMM);
        check("INV imm_type",    imm_type,    IMM_I);
        check("INV reg_write",   reg_write,   1'b0);
        check("INV mem_read",    mem_read,    1'b0);
        check("INV mem_write",   mem_write,   1'b0);
        check("INV mem_size",    mem_size,    MEM_WORD);
        check("INV mem_unsigned",mem_unsigned,1'b0);
        check("INV wb_sel",      wb_sel,      WB_ALU);
        check("INV branch",      branch,      1'b0);
        check("INV branch_type", branch_type, BR_EQ);
        check("INV jump",        jump,        1'b0);

        //------------------------------------------------------
        // 2. R-type：ADD / SUB
        //------------------------------------------------------
        instr_type = INST_R;
        funct3     = 3'b000;   // ADD
        funct7     = 7'b0000000;
        #1;

        check("R ADD alu_op",    alu_op,    ALU_ADD);
        check("R ADD alu_a_sel", alu_a_sel, ALU_A_RS1);
        check("R ADD alu_b_sel", alu_b_sel, ALU_B_RS2);
        check("R ADD reg_write", reg_write, 1'b1);
        check("R ADD mem_read",  mem_read,  1'b0);
        check("R ADD mem_write", mem_write, 1'b0);
        check("R ADD wb_sel",    wb_sel,    WB_ALU);

        funct3 = 3'b000;        // SUB
        funct7 = 7'b0100000;
        #1;
        check("R SUB alu_op",    alu_op, ALU_SUB);

        funct3 = 3'b111;        // AND
        funct7 = 7'b0000000;
        #1;
        check("R AND alu_op",    alu_op, ALU_AND);

        funct3 = 3'b101;        // SRA
        funct7 = 7'b0100000;
        #1;
        check("R SRA alu_op",    alu_op, ALU_SRA);

        //------------------------------------------------------
        // 3. I-type：ADDI / SRAI
        //------------------------------------------------------
        instr_type = INST_I;
        funct3     = 3'b000;    // ADDI
        funct7     = 7'b0000000;
        #1;

        check("I ADDI alu_op",   alu_op,    ALU_ADD);
        check("I ADDI alu_b_sel",alu_b_sel, ALU_B_IMM);
        check("I ADDI imm_type", imm_type,  IMM_I);
        check("I ADDI reg_write",reg_write, 1'b1);

        funct3 = 3'b101;        // SRAI
        funct7 = 7'b0100000;
        #1;
        check("I SRAI alu_op",   alu_op, ALU_SRA);

        //------------------------------------------------------
        // 4. Load：LW / LBU
        //------------------------------------------------------
        instr_type = INST_LOAD;
        funct3     = 3'b010;    // LW
        funct7     = 7'b0000000;
        #1;

        check("LW reg_write",    reg_write,    1'b1);
        check("LW mem_read",     mem_read,     1'b1);
        check("LW mem_write",    mem_write,    1'b0);
        check("LW mem_size",     mem_size,     MEM_WORD);
        check("LW mem_unsigned", mem_unsigned, 1'b0);
        check("LW wb_sel",       wb_sel,       WB_MEM);
        check("LW alu_a_sel",    alu_a_sel,    ALU_A_RS1);
        check("LW alu_b_sel",    alu_b_sel,    ALU_B_IMM);
        check("LW alu_op",       alu_op,       ALU_ADD);
        check("LW imm_type",     imm_type,     IMM_I);

        funct3 = 3'b100;        // LBU
        #1;
        check("LBU mem_size",    mem_size,     MEM_BYTE);
        check("LBU mem_unsigned",mem_unsigned, 1'b1);
        check("LBU wb_sel",      wb_sel,       WB_MEM);

        //------------------------------------------------------
        // 5. Store：SW / SB
        //------------------------------------------------------
        instr_type = INST_STORE;
        funct3     = 3'b010;    // SW
        funct7     = 7'b0000000;
        #1;

        check("SW reg_write",    reg_write,   1'b0);
        check("SW mem_read",     mem_read,    1'b0);
        check("SW mem_write",    mem_write,   1'b1);
        check("SW mem_size",     mem_size,    MEM_WORD);
        check("SW imm_type",     imm_type,    IMM_S);
        check("SW alu_a_sel",    alu_a_sel,   ALU_A_RS1);
        check("SW alu_b_sel",    alu_b_sel,   ALU_B_IMM);
        check("SW alu_op",       alu_op,      ALU_ADD);

        funct3 = 3'b000;        // SB
        #1;
        check("SB mem_size",     mem_size, MEM_BYTE);

        //------------------------------------------------------
        // 6. Branch：BEQ / BGE / BGEU
        //------------------------------------------------------
        instr_type = INST_BRANCH;
        funct3     = 3'b000;    // BEQ
        funct7     = 7'b0000000;
        #1;

        check("BEQ branch",      branch,      1'b1);
        check("BEQ jump",        jump,        1'b0);
        check("BEQ reg_write",   reg_write,   1'b0);
        check("BEQ alu_b_sel",   alu_b_sel,   ALU_B_RS2);
        check("BEQ imm_type",    imm_type,    IMM_B);
        check("BEQ branch_type", branch_type, BR_EQ);
        check("BEQ alu_op",      alu_op,      ALU_SUB);

        funct3 = 3'b101;        // BGE
        #1;
        check("BGE branch_type", branch_type, BR_GE);
        check("BGE alu_op",      alu_op,      ALU_SLT);

        funct3 = 3'b111;        // BGEU
        #1;
        check("BGEU branch_type",branch_type, BR_GEU);
        check("BGEU alu_op",     alu_op,      ALU_SLTU);

        //------------------------------------------------------
        // 7. JAL
        //------------------------------------------------------
        instr_type = INST_JAL;
        funct3     = 3'b000;
        funct7     = 7'b0000000;
        #1;

        check("JAL reg_write",   reg_write,   1'b1);
        check("JAL wb_sel",      wb_sel,      WB_PC4);
        check("JAL jump",        jump,        1'b1);
        check("JAL branch",      branch,      1'b0);
        check("JAL alu_a_sel",   alu_a_sel,   ALU_A_PC);
        check("JAL alu_b_sel",   alu_b_sel,   ALU_B_IMM);
        check("JAL alu_op",      alu_op,      ALU_ADD);
        check("JAL imm_type",    imm_type,    IMM_J);

        //------------------------------------------------------
        // 8. JALR
        //------------------------------------------------------
        instr_type = INST_JALR;
        funct3     = 3'b000;
        funct7     = 7'b0000000;
        #1;

        check("JALR reg_write",  reg_write,   1'b1);
        check("JALR wb_sel",     wb_sel,      WB_PC4);
        check("JALR jump",       jump,        1'b1);
        check("JALR branch",     branch,      1'b0);
        check("JALR alu_a_sel",  alu_a_sel,   ALU_A_RS1);
        check("JALR alu_b_sel",  alu_b_sel,   ALU_B_IMM);
        check("JALR alu_op",     alu_op,      ALU_ADD);
        check("JALR imm_type",   imm_type,    IMM_I);

        //------------------------------------------------------
        // 9. LUI
        //------------------------------------------------------
        instr_type = INST_LUI;
        funct3     = 3'b000;
        funct7     = 7'b0000000;
        #1;

        check("LUI reg_write",   reg_write,   1'b1);
        check("LUI alu_op",      alu_op,      ALU_COPY_B);
        check("LUI alu_b_sel",   alu_b_sel,   ALU_B_IMM);
        check("LUI imm_type",    imm_type,    IMM_U);
        check("LUI wb_sel",      wb_sel,      WB_ALU);

        //------------------------------------------------------
        // 10. AUIPC
        //------------------------------------------------------
        instr_type = INST_AUIPC;
        funct3     = 3'b000;
        funct7     = 7'b0000000;
        #1;

        check("AUIPC reg_write", reg_write,   1'b1);
        check("AUIPC alu_a_sel", alu_a_sel,   ALU_A_PC);
        check("AUIPC alu_b_sel", alu_b_sel,   ALU_B_IMM);
        check("AUIPC alu_op",    alu_op,      ALU_ADD);
        check("AUIPC imm_type",  imm_type,    IMM_U);

        //------------------------------------------------------
        // 汇总
        //------------------------------------------------------
        $display("==========================================");
        $display("  Total: %0d  PASS: %0d  FAIL: %0d",
                 pass_count + fail_count, pass_count, fail_count);
        if (fail_count == 0)
            $display("  *** ALL CONTROLLER TESTS PASSED ***");
        else
            $display("  *** SOME CONTROLLER TESTS FAILED ***");
        $display("==========================================");

        $finish;
    end

endmodule