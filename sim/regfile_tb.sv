`timescale 1ns / 1ps

module regfile_tb;

    // ---- 信号声明 ----
    logic        clk;
    logic        we;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;
    logic [31:0] wd;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    // ---- 时钟生成：10ns 周期 ----
    initial clk = 0;
    always #5 clk = ~clk;

    // ---- 例化被测模块 ----
    regfile uut (
        .clk      (clk),
        .we       (we),
        .rs1      (rs1),
        .rs2      (rs2),
        .rd       (rd),
        .wd       (wd),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data)
    );

    // ---- 测试统计 ----
    int pass_count = 0;
    int fail_count = 0;

    task automatic check(
        input string test_name,
        input logic [31:0] actual,
        input logic [31:0] expected
    );
        if (actual === expected) begin
            pass_count++;
            $display("[PASS] %s: got %h", test_name, actual);
        end else begin
            fail_count++;
            $display("[FAIL] %s: got %h, expected %h", test_name, actual, expected);
        end
    endtask


    initial begin
        
        // 初始化信号
        we   = 1'b0;
        rs1  = 5'd0;
        rs2  = 5'd0;
        rd   = 5'd0;
        wd   = 32'd0;

        // 等待复位稳定
        @(posedge clk);
        @(posedge clk);
     
        $display("========== RegFile Testbench Start ==========");

        // ========================================
        // Test 1: x0 读恒为 0（未写入任何值时）
        // ========================================
        rs1 = 5'd0;
        rs2 = 5'd0;
        #1;
        check("x0 read before write (rs1)", rs1_data, 32'd0);
        check("x0 read before write (rs2)", rs2_data, 32'd0);

        // ========================================
        // Test 2: 写入 x0 应被忽略
        // ========================================
        @(posedge clk);
        we = 1'b1;
        rd = 5'd0;
        wd = 32'hDEADBEEF;
        @(posedge clk);  // 等待写入生效
        we = 1'b0;
        rs1 = 5'd0;
        #1;
        check("x0 write should be ignored", rs1_data, 32'd0);

        // ========================================
        // Test 3: 正常写入 x1 并读出
        // ========================================
        @(posedge clk);
        we = 1'b1;
        rd = 5'd1;
        wd = 32'h12345678;
        @(posedge clk);
        we = 1'b0;
        rs1 = 5'd1;
        #1;
        check("x1 write & read", rs1_data, 32'h12345678);

        // ========================================
        // Test 4: 正常写入 x15 并读出
        // ========================================
        @(posedge clk);
        we = 1'b1;
        rd = 5'd15;
        wd = 32'hA5A5A5A5;
        @(posedge clk);
        we = 1'b0;
        rs1 = 5'd15;
        #1;
        check("x15 write & read", rs1_data, 32'hA5A5A5A5);

        // ========================================
        // Test 5: 双端口同时读
        // ========================================
        // 先写入 x2
        @(posedge clk);
        we = 1'b1;
        rd = 5'd2;
        wd = 32'hCAFEBABE;
        @(posedge clk);
        we = 1'b0;

        rs1 = 5'd1;  // x1 = 0x12345678
        rs2 = 5'd2;  // x2 = 0xCAFEBABE
        #1;
        check("dual read port1 (x1)", rs1_data, 32'h12345678);
        check("dual read port2 (x2)", rs2_data, 32'hCAFEBABE);

        // ========================================
        // Test 6: we=0 时写入不应生效
        // ========================================
        // 先写入 x3 一个已知值
        @(posedge clk);
        we = 1'b1;
        rd = 5'd3;
        wd = 32'hAAAA5555;
        @(posedge clk);
        we = 1'b0;
        
        // 尝试在 we=0 时写入新值
        @(posedge clk);
        we = 1'b0;
        rd = 5'd3;
        wd = 32'hFFFFFFFF;
        @(posedge clk);
        rs1 = 5'd3;
        #1;
        check("write disabled, x3 keeps old value", rs1_data, 32'hAAAA5555);
    
        // ========================================
        // Test 7: 覆盖写入（写两次同一寄存器）
        // ========================================
        @(posedge clk);
        we = 1'b1;
        rd = 5'd4;
        wd = 32'h11111111;
        @(posedge clk);
        wd = 32'h22222222;  // 覆盖写入
        @(posedge clk);
        we = 1'b0;
        rs1 = 5'd4;
        #1;
        check("x4 overwrite", rs1_data, 32'h22222222);

        // ========================================
        // Test 8: 边界值写入（全 1 和全 0）
        // ========================================
        @(posedge clk);
        we = 1'b1;
        rd = 5'd5;
        wd = 32'hFFFFFFFF;
        @(posedge clk);
        rd = 5'd6;
        wd = 32'h00000000;
        @(posedge clk);
        we = 1'b0;

        rs1 = 5'd5;
        rs2 = 5'd6;
        #1;
        check("x5 all ones", rs1_data, 32'hFFFFFFFF);
        check("x6 all zeros", rs2_data, 32'h00000000);

        // ========================================
        // Test 9: 读未初始化的寄存器应为 X
        // ========================================
        rs1 = 5'd31;  // x31 从未写入
        #1;
        if ($isunknown(rs1_data)) begin
            pass_count++;
            $display("[PASS] x31 uninitialized read is X");
        end else begin
            fail_count++;
            $display("[FAIL] x31 uninitialized read: got %h, expected X", rs1_data);
        end

        // ========================================
        // Test 10: 写后立即读同一寄存器（同周期）
        // ========================================
        @(posedge clk);
        we = 1'b1;
        rd = 5'd7;
        wd = 32'hABCDEF01;
        rs1 = 5'd7;  
        @(posedge clk);
        we = 1'b0;
        #1;
        check("x7 write-then-read", rs1_data, 32'hABCDEF01);

        // ========================================
        // Test 11: 连续写入多个寄存器后批量读出
        // ========================================
        @(posedge clk);
        we = 1'b1;
        for (int i = 8; i < 16; i++) begin
            rd = i[4:0];
            wd = i * 32'd100;
            @(posedge clk);
        end
        we = 1'b0;

        for (int i = 8; i < 16; i++) begin
            rs1 = i[4:0];
            #1;
            check($sformatf("x%0d batch read", i), rs1_data, i * 32'd100);
        end

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