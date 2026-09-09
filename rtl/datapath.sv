`timescale 1ns / 1ps
import cpu_pkg::*;
module datapath (
    //==========================================================
    // Clock / Reset
    //==========================================================
    input logic clk,
    input logic rst,

    //==========================================================
    // Instruction
    //==========================================================
    input  logic [31:0] instr,
    output logic [31:0] pc,

    //==========================================================
    // Register file fields
    // 由 decoder 提供
    //==========================================================
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] rd,

    //==========================================================
    // ALU control
    // 由 controller 提供
    //==========================================================
    input alu_op_t    alu_op,
    input alu_a_sel_t alu_a_sel,
    input alu_b_sel_t alu_b_sel,

    //==========================================================
    // Immediate control
    //==========================================================
    input imm_type_t imm_type,

    //==========================================================
    // Register write-back
    //==========================================================
    input logic    reg_write,
    input wb_sel_t wb_sel,

    //==========================================================
    // Branch / Jump
    //==========================================================
    input logic         branch,
    input branch_type_t branch_type,
    input logic         jump,

    //==========================================================
    // Data memory control
    //==========================================================
    input logic      mem_read,
    input logic      mem_write,
    input mem_size_t mem_size,
    input logic      mem_unsigned,

    //==========================================================
    // Data memory interface
    //==========================================================
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    input  logic [31:0] dmem_rdata,
    output logic        dmem_we,
    output logic [ 3:0] dmem_be
);

    //==========================================================
    // Internal signals
    //==========================================================
    // ---------- PC ----------
    logic [31:0] pc_next;
    logic [31:0] pc_plus_4;

    // ---------- Immediate ----------
    logic [31:0] imm;

    // ---------- Register file ----------
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    // ---------- ALU ----------
    logic [31:0] alu_a;
    logic [31:0] alu_b;
    logic [31:0] alu_result;
    logic        alu_zero;

    // ---------- Branch / Jump ----------
    logic [31:0] branch_target;
    logic [31:0] jal_target;
    logic [31:0] jalr_target;
    logic        branch_taken;

    // ---------- Memory ----------
    logic [31:0] load_data;

    // ---------- Write back ----------
    logic [31:0] wb_data;

    //==========================================================
    // PC
    //==========================================================
    pc u_pc (
        .clk    (clk),
        .rst    (rst),
        .next_pc(pc_next),
        .pc     (pc)
    );
    assign pc_plus_4 = pc + 32'd4;

    //==========================================================
    // Immediate Generator
    //==========================================================
    imm_gen u_imm_gen (
        .inst    (instr),
        .imm_type(imm_type),
        .imm     (imm)
    );

    //==========================================================
    // Register File
    //==========================================================
    regfile u_regfile (
        .clk     (clk),
        .we      (reg_write),
        .rs1     (rs1),
        .rs2     (rs2),
        .rd      (rd),
        .wd      (wb_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    //==========================================================
    // ALU input MUX
    // A:
    //   ALU_A_RS1 -> rs1
    //   ALU_A_PC  -> PC
    // B:
    //   ALU_B_RS2 -> rs2
    //   ALU_B_IMM -> immediate
    //==========================================================
    always_comb begin
        case (alu_a_sel)
            ALU_A_RS1: alu_a = rs1_data;
            ALU_A_PC:  alu_a = pc;
            default:   alu_a = 32'b0;
        endcase
    end
    always_comb begin
        case (alu_b_sel)
            ALU_B_RS2: alu_b = rs2_data;
            ALU_B_IMM: alu_b = imm;
            default:   alu_b = 32'b0;
        endcase
    end

    //==========================================================
    // ALU
    //==========================================================
    alu u_alu (
        .a     (alu_a),
        .b     (alu_b),
        .alu_op(alu_op),
        .result(alu_result),
        .zero  (alu_zero)
    );

    //==========================================================
    // Branch comparator
    // 不用ALU的zero/slt结果。
    //==========================================================
    always_comb begin
        branch_taken = 1'b0;
        if (branch) begin
            case (branch_type)
                BR_EQ: branch_taken = (rs1_data == rs2_data);
                BR_NE: branch_taken = (rs1_data != rs2_data);
                BR_LT: branch_taken = ($signed(rs1_data) < $signed(rs2_data));
                BR_GE: branch_taken = ($signed(rs1_data) >= $signed(rs2_data));
                BR_LTU: branch_taken = (rs1_data < rs2_data);
                BR_GEU: branch_taken = (rs1_data >= rs2_data);
                default: branch_taken = 1'b0;
            endcase
        end
    end

    //==========================================================
    // Branch / Jump targets
    //==========================================================
    // Branch target:
    //     PC + B-immediate
    // JAL target:
    //     PC + J-immediate
    // JALR target:
    //     (rs1 + I-immediate) & ~1
    // imm 具体格式已经由controller->imm_gen决定。
    assign branch_target = pc + imm;
    assign jal_target = pc + imm;
    assign jalr_target = (rs1_data + imm) & 32'hFFFF_FFFE;

    //==========================================================
    // Next PC
    // Priority:
    //     JAL/JALR
    //     Branch taken
    //     PC + 4
    //==========================================================
    always_comb begin
        pc_next = pc_plus_4;
        if (jump) begin
            if (alu_a_sel == ALU_A_RS1) begin
                // JALR
                pc_next = jalr_target;
            end else begin
                // JAL
                pc_next = jal_target;
            end
        end else if (branch && branch_taken) begin
            pc_next = branch_target;
        end
    end

    //==========================================================
    // Data Memory Interface
    // CPU 使用 byte-addressed memory。
    // dmem_addr:
    //     ALU result = rs1 + immediate
    // dmem_wdata:
    //     对 SB / SH 根据地址低位进行 byte lane 对齐
    // dmem_be:
    //     byte enable
    //==========================================================
    assign dmem_addr = alu_result;
    assign dmem_we   = mem_write;
    always_comb begin
        dmem_wdata = 32'b0;
        dmem_be    = 4'b0000;
        if (mem_write) begin
            case (mem_size)
                //==================================================
                // SB
                //==================================================
                MEM_BYTE: begin
                    case (alu_result[1:0])
                        2'b00: begin
                            dmem_wdata = {24'b0, rs2_data[7:0]};
                            dmem_be    = 4'b0001;
                        end
                        2'b01: begin
                            dmem_wdata = {16'b0, rs2_data[7:0], 8'b0};
                            dmem_be    = 4'b0010;
                        end
                        2'b10: begin
                            dmem_wdata = {8'b0, rs2_data[7:0], 16'b0};
                            dmem_be    = 4'b0100;
                        end
                        2'b11: begin
                            dmem_wdata = {rs2_data[7:0], 24'b0};
                            dmem_be    = 4'b1000;
                        end
                        default: begin
                            dmem_wdata = 32'b0;
                            dmem_be    = 4'b0000;
                        end
                    endcase
                end

                //==================================================
                // SH
                // RV32I 的半字访问要求自然对齐。
                // addr[0] == 0 时有效。
                //==================================================
                MEM_HALF: begin
                    if (alu_result[0] == 1'b0) begin
                        case (alu_result[1])
                            1'b0: begin
                                dmem_wdata = {16'b0, rs2_data[15:0]};
                                dmem_be    = 4'b0011;
                            end
                            1'b1: begin
                                dmem_wdata = {rs2_data[15:0], 16'b0};
                                dmem_be    = 4'b1100;
                            end
                            default: begin
                                dmem_wdata = 32'b0;
                                dmem_be    = 4'b0000;
                            end
                        endcase
                    end
                end

                //==================================================
                // SW
                //==================================================
                MEM_WORD: begin
                    // 当前版本只支持自然对齐 word store
                    if (alu_result[1:0] == 2'b00) begin
                        dmem_wdata = rs2_data;
                        dmem_be    = 4'b1111;
                    end
                end

                default: begin
                    dmem_wdata = 32'b0;
                    dmem_be    = 4'b0000;
                end
            endcase
        end
    end

    //==========================================================
    // Load Data Extraction / Extension
    // RAM 返回一个完整 32-bit word。
    // 根据 dmem_addr 选择其中的 byte / halfword。
    // LB/LH  -> sign extend
    // LBU/LHU -> zero extend
    // LW     -> 直接返回 32 bit
    //==========================================================
    always_comb begin
        load_data = 32'b0;
        if (mem_read) begin
            case (mem_size)
                //==================================================
                // LB / LBU
                //==================================================
                MEM_BYTE: begin
                    case (dmem_addr[1:0])
                        2'b00: begin
                            if (mem_unsigned) load_data = {24'b0, dmem_rdata[7:0]};
                            else load_data = {{24{dmem_rdata[7]}}, dmem_rdata[7:0]};
                        end
                        2'b01: begin
                            if (mem_unsigned) load_data = {24'b0, dmem_rdata[15:8]};
                            else load_data = {{24{dmem_rdata[15]}}, dmem_rdata[15:8]};
                        end
                        2'b10: begin
                            if (mem_unsigned) load_data = {24'b0, dmem_rdata[23:16]};
                            else load_data = {{24{dmem_rdata[23]}}, dmem_rdata[23:16]};
                        end
                        2'b11: begin
                            if (mem_unsigned) load_data = {24'b0, dmem_rdata[31:24]};
                            else load_data = {{24{dmem_rdata[31]}}, dmem_rdata[31:24]};
                        end
                        default: load_data = 32'b0;
                    endcase
                end

                //==================================================
                // LH / LHU
                // 自然对齐 halfword：
                // addr[1:0] = 00 -> low half
                // addr[1:0] = 10 -> high half
                //==================================================
                MEM_HALF: begin
                    case (dmem_addr[1:0])
                        2'b00: begin
                            if (mem_unsigned) load_data = {16'b0, dmem_rdata[15:0]};
                            else load_data = {{16{dmem_rdata[15]}}, dmem_rdata[15:0]};
                        end
                        2'b10: begin
                            if (mem_unsigned) load_data = {16'b0, dmem_rdata[31:16]};
                            else load_data = {{16{dmem_rdata[31]}}, dmem_rdata[31:16]};
                        end
                        default: load_data = 32'b0;
                    endcase
                end

                //==================================================
                // LW
                //==================================================
                MEM_WORD: begin
                    if (dmem_addr[1:0] == 2'b00) load_data = dmem_rdata;
                    else load_data = 32'b0;
                end
                default: begin
                    load_data = 32'b0;
                end
            endcase
        end
    end

    //==========================================================
    // Write Back MUX
    // WB_ALU  -> ALU result
    // WB_MEM  -> Load data
    // WB_PC4  -> PC + 4
    //==========================================================
    always_comb begin
        case (wb_sel)
            WB_ALU: wb_data = alu_result;
            WB_MEM: wb_data = load_data;
            WB_PC4: wb_data = pc_plus_4;
            default: wb_data = 32'b0;
        endcase
    end
endmodule
