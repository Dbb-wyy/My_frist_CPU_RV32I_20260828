`timescale 1ns / 1ps

module top_tb;

    logic clk;
    logic rst;
    
    int error_count = 0;
    logic test_started = 0;
    
    top u_top (.clk(clk), .rst(rst));
    
    logic [31:0] pc;
    logic [31:0] instr;
    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic [31:0] dmem_rdata;
    logic dmem_we;
    logic [3:0] dmem_be;
    
    wire [31:0] regs [32];
    
    assign pc = u_top.pc;
    assign instr = u_top.instr;
    assign dmem_addr = u_top.dmem_addr;
    assign dmem_wdata = u_top.dmem_wdata;
    assign dmem_rdata = u_top.dmem_rdata;
    assign dmem_we = u_top.dmem_we;
    assign dmem_be = u_top.dmem_be;
    
    genvar i;
    generate
        for (i = 0; i < 32; i++) begin : reg_connect
            assign regs[i] = u_top.u_cpu.u_datapath.u_regfile.regs[i];
        end
    endgenerate
    
    initial clk = 1'b0;
    always #5 clk = ~clk;
    
    task automatic check_reg(input int reg_num, input logic [31:0] expected, input string description);
        if (regs[reg_num] !== expected) begin
            $display("ERROR at t=%0t: Register x%0d = %h, expected %h (%s)", 
                     $time, reg_num, regs[reg_num], expected, description);
            error_count++;
            $finish;
        end else begin
            $display("PASS at t=%0t: Register x%0d = %h (%s)", 
                     $time, reg_num, expected, description);
        end
    endtask
    
    task automatic check_mem(input int addr, input logic [31:0] expected, input string description);
        automatic logic [31:0] mem_val;
        mem_val = u_top.u_ram.mem[addr[31:2]];
        if (mem_val !== expected) begin
            $display("ERROR at t=%0t: Memory[0x%h] = %h, expected %h (%s)", 
                     $time, addr, mem_val, expected, description);
            error_count++;
            $finish;
        end else begin
            $display("PASS at t=%0t: Memory[0x%h] = %h (%s)", 
                     $time, addr, expected, description);
        end
    endtask
    
    initial begin
        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst = 1'b0;
        test_started = 1;
        $display("========================================");
        $display("Test started at time %0t", $time);
        $display("========================================");
        wait_for_program_end();
        $display("========================================");
        if (error_count == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("TEST FAILURES: %0d errors", error_count);
        $display("Simulation finished at time %0t", $time);
        $display("========================================");
        $finish;
    end
    
    task automatic wait_for_program_end();
        int cycle_count = 0;
        logic [31:0] prev_pc = 0;
        logic [31:0] prev_instr = 0;
        int loop_count = 0;
        
        forever begin
            @(negedge clk);
            if (!test_started) continue;
            cycle_count++;
            
            if (pc == prev_pc && instr == prev_instr && pc != 32'h0) begin
                loop_count++;
                if (loop_count >= 3) begin
                    $display("Program entered infinite loop at PC=%h, instruction=%h", pc, instr);
                    break;
                end
            end else begin
                loop_count = 0;
            end
            prev_pc = pc;
            prev_instr = instr;
            
            case (pc)
                32'h0000000C: check_reg(3, 32'h00000008, "add result");
                32'h00000010: check_reg(4, 32'h00000002, "sub result");
                32'h00000014: check_reg(5, 32'h00000007, "or result");
                32'h00000018: check_reg(6, 32'h00000001, "and result");
                32'h0000001C: check_reg(7, 32'h00000006, "xor result");
                32'h00000020: check_reg(8, 32'h00000000, "srl result");
                32'h00000024: check_reg(9, 32'h00000028, "sll result");
                32'h00000028: check_reg(10, 32'h00000000, "sra result");
                32'h0000002C: check_reg(11, 32'hFFFFFFF3, "addi result");
                32'h00000030: check_reg(11, 32'h0000000F, "ori result");
                32'h00000034: check_reg(11, 32'h00000000, "andi result");
                32'h00000038: check_reg(11, 32'h0000000F, "xori result");
                32'h0000003C: check_reg(12, 32'h00000001, "srli result");
                32'h00000040: check_reg(13, 32'h00000006, "slli result");
                32'h00000044: check_reg(14, 32'h00000001, "srai result");
                
                32'h0000004C: check_mem(0, 32'h00000008, "sw mem[0]");
                32'h00000050: check_mem(4, 32'h00000002, "sw mem[4]");
                32'h00000054: check_mem(8, 32'h00000007, "sw mem[8]");
                32'h00000058: check_mem(12, 32'h00000001, "sw mem[12]");
                32'h0000005C: check_mem(16, 32'h00000006, "sw mem[16]");
                32'h00000060: check_mem(20, 32'h00000000, "sw mem[20]");
                32'h00000064: check_mem(24, 32'h00000028, "sw mem[24]");
                32'h00000068: check_mem(28, 32'h00000000, "sw mem[28]");
                
                // 半字/字节存储后不检查内存，仅输出信息
                32'h0000006C: begin
                    $display("INFO: Halfword store to addr 35 = %h", u_top.u_ram.mem[8] & 32'h0000FFFF);
                end
                32'h00000070: begin
                    $display("INFO: Byte store to addr 36 = %h", u_top.u_ram.mem[9] & 32'h000000FF);
                end
                
                32'h00000078: check_reg(6, 32'h00000008, "lw x6");
                32'h0000007C: check_reg(7, 32'h00000002, "lw x7");
                32'h00000080: check_reg(8, 32'h00000007, "lw x8");
                32'h00000084: check_reg(9, 32'h00000001, "lw x9");
                32'h00000088: check_reg(10, 32'h00000006, "lw x10");
                32'h0000008C: check_reg(11, 32'h00000000, "lw x11");
                32'h00000090: check_reg(12, 32'h00000028, "lw x12");
                32'h00000094: check_reg(13, 32'h0000000F, "lhu x13");
                32'h00000098: check_reg(14, 32'h00000001, "lbu x14");
                
                32'h000000B0: begin
                    check_reg(28, 32'h00000003, "x28=3");
                    check_reg(29, 32'h00000004, "x29=4");
                end
                32'h000000D0: check_reg(30, 32'h00000007, "x30=7 intermediate");
                32'h00000108: check_reg(30, 32'h00000006, "x30=6 final");
                32'h00000118: begin
                    check_reg(8, 32'h00000001, "sltu result");
                    check_reg(9, 32'h00000000, "slt result");
                end
                32'h00000120: check_reg(1, 32'h1234500A, "LUI+ADDI");
                32'h00000128: begin
                    check_mem(0, 32'h00000008, "final mem[0]");
                    check_mem(8, 32'h00000006, "final mem[8]");
                    check_mem(12, 32'h1234500A, "final mem[12]");
                end
            endcase
        end
    endtask
    
    initial begin
        $monitor("t=%0t | rst=%b | pc=%h | instr=%h | x1=%h x2=%h x3=%h x4=%h x5=%h x6=%h | daddr=%h | dwdata=%h | dwe=%b",
                 $time, rst, pc, instr, regs[1], regs[2], regs[3], regs[4], regs[5], regs[6],
                 dmem_addr, dmem_wdata, dmem_we);
    end
    
    initial begin
        #10000;
        $display("TIMEOUT");
        $finish;
    end

endmodule