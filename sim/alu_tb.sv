`timescale 1ns / 1ps

import cpu_pkg::*;
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2026 10:49:59 PM
// Design Name: 
// Module Name: alu_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module alu_tb;

    // 信号声明
    logic [31:0] a;
    logic [31:0] b;
    logic [4:0]  alu_op;
    logic [31:0] result;
    logic        zero;

    // 例化被测模块
    alu uut (
        .a       (a),
        .b       (b),
        .alu_op  (alu_op),
        .result  (result),
        .zero    (zero)
    );

    // 测试统计
    int pass_count = 0;
    int fail_count = 0;

    // 检查任务
    task automatic check(
        input string op_name,
        input logic [31:0] expected
    );
        #5; // 等待组合逻辑稳定
        if (result === expected) begin
            pass_count++;
            $display("[PASS] %s: a=%h, b=%h => result=%h", op_name, a, b, result);
        end else begin
            fail_count++;
            $display("[FAIL] %s: a=%h, b=%h => result=%h, expected=%h",
                     op_name, a, b, result, expected);
        end
    endtask

    // 主测试流程
    initial begin
        $display("========== ALU Testbench Start ==========");

        // ---- ADD ----
        a = 32'd5; b = 32'd3; alu_op = ALU_ADD;
        check("ADD", 32'd8);

        // ---- SUB ----
        a = 32'd10; b = 32'd4; alu_op = ALU_SUB;
        check("SUB", 32'd6);

        // ---- AND ----
        a = 32'hFF00FF00; b = 32'h0F0F0F0F; alu_op = ALU_AND;
        check("AND", 32'h0F000F00);

        // ---- OR ----
        a = 32'hFF00FF00; b = 32'h0F0F0F0F; alu_op = ALU_OR;
        check("OR", 32'hFF0FFF0F);

        // ---- XOR ----
        a = 32'hFF00FF00; b = 32'h0F0F0F0F; alu_op = ALU_XOR;
        check("XOR", 32'hF00FF00F);

        // ---- SLL ----
        a = 32'h00000001; b = 32'd4; alu_op = ALU_SLL;
        check("SLL", 32'h00000010);

        // ---- SRL ----
        a = 32'h80000000; b = 32'd4; alu_op = ALU_SRL;
        check("SRL", 32'h08000000);

        // ---- SRA (算术右移，保留符号位) ----
        a = 32'h80000000; b = 32'd4; alu_op = ALU_SRA;
        check("SRA", 32'hF8000000);

        // ---- SLT (有符号比较，-1 < 1) ----
        a = 32'hFFFFFFFF; b = 32'd1; alu_op = ALU_SLT;
        check("SLT", 32'd1);

        // ---- SLTU (无符号比较，0xFFFFFFFF > 1) ----
        a = 32'hFFFFFFFF; b = 32'd1; alu_op = ALU_SLTU;
        check("SLTU", 32'd0);

        // ---- COPY_A ----
        a = 32'hDEADBEEF; b = 32'd0; alu_op = ALU_COPY_A;
        check("COPY_A", 32'hDEADBEEF);

        // ---- COPY_B ----
        a = 32'd0; b = 32'hCAFEBABE; alu_op = ALU_COPY_B;
        check("COPY_B", 32'hCAFEBABE);

        // ---- zero 标志测试 ----
        a = 32'd0; b = 32'd0; alu_op = ALU_ADD;
        #5;
        if (zero === 1'b1) begin
            pass_count++;
            $display("[PASS] ZERO flag: result=0, zero=%b", zero);
        end else begin
            fail_count++;
            $display("[FAIL] ZERO flag: result=0, zero=%b, expected 1", zero);
        end

        // ---- zero 标志为 0 的情况 ----
        a = 32'd1; b = 32'd1; alu_op = ALU_ADD;
        #5;
        if (zero === 1'b0) begin
            pass_count++;
            $display("[PASS] ZERO flag: result=2, zero=%b", zero);
        end else begin
            fail_count++;
            $display("[FAIL] ZERO flag: result=2, zero=%b, expected 0", zero);
        end

        // ---- 边界值测试：溢出 ----
        a = 32'h7FFFFFFF; b = 32'd1; alu_op = ALU_ADD;
        check("ADD overflow", 32'h80000000);

        // ---- 边界值测试：SUB 结果为负 ----
        a = 32'd0; b = 32'd1; alu_op = ALU_SUB;
        check("SUB negative", 32'hFFFFFFFF);

        // ---- 非法操作码 ----
        a = 32'h12345678; b = 32'h87654321; alu_op = 5'b11111;
        check("ILLEGAL op", 32'd0);

        // 汇总
        $display("==========================================");
        $display("  Total: %0d  PASS: %0d  FAIL: %0d",
                 pass_count + fail_count, pass_count, fail_count);
        if (fail_count == 0)
            $display("  *** ALL TESTS PASSED ***");
        else
            $display("  *** SOME TESTS FAILED ***");
        $display("==========================================");

        $finish;
    end

endmodule
