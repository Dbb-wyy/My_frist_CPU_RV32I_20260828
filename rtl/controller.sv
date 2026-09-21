import cpu_pkg::*;

module controller (
    input  instr_type_t  instr_type,
    input  logic [2:0]   funct3,
    input  logic [6:0]   funct7,

    output alu_op_t      alu_op,
    output alu_a_sel_t   alu_a_sel,
    output alu_b_sel_t   alu_b_sel,

    output imm_type_t    imm_type,

    output logic         reg_write,

    output logic         mem_read,
    output logic         mem_write,
    output mem_size_t    mem_size,
    output logic         mem_unsigned,

    output wb_sel_t      wb_sel,

    output logic         branch,
    output branch_type_t branch_type,
    output logic         jump
);

    // 子函数：从 funct3/funct7 译出 R 型 ALU 操作
    function automatic alu_op_t decode_r_op;
        input logic [2:0] f3;
        input logic [6:0] f7;
        case (f3)
            3'b000:  decode_r_op = f7[5] ? ALU_SUB : ALU_ADD;
            3'b001:  decode_r_op = ALU_SLL;
            3'b010:  decode_r_op = ALU_SLT;
            3'b011:  decode_r_op = ALU_SLTU;
            3'b100:  decode_r_op = ALU_XOR;
            3'b101:  decode_r_op = f7[5] ? ALU_SRA : ALU_SRL;
            3'b110:  decode_r_op = ALU_OR;
            default: decode_r_op = ALU_AND;   // 3'b111
        endcase
    endfunction

    // 子函数：从 funct3/funct7 译出 I 型(立即数) ALU 操作
    function automatic alu_op_t decode_i_op;
        input logic [2:0] f3;
        input logic [6:0] f7;
        case (f3)
            3'b000: decode_i_op = ALU_ADD;    // ADDI
            3'b010: decode_i_op = ALU_SLT;    // SLTI
            3'b011: decode_i_op = ALU_SLTU;   // SLTIU
            3'b100: decode_i_op = ALU_XOR;    // XORI
            3'b110: decode_i_op = ALU_OR;     // ORI
            3'b111: decode_i_op = ALU_AND;    // ANDI
            3'b001: decode_i_op = ALU_SLL;    // SLLI
            default:decode_i_op = f7[5] ? ALU_SRA : ALU_SRL; // SRAI / SRLI (f3=101)
        endcase
    endfunction

    always_comb begin
        // ---------- 默认值：保证任何分支下都有确定输出，杜绝锁存 ----------
        alu_op      = ALU_ADD;
        alu_a_sel   = ALU_A_RS1;
        alu_b_sel   = ALU_B_IMM;
        imm_type    = IMM_I;
        reg_write   = 1'b0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        mem_size    = MEM_WORD;
        mem_unsigned= 1'b0;
        wb_sel      = WB_ALU;
        branch      = 1'b0;
        branch_type = BR_EQ;
        jump        = 1'b0;

        case (instr_type)

            // ---------------- R-type ----------------
            INST_R: begin
                reg_write  = 1'b1;
                alu_b_sel  = ALU_B_RS2;
                alu_a_sel  = ALU_A_RS1;
                alu_op     = decode_r_op(funct3, funct7);
            end

            // ---------------- I-type (立即数 ALU 运算) ----------------
            INST_I: begin
                reg_write  = 1'b1;
                alu_b_sel  = ALU_B_IMM;       // imm_type 保持默认 IMM_I
                alu_a_sel  = ALU_A_RS1;
                alu_op     = decode_i_op(funct3, funct7);
            end

            // ---------------- Load ----------------
            INST_LOAD: begin
                reg_write   = 1'b1;
                mem_read    = 1'b1;
                mem_write   = 1'b0;
                mem_unsigned= 1'b0;
                wb_sel      = WB_MEM;         // 结果写回来自存储器
                alu_a_sel   = ALU_A_RS1;
                alu_b_sel   = ALU_B_IMM;      // 地址 = rs1 + imm
                alu_op      = ALU_ADD;
                imm_type    = IMM_I;
                case (funct3)
                    3'b000: mem_size = MEM_BYTE;            // LB
                    3'b001: mem_size = MEM_HALF;            // LH
                    3'b010: mem_size = MEM_WORD;            // LW
                    3'b100: begin mem_size = MEM_BYTE; mem_unsigned = 1'b1; end // LBU
                    3'b101: begin mem_size = MEM_HALF; mem_unsigned = 1'b1; end // LHU
                endcase
            end

            // ---------------- Store ----------------
            INST_STORE: begin
                reg_write  = 1'b0;             // 不写回
                mem_write  = 1'b1;
                mem_read   = 1'b0;
                alu_a_sel  = ALU_A_RS1;
                alu_b_sel  = ALU_B_IMM;        // 地址 = rs1 + imm
                alu_op     = ALU_ADD;
                imm_type   = IMM_S;
                case (funct3)
                    3'b000: mem_size = MEM_BYTE;            // SB
                    3'b001: mem_size = MEM_HALF;            // SH
                    3'b010: mem_size = MEM_WORD;            // SW
                endcase
                // mem_unsigned 对 store 无意义，保持默认 0
            end

            // ---------------- Branch ----------------
            INST_BRANCH: begin
                branch      = 1'b1;
                branch_type = branch_type_t'(funct3);   // 与 funct3 对齐
                alu_a_sel   = ALU_A_RS1;
                alu_b_sel   = ALU_B_RS2;        // ALU 只做比较
                imm_type    = IMM_B;            // 目标地址由 datapath 专用加法器 PC+imm 算
                case (branch_type)
                    BR_EQ, BR_NE:   alu_op = ALU_SUB;   // 看 zero 标志
                    BR_LT, BR_GE:   alu_op = ALU_SLT;   // 有符号小于
                    BR_LTU, BR_GEU: alu_op = ALU_SLTU;  // 无符号小于
                endcase
            end

            // ---------------- JAL ----------------
            INST_JAL: begin
                reg_write = 1'b1;
                wb_sel    = WB_PC4;            // rd 回写 PC+4 (link)
                jump      = 1'b1;
                alu_a_sel = ALU_A_PC;          // 目标 = PC + imm
                alu_b_sel = ALU_B_IMM;
                alu_op    = ALU_ADD;
                imm_type  = IMM_J;
            end

            // ---------------- JALR ----------------
            INST_JALR: begin
                reg_write = 1'b1;
                wb_sel    = WB_PC4;            // rd 回写 PC+4 (link)
                jump      = 1'b1;
                alu_a_sel = ALU_A_RS1;         // 目标 = rs1 + imm (I-type!)
                alu_b_sel = ALU_B_IMM;
                alu_op    = ALU_ADD;
                imm_type  = IMM_I;             // JALR 用 I 格式立即数
            end

            // ---------------- LUI ----------------
            INST_LUI: begin
                reg_write = 1'b1;
                alu_b_sel = ALU_B_IMM;
                alu_op    = ALU_COPY_B;        // 结果 = u_imm（已 <<12）
                imm_type  = IMM_U;
                // alu_a 无关，保持默认；wb_sel 默认 WB_ALU
            end

            // ---------------- AUIPC ----------------
            INST_AUIPC: begin
                reg_write = 1'b1;
                alu_a_sel = ALU_A_PC;
                alu_b_sel = ALU_B_IMM;
                alu_op    = ALU_ADD;           // 结果 = PC + imm
                imm_type  = IMM_U;
            end

            // ---------------- INVALID / others：什么都不做，走默认值 ----------------
            default: ;
        endcase
    end

endmodule