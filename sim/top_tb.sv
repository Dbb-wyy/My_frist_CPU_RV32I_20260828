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
        .PROGRAM_HEX("../../../../Test/test_C/test_bubble.hex")   // 相对路径，或使用绝对路径
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
        repeat (950000) @(posedge clk);

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
        // $monitor("t=%0t |rst=%b |pc=%h |instr=%h |x1=%h x2=%h x3=%h x4=%h x5=%h x6=%h x7=%h x8=%h x9=%h x10=%h x11=%h x12=%h x13=%h x14=%h x15=%h x16=%h x17=%h x18=%h x19=%h x20=%h x31=%h",
        $monitor("t=%0t |rst=%b |pc=%h |instr=%h |x1=%h x2=%h x3=%h x4=%h x10=%h x11=%h x12=%h x13=%h x31=%h",
                 $time,
                 rst,
                 u_top.pc,
                 u_top.instr,
//                 u_top.dmem_addr,
//                 u_top.dmem_wdata,
//                 u_top.dmem_we,
//                 u_top.dmem_be,
                 u_top.u_cpu.u_datapath.u_regfile.regs[1],
                 u_top.u_cpu.u_datapath.u_regfile.regs[2],
                 u_top.u_cpu.u_datapath.u_regfile.regs[3],
                 u_top.u_cpu.u_datapath.u_regfile.regs[4],
                //  u_top.u_cpu.u_datapath.u_regfile.regs[5],
                //  u_top.u_cpu.u_datapath.u_regfile.regs[6],
                //  u_top.u_cpu.u_datapath.u_regfile.regs[7],
                //  u_top.u_cpu.u_datapath.u_regfile.regs[8],
                //  u_top.u_cpu.u_datapath.u_regfile.regs[9],
                 u_top.u_cpu.u_datapath.u_regfile.regs[10],
                 u_top.u_cpu.u_datapath.u_regfile.regs[11],
                 u_top.u_cpu.u_datapath.u_regfile.regs[12],
                 u_top.u_cpu.u_datapath.u_regfile.regs[13],
                //  u_top.u_cpu.u_datapath.u_regfile.regs[14],
                //  u_top.u_cpu.u_datapath.u_regfile.regs[15],
                //  u_top.u_cpu.u_datapath.u_regfile.regs[16],
                //  u_top.u_cpu.u_datapath.u_regfile.regs[17],
                //  u_top.u_cpu.u_datapath.u_regfile.regs[18],
                //  u_top.u_cpu.u_datapath.u_regfile.regs[19],
                //  u_top.u_cpu.u_datapath.u_regfile.regs[20],
                 u_top.u_cpu.u_datapath.u_regfile.regs[31]);
    end

endmodule