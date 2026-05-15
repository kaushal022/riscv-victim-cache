`timescale 1ns / 1ps
// EX/MEM Pipeline Register
// - Passes ALU result, control signals, store data, PC, etc.
module ex_mem_reg (
    input  wire        clk,
    input  wire        rst,
    // Data path inputs
    input  wire [31:0] alu_result_in,
    input  wire        branch_taken_in,
    input  wire [4:0]  rs2_in,
    input  wire [4:0]  rd_in,
    input  wire [31:0] reg_out_2_in,    // store data (forwarded)
    input  wire [31:0] pc_in,
    input  wire [31:0] imm_in,
    // Control inputs
    input  wire        reg_we_in,
    input  wire        mem_we_in,
    input  wire        mem_re_in,
    input  wire        mem_to_reg_in,
    input  wire        jump_in,
    input  wire        branch_in,
    input  wire [2:0]  func3_in,
    input  wire [1:0]  pc_sel_in,
    input  wire        stall,
    // Data path outputs
    output reg  [31:0] alu_result_out,
    output reg         branch_taken_out,
    output reg  [4:0]  rs2_out,
    output reg  [4:0]  rd_out,
    output reg  [31:0] reg_out_2,
    output reg  [31:0] pc_out,
    output reg  [31:0] imm_out,
    // Control outputs
    output reg         reg_we_out,
    output reg         mem_we_out,
    output reg         mem_re_out,
    output reg         mem_to_reg_out,
    output reg         jump_out,
    output reg         branch_out,
    output reg  [2:0]  func3_out,
    output reg  [1:0]  pc_sel_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_result_out  <= 32'd0;
            branch_taken_out<= 1'b0;
            rs2_out         <= 5'd0;
            rd_out          <= 5'd0;
            reg_out_2       <= 32'd0;
            pc_out          <= 32'd0;
            imm_out         <= 32'd0;
            reg_we_out      <= 1'b0;
            mem_we_out      <= 1'b0;
            mem_re_out      <= 1'b0;
            mem_to_reg_out  <= 1'b0;
            jump_out        <= 1'b0;
            branch_out      <= 1'b0;
            func3_out       <= 3'd0;
            pc_sel_out      <= 2'b00;
        end else if (!stall) begin
            alu_result_out  <= alu_result_in;
            branch_taken_out<= branch_taken_in;
            rs2_out         <= rs2_in;
            rd_out          <= rd_in;
            reg_out_2       <= reg_out_2_in;
            pc_out          <= pc_in;
            imm_out         <= imm_in;
            reg_we_out      <= reg_we_in;
            mem_we_out      <= mem_we_in;
            mem_re_out      <= mem_re_in;
            mem_to_reg_out  <= mem_to_reg_in;
            jump_out        <= jump_in;
            branch_out      <= branch_in;
            func3_out       <= func3_in;
            pc_sel_out      <= pc_sel_in;
        end
    end

endmodule
