module imm_gen
    import cpu_pkg::*;
(
    input logic [31:0] inst,
    input imm_type_t imm_type,
    output logic [31:0] imm
);

    logic [31:0] i_imm;
    logic [31:0] s_imm;
    logic [31:0] b_imm;
    logic [31:0] u_imm;
    logic [31:0] j_imm;

    assign i_imm = {{20{inst[31]}}, inst[31:20]};

    assign s_imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};

    assign b_imm = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};

    assign u_imm = {inst[31:12], 12'b0};

    assign j_imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};

    always_comb begin
        case (imm_type)  //定义于cpu_pkg.sv
            IMM_I: imm = i_imm;
            IMM_S: imm = s_imm;
            IMM_B: imm = b_imm;
            IMM_U: imm = u_imm;
            IMM_J: imm = j_imm;

            default: imm = 32'b0;
        endcase
    end

endmodule

