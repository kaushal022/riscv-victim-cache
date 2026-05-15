`timescale 1ns / 1ps

module if_id_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,
    input  wire        flush,
    input  wire [31:0] instr_in,
    input  wire [31:0] pc_in,
    // Decoded fields
    output reg  [6:0]  opcode,
    output reg  [4:0]  rs1,
    output reg  [4:0]  rs2,
    output reg  [4:0]  rd,
    output reg  [2:0]  func3,
    output reg  [6:0]  func7,
    output reg  [31:0] instr_out,
    output reg  [31:0] pc_out
);

    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            opcode    <= 7'd0;
            rs1       <= 5'd0;
            rs2       <= 5'd0;
            rd        <= 5'd0;
            func3     <= 3'd0;
            func7     <= 7'd0;
            instr_out <= 32'd0;
            pc_out    <= 32'd0;
        end else if (!stall) begin
            opcode    <= instr_in[6:0];
            rs1       <= instr_in[19:15];
            rs2       <= instr_in[24:20];
            rd        <= instr_in[11:7];
            func3     <= instr_in[14:12];
            func7     <= instr_in[31:25];
            instr_out <= instr_in;
            pc_out    <= pc_in;
        end
    end

endmodule
