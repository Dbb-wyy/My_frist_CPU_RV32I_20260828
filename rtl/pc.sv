`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/28/2026 11:20:43 PM
// Design Name: 
// Module Name: pc
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
module pc (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] next_pc,

    output logic [31:0] pc
);

    // PC register
    //
    // Reset:
    //   pc <= 0
    //
    // Normal operation:
    //   pc <= next_pc
    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= 32'h0000_0000;
        end
        else begin
            pc <= next_pc;
        end
    end

endmodule

