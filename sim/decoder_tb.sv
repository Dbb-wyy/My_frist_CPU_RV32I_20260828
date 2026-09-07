`timescale 1ns/1ps

import cpu_pkg::*;

module decoder_tb;

    logic [31:0] inst;

    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;

    logic [6:0]  opcode;
    logic [2:0]  funct3;
    logic [6:0]  funct7;

    instr_type_t instr_type;


    // DUT
    decoder dut (
        .inst       (inst),
        .rs1        (rs1),
        .rs2        (rs2),
        .rd         (rd),
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7     (funct7),
        .instr_type (instr_type)
    );


    initial begin

        // =====================================================
        // Test 1: ADD x1, x2, x3
        //
        // funct7 = 0000000
        // rs2    = 00011
        // rs1    = 00010
        // funct3 = 000
        // rd     = 00001
        // opcode = 0110011
        //
        // machine code = 0x003100B3
        // =====================================================

        inst = 32'h003100B3;

        #1;

        $display("Test 1: ADD");
        $display("inst       = %h", inst);
        $display("opcode     = %b", opcode);
        $display("funct7     = %b", funct7);
        $display("funct3     = %b", funct3);
        $display("rs1        = x%0d", rs1);
        $display("rs2        = x%0d", rs2);
        $display("rd         = x%0d", rd);
        $display("instr_type = %s", instr_type.name());

        assert (opcode == 7'b0110011);
        assert (funct7 == 7'b0000000);
        assert (funct3 == 3'b000);
        assert (rs1 == 5'd2);
        assert (rs2 == 5'd3);
        assert (rd  == 5'd1);
        assert (instr_type == INST_R);


        // =====================================================
        // Test 2: ADDI x5, x6, 10
        //
        // opcode = 0010011
        //
        // machine code = 0x00A30293
        // =====================================================

        inst = 32'h00A30293;

        #1;

        $display("\nTest 2: ADDI");
        $display("inst       = %h", inst);
        $display("opcode     = %b", opcode);
        $display("funct3     = %b", funct3);
        $display("rs1        = x%0d", rs1);
        $display("rd         = x%0d", rd);
        $display("instr_type = %s", instr_type.name());

        assert (opcode == 7'b0010011);
        assert (funct3 == 3'b000);
        assert (rs1 == 5'd6);
        assert (rd  == 5'd5);
        assert (instr_type == INST_I);


        // =====================================================
        // Test 3: LW x1, 8(x2)
        //
        // opcode = 0000011
        // funct3 = 010
        //
        // machine code = 0x00812083
        // =====================================================

        inst = 32'h00812083;

        #1;

        $display("\nTest 3: LW");
        $display("inst       = %h", inst);
        $display("opcode     = %b", opcode);
        $display("funct3     = %b", funct3);
        $display("rs1        = x%0d", rs1);
        $display("rd         = x%0d", rd);
        $display("instr_type = %s", instr_type.name());

        assert (opcode == 7'b0000011);
        assert (funct3 == 3'b010);
        assert (rs1 == 5'd2);
        assert (rd  == 5'd1);
        assert (instr_type == INST_LOAD);


        // =====================================================
        // Test 4: SW x3, 8(x4)
        //
        // opcode = 0100011
        // funct3 = 010
        //
        // machine code = 0x00322423
        // =====================================================

        inst = 32'h00322423;

        #1;

        $display("\nTest 4: SW");
        $display("inst       = %h", inst);
        $display("opcode     = %b", opcode);
        $display("funct3     = %b", funct3);
        $display("rs1        = x%0d", rs1);
        $display("rs2        = x%0d", rs2);
        $display("instr_type = %s", instr_type.name());

        assert (opcode == 7'b0100011);
        assert (funct3 == 3'b010);
        assert (rs1 == 5'd4);
        assert (rs2 == 5'd3);
        assert (instr_type == INST_STORE);


        // =====================================================
        // Test 5: BEQ x1, x2, offset
        //
        // opcode = 1100011
        // funct3 = 000
        //
        // machine code = 0x00208663
        // =====================================================

        inst = 32'h00208663;

        #1;

        $display("\nTest 5: BEQ");
        $display("inst       = %h", inst);
        $display("opcode     = %b", opcode);
        $display("funct3     = %b", funct3);
        $display("rs1        = x%0d", rs1);
        $display("rs2        = x%0d", rs2);
        $display("instr_type = %s", instr_type.name());

        assert (opcode == 7'b1100011);
        assert (funct3 == 3'b000);
        assert (rs1 == 5'd1);
        assert (rs2 == 5'd2);
        assert (instr_type == INST_BRANCH);


        // =====================================================
        // Test 6: JAL
        //
        // opcode = 1101111
        // =====================================================

        inst = 32'h0000006F;

        #1;

        $display("\nTest 6: JAL");
        $display("inst       = %h", inst);
        $display("opcode     = %b", opcode);
        $display("instr_type = %s", instr_type.name());

        assert (opcode == 7'b1101111);
        assert (instr_type == INST_JAL);


        // =====================================================
        // Test 7: JALR x1, 0(x2)
        //
        // opcode = 1100111
        // funct3 = 000
        //
        // machine code = 0x000100E7
        // =====================================================

        inst = 32'h000100E7;

        #1;

        $display("\nTest 7: JALR");
        $display("inst       = %h", inst);
        $display("opcode     = %b", opcode);
        $display("funct3     = %b", funct3);
        $display("rs1        = x%0d", rs1);
        $display("rd         = x%0d", rd);
        $display("instr_type = %s", instr_type.name());

        assert (opcode == 7'b1100111);
        assert (funct3 == 3'b000);
        assert (rs1 == 5'd2);
        assert (rd  == 5'd1);
        assert (instr_type == INST_JALR);


        // =====================================================
        // Test 8: LUI x1, 0x12345
        //
        // opcode = 0110111
        // =====================================================

        inst = 32'h123450B7;

        #1;

        $display("\nTest 8: LUI");
        $display("inst       = %h", inst);
        $display("opcode     = %b", opcode);
        $display("rd         = x%0d", rd);
        $display("instr_type = %s", instr_type.name());

        assert (opcode == 7'b0110111);
        assert (rd  == 5'd1);
        assert (instr_type == INST_LUI);


        // =====================================================
        // Test 9: AUIPC x1, 0x12345
        // =====================================================

        inst = 32'h12345097;

        #1;

        $display("\nTest 9: AUIPC");
        $display("inst       = %h", inst);
        $display("opcode     = %b", opcode);
        $display("rd         = x%0d", rd);
        $display("instr_type = %s", instr_type.name());

        assert (opcode == 7'b0010111);
        assert (rd  == 5'd1);
        assert (instr_type == INST_AUIPC);


        // =====================================================
        // Test 10: Invalid opcode
        // =====================================================

        inst = 32'hFFFFFFFF;

        #1;

        $display("\nTest 10: INVALID");
        $display("inst       = %h", inst);
        $display("opcode     = %b", opcode);
        $display("instr_type = %s", instr_type.name());

        assert (instr_type == INST_INVALID);


        // =====================================================
        // Done
        // =====================================================

        $display("\n================================");
        $display("All decoder tests passed!");
        $display("================================");

        $finish;

    end

endmodule