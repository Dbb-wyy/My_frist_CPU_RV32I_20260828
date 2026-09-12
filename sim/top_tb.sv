`timescale 1ns / 1ps

module top_tb;

    //==========================================================
    // 时钟 / 复位
    //==========================================================
    logic clk;
    logic rst;

    //==========================================================
    // DUT：被测顶层
    //==========================================================
    top #(
        .PROGRAM_HEX("../../../../Test/program2.hex")   // 相对路径，或使用绝对路径
    ) u_top (
        .clk (clk),
        .rst (rst)
    );

    //==========================================================
    // 时钟：周期 10ns
    //==========================================================
    initial clk = 1'b0;
    always #5 clk = ~clk;

    //==========================================================
    // 复位 + 运行
    //==========================================================
    initial begin
        // 初始复位
        rst = 1'b1;

        // 保持复位 2 个时钟沿，让 PC 稳定复位到 0
        repeat (2) @(posedge clk);

        // 释放复位，CPU 从 PC=0 开始执行
        rst = 1'b0;

        // 让程序跑足够多的周期
        repeat (6) @(posedge clk);

        $display("========================================");
        $display("Simulation finished at time %0t", $time);
        $display("========================================");
        $finish;
    end

    //==========================================================
    // 波形/打印监视
    // 通过层次路径观察内部寄存器堆 x1~x4
    //==========================================================
    initial begin
        $monitor("t=%0t | rst=%b | pc=%h | instr=%h | daddr=%h | dwdata=%h | dwe=%b | dbe=%b | x1=%h x2=%h x3=%h x4=%h",
                 $time,
                 rst,
                 u_top.pc,
                 u_top.instr,
                 u_top.dmem_addr,
                 u_top.dmem_wdata,
                 u_top.dmem_we,
                 u_top.dmem_be,
                 u_top.u_cpu.u_datapath.u_regfile.regs[1],
                 u_top.u_cpu.u_datapath.u_regfile.regs[2],
                 u_top.u_cpu.u_datapath.u_regfile.regs[3],
                 u_top.u_cpu.u_datapath.u_regfile.regs[4]);
    end

endmodule