`timescale 1ns / 1ps

module rom #(
    // 指令条数：8KB / 4B = 2048 条
    parameter int  DEPTH    = 2048,
    // 初始化文件，由仿真/综合时指定
    parameter string HEX_FILE = ("/home/dbb/Workspace/FPGA/My_frist_CPU_RV32I_20260828/program.hex")
) (
    input  logic [31:0] addr,    // 字节地址，通常接 PC
    output logic [31:0] instr    // 读出的 32 位指令
);

    localparam int AW = $clog2(DEPTH);   // DEPTH=2048 -> AW=11

    logic [31:0] mem [0:DEPTH-1];

    //----------------------------------------------------------
    // 上电/仿真初始化：
    // 1. 先全部清零（0x00000000 是 add x0,x0,x0，近似无害 NOP）
    // 2. 再用 hex 文件覆盖实际指令区
    //----------------------------------------------------------
    initial begin
        for (int i = 0; i < DEPTH; i++)
            mem[i] = 32'h0000_0000;

        if (HEX_FILE != "")
            $readmemh(HEX_FILE, mem);
    end

    //----------------------------------------------------------
    // 异步只读
    //----------------------------------------------------------
    assign instr = mem[addr[AW+1:2]];

endmodule