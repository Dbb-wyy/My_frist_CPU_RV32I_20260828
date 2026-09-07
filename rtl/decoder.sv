module decoder
    import cpu_pkg::*;
(
    input  logic [31:0] inst,

    output logic [4:0]  rs1,
    output logic [4:0]  rs2,
    output logic [4:0]  rd,

    output logic [6:0]  opcode,
    output logic [2:0]  funct3,
    output logic [6:0]  funct7,

    output instr_type_t instr_type
);

    // 从指令中直接提取字段
    assign opcode = inst[6:0];
    assign rd     = inst[11:7];
    assign funct3 = inst[14:12];
    assign rs1    = inst[19:15];
    assign rs2    = inst[24:20];
    assign funct7 = inst[31:25];

    // 根据 opcode 判断指令大类
    always_comb begin
        case (opcode)

            7'b0110011:
                instr_type = INST_R;

            7'b0010011:
                instr_type = INST_I;

            7'b0000011:
                instr_type = INST_LOAD;

            7'b0100011:
                instr_type = INST_STORE;

            7'b1100011:
                instr_type = INST_BRANCH;

            7'b1101111:
                instr_type = INST_JAL;

            7'b1100111:
                instr_type = INST_JALR;

            7'b0110111:
                instr_type = INST_LUI;

            7'b0010111:
                instr_type = INST_AUIPC;

            default:
                instr_type = INST_INVALID;

        endcase
    end

endmodule