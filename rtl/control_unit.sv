`timescale 1ns / 1ps

// Control Unit (ID stage)

module control_unit (
    input  wire [6:0] opcode,
    input  wire       stall,       // load-use stall → suppress decode
    output reg        reg_we,      // register write enable
    output reg        mem_we,      // memory write enable
    output reg        mem_re,      // memory read enable
    output reg        mem_to_reg,  // 1 = write mem data to rd
    output reg  [1:0] alu_op,      // ALU operation type
    output reg  [1:0] op_a_sel,    // 00=rs1, 01=PC, 10=0(LUI)
    output reg        op_b_sel,    // 0=rs2, 1=imm
    output reg  [1:0] pc_sel,      // 00=PC+4, 01=PC+imm, 10=rs1+imm(JALR)
    output reg        jump,        // JAL or JALR
    output reg        branch       // branch instruction
);

    always @(*) begin
        reg_we     = 1'b0;
        mem_we     = 1'b0;
        mem_re     = 1'b0;
        mem_to_reg = 1'b0;
        alu_op     = 2'b00;
        op_a_sel   = 2'b00;
        op_b_sel   = 1'b0;
        pc_sel     = 2'b00;
        jump       = 1'b0;
        branch     = 1'b0;

        if (!stall) begin
            case (opcode)
                // R-type (ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND)
                7'b0110011: begin
                    reg_we   = 1'b1;
                    alu_op   = 2'b10;
                end

                // I-type ALU (ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI)
                7'b0010011: begin
                    reg_we   = 1'b1;
                    alu_op   = 2'b11;
                    op_b_sel = 1'b1;
                end

                // Load (LB, LH, LW, LBU, LHU)
                7'b0000011: begin
                    reg_we     = 1'b1;
                    mem_re     = 1'b1;
                    mem_to_reg = 1'b1;
                    alu_op     = 2'b00;
                    op_b_sel   = 1'b1;
                end

                // Store (SB, SH, SW)
                7'b0100011: begin
                    mem_we   = 1'b1;
                    alu_op   = 2'b00;    // ADD for address calc
                    op_b_sel = 1'b1;
                end

                // Branch (BEQ, BNE, BLT, BGE, BLTU, BGEU)
                7'b1100011: begin
                    alu_op = 2'b01;
                    branch = 1'b1;
                end

                // JAL
                7'b1101111: begin
                    reg_we   = 1'b1;
                    jump     = 1'b1;
                    pc_sel   = 2'b01;    // PC + imm
                    op_a_sel = 2'b01;    // PC
                    op_b_sel = 1'b1;     // imm
                end

                // JALR
                7'b1100111: begin
                    reg_we   = 1'b1;
                    jump     = 1'b1;
                    pc_sel   = 2'b10;    // rs1 + imm
                    op_b_sel = 1'b1;
                end

                // LUI
                7'b0110111: begin
                    reg_we   = 1'b1;
                    op_a_sel = 2'b10;    // 0
                    op_b_sel = 1'b1;     // imm
                    alu_op   = 2'b00;    // ADD → 0 + imm
                end

                // AUIPC
                7'b0010111: begin
                    reg_we   = 1'b1;
                    op_a_sel = 2'b01;    // PC
                    op_b_sel = 1'b1;     // imm
                    alu_op   = 2'b00;    // ADD → PC + imm
                end

                default: begin
                    // NOP
                end
            endcase
        end
    end

endmodule
