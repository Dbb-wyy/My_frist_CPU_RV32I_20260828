import cpu_pkg::*;

module alu (
    input logic [31:0] a,
    input logic [31:0] b,

    input logic [4:0] alu_op,

    output logic [31:0] result,
    output logic        zero
);

    always_comb begin
        // 默认值，避免综合出锁存器
        result = 32'b0;

        case (alu_op)

            // A + B
            ALU_ADD: begin
                result = a + b;
            end

            // A - B
            ALU_SUB: begin
                result = a - b;
            end

            // 按位与
            ALU_AND: begin
                result = a & b;
            end

            // 按位或
            ALU_OR: begin
                result = a | b;
            end

            // 按位异或
            ALU_XOR: begin
                result = a ^ b;
            end

            // 逻辑左移
            ALU_SLL: begin
                result = a << b[4:0];
            end

            // 逻辑右移
            ALU_SRL: begin
                result = a >> b[4:0];
            end

            // 算术右移
            ALU_SRA: begin
                result = $signed(a) >>> b[4:0];
            end

            // 有符号小于
            ALU_SLT: begin
                result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            end

            // 无符号小于
            ALU_SLTU: begin
                result = (a < b) ? 32'd1 : 32'd0;
            end

            // 直接输出 A
            ALU_COPY_A: begin
                result = a;
            end

            // 直接输出 B
            ALU_COPY_B: begin
                result = b;
            end

            // 非法操作码
            default: begin
                result = 32'b0;
            end

        endcase
    end

    // result == 0 时，zero = 1
    assign zero = (result == 32'b0);

endmodule

