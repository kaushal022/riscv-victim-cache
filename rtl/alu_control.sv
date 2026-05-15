`timescale 1ns / 1ps
// ALU Control
// - Derives 4-bit ALU instruction from alu_op + func3 + func7
//   alu_op: 00=ADD, 01=Branch(SUB), 10=R-type, 11=I-type
module alu_control (
    input  wire [1:0] alu_op,
    input  wire [2:0] func3,
    input  wire [6:0] func7,
    output reg  [3:0] alu_ctrl
);

    // ALU instruction encoding
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_SLL  = 4'b0010;
    localparam ALU_SLT  = 4'b0011;
    localparam ALU_SLTU = 4'b0100;
    localparam ALU_XOR  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_OR   = 4'b1000;
    localparam ALU_AND  = 4'b1001;

    always @(*) begin
        alu_ctrl = ALU_ADD;  // safe default

        case (alu_op)
            2'b00: alu_ctrl = ALU_ADD;   // loads, stores, LUI, AUIPC
            2'b01: alu_ctrl = ALU_SUB;   // branches (compare via subtract)

            2'b10: begin  // R-type
                case (func3)
                    3'b000: alu_ctrl = (func7[5]) ? ALU_SUB : ALU_ADD;
                    3'b001: alu_ctrl = ALU_SLL;
                    3'b010: alu_ctrl = ALU_SLT;
                    3'b011: alu_ctrl = ALU_SLTU;
                    3'b100: alu_ctrl = ALU_XOR;
                    3'b101: alu_ctrl = (func7[5]) ? ALU_SRA : ALU_SRL;
                    3'b110: alu_ctrl = ALU_OR;
                    3'b111: alu_ctrl = ALU_AND;
                endcase
            end

            2'b11: begin  // I-type
                case (func3)
                    3'b000: alu_ctrl = ALU_ADD;   // ADDI
                    3'b001: alu_ctrl = ALU_SLL;   // SLLI
                    3'b010: alu_ctrl = ALU_SLT;   // SLTI
                    3'b011: alu_ctrl = ALU_SLTU;  // SLTIU
                    3'b100: alu_ctrl = ALU_XOR;   // XORI
                    3'b101: alu_ctrl = (func7[5]) ? ALU_SRA : ALU_SRL;  // SRAI/SRLI
                    3'b110: alu_ctrl = ALU_OR;    // ORI
                    3'b111: alu_ctrl = ALU_AND;   // ANDI
                endcase
            end
        endcase
    end

endmodule
