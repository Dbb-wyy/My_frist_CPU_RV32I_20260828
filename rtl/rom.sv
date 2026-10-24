
`timescale 1ns / 1ps

module rom #(
    parameter int DEPTH = 2048,
    parameter string HEX_FILE = "../../../../Test/test_C/HEXS/test_Data_In_ROM.hex"
) (
    // 指令读取端口
    input  logic [31:0] addr,
    output logic [31:0] instr,

    // 数据读取端口
    input  logic [31:0] data_addr,
    output logic [31:0] data_rdata
);

    localparam int AW = $clog2(DEPTH);

    logic [31:0] mem [0:DEPTH-1];

    initial begin
        for (int i = 0; i < DEPTH; i++)
            mem[i] = 32'h0000_0000;

        if (HEX_FILE != "")
            $readmemh(HEX_FILE, mem);
    end

    // 指令端口：异步读取
    assign instr = mem[addr[AW+1:2]];

    // 数据端口：异步读取，与指令读取互不影响
    assign data_rdata = mem[data_addr[AW+1:2]];

endmodule
