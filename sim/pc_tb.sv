`timescale 1ns / 1ps

module pc_tb;

    // 信号声明
    logic        clk;
    logic        rst;
    logic [31:0] next_pc;
    logic [31:0] pc;

    // 被测模块实例化
    pc u_pc (
        .clk     (clk),
        .rst     (rst),
        .next_pc (next_pc),
        .pc      (pc)
    );

    // 时钟生成：周期 10ns
    initial clk = 0;
    always #5 clk = ~clk;

    // 测试任务
    task check_pc(input logic [31:0] expected, input string msg);
        if (pc === expected) begin
            $display("[PASS] %s, pc = %h", msg, pc);
        end else begin
            $error("[FAIL] %s, expected pc = %h, actual pc = %h", msg, expected, pc);
        end
    endtask

    // 测试流程
    initial begin
        // 初始化
        rst     = 1;
        next_pc = 32'hDEAD_BEEF;

        // 等待复位结束
        @(posedge clk);
        #1;
        check_pc(32'h0000_0000, "reset value");

        // 释放复位
        @(negedge clk);
        rst = 0;

        // 测试正常加载 next_pc
        next_pc = 32'h0000_0004;
        @(posedge clk);
        #1;
        check_pc(32'h0000_0004, "load next_pc = 0x4");

        next_pc = 32'h0000_0008;
        @(posedge clk);
        #1;
        check_pc(32'h0000_0008, "load next_pc = 0x8");

        // 测试随机值
        next_pc = 32'hABCD_1234;
        @(posedge clk);
        #1;
        check_pc(32'hABCD_1234, "load next_pc = 0xABCD1234");

        // 测试复位优先级：即使 next_pc 有值，复位后 pc 应为 0
        next_pc = 32'hFFFF_FFFF;
        rst = 1;
        @(posedge clk);
        #1;
        check_pc(32'h0000_0000, "reset while next_pc is non-zero");

        // 复位后再次正常工作
        @(negedge clk);
        rst = 0;
        next_pc = 32'h0000_1000;
        @(posedge clk);
        #1;
        check_pc(32'h0000_1000, "load after reset = 0x1000");

        $display("--- Testbench finished ---");
        $finish;
    end

    // 超时保护
    initial begin
        #1000;
        $display("--- Timeout ---");
        $finish;
    end

    // 波形输出（仿真时可用）
    initial begin
        $dumpfile("pc_tb.vcd");
        $dumpvars(0, pc_tb);
    end

endmodule