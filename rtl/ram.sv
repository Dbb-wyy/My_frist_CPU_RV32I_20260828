`timescale 1ns / 1ps

module ram #(
    parameter int          DEPTH    = 2048,
    parameter logic [31:0] RAM_BASE = 32'h1000_0000
) (
    input  logic        clk,    // 时钟
    input  logic [31:0] addr,   // 字节地址，来自 datapath 的 dmem_addr
    input  logic [31:0] wdata,  // 写数据，来自 dmem_wdata
    output logic [31:0] rdata,  // 读数据，送回 dmem_rdata
    input  logic        we,     // 写使能，来自 dmem_we
    input  logic [ 3:0] be      // 字节使能，来自 dmem_be
);

    // 一个字 = 4 字节，字索引位宽 = clog2(DEPTH)
    localparam int AW = $clog2(DEPTH);  // DEPTH=2048 -> AW=11

    // 地址范围检查：只有落在 [RAM_BASE, RAM_BASE + DEPTH*4) 的访问才生效
    localparam logic [31:0] RAM_END = RAM_BASE + DEPTH * 4;
    wire ram_sel = (addr >= RAM_BASE) && (addr < RAM_END);

    logic [31:0] mem[0:DEPTH-1];

    //----------------------------------------------------------
    // 仿真初始化：数据 RAM 上电内容清零
    // 如果不想依赖 initial，可以删除；但仿真时建议保留
    //----------------------------------------------------------
    initial begin
        for (int i = 0; i < DEPTH; i++) mem[i] = 32'b0;
    end

    //----------------------------------------------------------
    // 异步读
    // 字节地址右移 2 位得到字地址
    // 只有命中 RAM 地址范围才返回数据，否则返回 0
    //----------------------------------------------------------
    assign rdata = ram_sel ? mem[addr[AW+1:2]] : 32'b0;

    //----------------------------------------------------------
    // 同步写 + 字节使能
    // 只有命中 RAM 地址范围才真正写入
    //----------------------------------------------------------
    always_ff @(posedge clk) begin
        if (we && ram_sel) begin
            if (be[0]) mem[addr[AW+1:2]][7:0] <= wdata[7:0];
            if (be[1]) mem[addr[AW+1:2]][15:8] <= wdata[15:8];
            if (be[2]) mem[addr[AW+1:2]][23:16] <= wdata[23:16];
            if (be[3]) mem[addr[AW+1:2]][31:24] <= wdata[31:24];
        end
    end

endmodule
