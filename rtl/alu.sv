`timescale 1ns / 1ps
// ALU — Arithmetic Logic Unit
module alu (
    input  wire [31:0] op_a,
    input  wire [31:0] op_b,
    input  wire [3:0]  alu_instr,
    input  wire [2:0]  func3,
    input  wire        is_branch,
    output reg  [31:0] result,
    output reg         branch_taken
);

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

    wire signed [31:0] signed_a = op_a;
    wire signed [31:0] signed_b = op_b;

    // ALU operation
    always @(*) begin
        result = 32'd0;
        case (alu_instr)
            ALU_ADD:  result = op_a + op_b;
            ALU_SUB:  result = op_a - op_b;
            ALU_SLL:  result = op_a << op_b[4:0];
            ALU_SLT:  result = (signed_a < signed_b) ? 32'd1 : 32'd0;
            ALU_SLTU: result = (op_a < op_b) ? 32'd1 : 32'd0;
            ALU_XOR:  result = op_a ^ op_b;
            ALU_SRL:  result = op_a >> op_b[4:0];
            ALU_SRA:  result = $signed(op_a) >>> op_b[4:0];
            ALU_OR:   result = op_a | op_b;
            ALU_AND:  result = op_a & op_b;
            default:  result = 32'd0;
        endcase
    end

    // Branch condition evaluation
    always @(*) begin
        branch_taken = 1'b0;
        if (is_branch) begin
            case (func3)
                3'b000:  branch_taken = (op_a == op_b);                          // BEQ
                3'b001:  branch_taken = (op_a != op_b);                          // BNE
                3'b100:  branch_taken = (signed_a < signed_b);                   // BLT
                3'b101:  branch_taken = (signed_a >= signed_b);                  // BGE
                3'b110:  branch_taken = (op_a < op_b);                           // BLTU
                3'b111:  branch_taken = (op_a >= op_b);                          // BGEU
                default: branch_taken = 1'b0;
            endcase
        end
    end

endmodule
