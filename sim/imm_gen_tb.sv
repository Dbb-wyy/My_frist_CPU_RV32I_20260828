`timescale 1ns / 1ps

import cpu_pkg::*;

module imm_gen_tb;

    // ---- 信号声明 ----
    logic [31:0] inst;
    imm_type_t   imm_type;
    logic [31:0] imm;

    // ---- 例化被测模块 ----
    imm_gen uut (
        .inst     (inst),
        .imm_type (imm_type),
        .imm      (imm)
    );

    // ---- 测试统计 ----
    int pass_count = 0;
    int fail_count = 0;

    task automatic check(
        input string test_name,
        ref logic [31:0] actual,
        input logic [31:0] expected
    );
        #5;
        if (actual === expected) begin
            pass_count++;
            $display("[PASS] %s: got %h", test_name, actual);
        end else begin
            fail_count++;
            $display("[FAIL] %s: got %h, expected %h", test_name, actual, expected);
        end
    endtask

    // ---- 主测试流程 ----
    initial begin
        $display("========== Immediate Generator Testbench Start ==========");

        // ========================================
        // I-Type 立即数测试
        // ========================================
        // 正数：0x123 << 20 | 0x00000013 (ADDI x0, x0, 0x123)
        inst = 32'h12300013;
        imm_type = IMM_I;
        check("I-type positive (0x123)", imm, 32'h00000123);

        // 负数：-1 (0xFFF)
        inst = 32'hFFF00013;
        imm_type = IMM_I;
        check("I-type negative (-1)", imm, 32'hFFFFFFFF);

        // 边界值：最大正数 0x7FF
        inst = 32'h7FF00013;
        imm_type = IMM_I;
        check("I-type max positive (0x7FF)", imm, 32'h000007FF);

        // 边界值：最小负数 0x800
        inst = 32'h80000013;
        imm_type = IMM_I;
        check("I-type min negative (0x800)", imm, 32'hFFFFF800);

        // ========================================
        // S-Type 立即数测试
        // ========================================
        // 正数：0x123 (SW x0, 0x123(x0))
        inst = 32'h120021A3;
        imm_type = IMM_S;
        check("S-type positive (0x123)", imm, 32'h00000123);

        // 负数：-1 (0xFFF)
        inst = 32'hFE002FA3;
        imm_type = IMM_S;
        check("S-type negative (-1)", imm, 32'hFFFFFFFF);

        // 边界值：最大正数 0x7FF
        inst = 32'h7E002FA3;
        imm_type = IMM_S;
        check("S-type max positive (0x7FF)", imm, 32'h000007FF);

        // 边界值：最小负数 0x800
        inst = 32'h80000023;
        imm_type = IMM_S;
        check("S-type min negative (0x800)", imm, 32'hFFFFF800);

        // ========================================
        // B-Type 立即数测试
        // ========================================
        // 正数：+4 (BEQ x0, x0, +4)
        inst = 32'h00000263;
        imm_type = IMM_B;
        check("B-type +4", imm, 32'h00000004);

        // 负数：-4 (BEQ x0, x0, -4)
        inst = 32'hFE000EE3;
        imm_type = IMM_B;
        check("B-type -4", imm, 32'hFFFFFFFC);

        // 边界值：最大正偏移 +4094
        inst = 32'h7E000FE3;
        imm_type = IMM_B;
        check("B-type max positive (+4094)", imm, 32'h00000FFE);

        // 边界值：最小负偏移 -4096
        inst = 32'h80000063;
        imm_type = IMM_B;
        check("B-type min negative (-4096)", imm, 32'hFFFFF000);

        // ========================================
        // U-Type 立即数测试
        // ========================================
        // LUI x0, 0x12345
        inst = 32'h12345037;
        imm_type = IMM_U;
        check("U-type 0x12345000", imm, 32'h12345000);

        // LUI x0, 0xFFFFF
        inst = 32'hFFFFF037;
        imm_type = IMM_U;
        check("U-type 0xFFFFF000", imm, 32'hFFFFF000);

        // LUI x0, 0x00000
        inst = 32'h00000037;
        imm_type = IMM_U;
        check("U-type 0x00000000", imm, 32'h00000000);

        // LUI x0, 0x80000
        inst = 32'h80000037;
        imm_type = IMM_U;
        check("U-type 0x80000000", imm, 32'h80000000);

        // ========================================
        // J-Type 立即数测试
        // ========================================
        // 正数：+4 (JAL x0, +4)
        inst = 32'h0040006F;
        imm_type = IMM_J;
        check("J-type +4", imm, 32'h00000004);

        // 负数：-4 (JAL x0, -4)
        inst = 32'hFFDFF0EF;
        imm_type = IMM_J;
        check("J-type -4", imm, 32'hFFFFFFFC);

        // 边界值：最大正偏移 +1048574
        inst = 32'h7FFFF06F;
        imm_type = IMM_J;
        check("J-type max positive (+1048574)", imm, 32'h000FFFFE);

        // 边界值：最小负偏移 -1048576
        inst = 32'h8000006F;
        imm_type = IMM_J;
        check("J-type min negative (-1048576)", imm, 32'hFFF00000);

        // ========================================
        // 非法操作码测试
        // ========================================
        inst = 32'h12345678;
        imm_type = imm_type_t'(5'd31);  // 非法类型
        check("Illegal imm_type", imm, 32'h00000000);

        // ========================================
        // 汇总
        // ========================================
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