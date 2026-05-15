`timescale 1ns / 1ps

// ID/EX Pipeline Register
module id_ex_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        flush,
    // Data path inputs
    input  wire [6:0]  opcode_in,
    input  wire [31:0] reg_out_1_in,
    input  wire [31:0] reg_out_2_in,
    input  wire [4:0]  rs1_in,
    input  wire [4:0]  rs2_in,
    input  wire [4:0]  rd_in,
    input  wire [31:0] imm_in,
    input  wire [2:0]  func3_in,
    input  wire [6:0]  func7_in,
    input  wire [31:0] pc_in,
    // Control inputs
    input  wire        reg_we_in,
    input  wire        mem_we_in,
    input  wire        mem_re_in,
    input  wire        mem_to_reg_in,
    input  wire [1:0]  alu_op_in,
    input  wire [1:0]  op_a_sel_in,
    input  wire        op_b_sel_in,
    input  wire [1:0]  pc_sel_in,
    input  wire        jump_in,
    input  wire        branch_in,
    input  wire        stall,
    // Data path outputs
    output reg  [6:0]  opcode_out,
    output reg  [31:0] reg_out_1,
    output reg  [31:0] reg_out_2,
    output reg  [4:0]  rs1_out,
    output reg  [4:0]  rs2_out,
    output reg  [4:0]  rd_out,
    output reg  [31:0] imm_out,
    output reg  [2:0]  func3_out,
    output reg  [6:0]  func7_out,
    output reg  [31:0] pc_out,
    // Control outputs
    output reg         reg_we_out,
    output reg         mem_we_out,
    output reg         mem_re_out,
    output reg         mem_to_reg_out,
    output reg  [1:0]  alu_op_out,
    output reg  [1:0]  op_a_sel_out,
    output reg         op_b_sel_out,
    output reg  [1:0]  pc_sel_out,
    output reg         jump_out,
    output reg         branch_out
);

    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            opcode_out     <= 7'd0;
            reg_out_1      <= 32'd0;
            reg_out_2      <= 32'd0;
            rs1_out        <= 5'd0;
            rs2_out        <= 5'd0;
            rd_out         <= 5'd0;
            imm_out        <= 32'd0;
            func3_out      <= 3'd0;
            func7_out      <= 7'd0;
            pc_out         <= 32'd0;
            reg_we_out     <= 1'b0;
            mem_we_out     <= 1'b0;
            mem_re_out     <= 1'b0;
            mem_to_reg_out <= 1'b0;
            alu_op_out     <= 2'b00;
            op_a_sel_out   <= 2'b00;
            op_b_sel_out   <= 1'b0;
            pc_sel_out     <= 2'b00;
            jump_out       <= 1'b0;
            branch_out     <= 1'b0;
        end else if (!stall) begin
            opcode_out     <= opcode_in;
            reg_out_1      <= reg_out_1_in;
            reg_out_2      <= reg_out_2_in;
            rs1_out        <= rs1_in;
            rs2_out        <= rs2_in;
            rd_out         <= rd_in;
            imm_out        <= imm_in;
            func3_out      <= func3_in;
            func7_out      <= func7_in;
            pc_out         <= pc_in;
            reg_we_out     <= reg_we_in;
            mem_we_out     <= mem_we_in;
            mem_re_out     <= mem_re_in;
            mem_to_reg_out <= mem_to_reg_in;
            alu_op_out     <= alu_op_in;
            op_a_sel_out   <= op_a_sel_in;
            op_b_sel_out   <= op_b_sel_in;
            pc_sel_out     <= pc_sel_in;
            jump_out       <= jump_in;
            branch_out     <= branch_in;
        end
    end

endmodule
