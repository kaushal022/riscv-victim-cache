`timescale 1ns / 1ps
// MEM/WB Pipeline Register
// - Passes ALU result, memory data, control for write-back
module mem_wb_reg (
    input  wire        clk,
    input  wire        rst,
    // Data path inputs
    input  wire [4:0]  rd_in,
    input  wire [31:0] alu_result_in,
    input  wire [31:0] mem_data_in,
    input  wire [31:0] pc_in,
    // Control inputs
    input  wire        reg_we_in,
    input  wire        mem_to_reg_in,
    input  wire        jump_in,
    input  wire        stall,
    // Data path outputs
    output reg  [4:0]  rd_out,
    output reg  [31:0] alu_result_out,
    output reg  [31:0] mem_data_out,
    output reg  [31:0] pc_out,
    // Control outputs
    output reg         reg_we_out,
    output reg         mem_to_reg_out,
    output reg         jump_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_out         <= 5'd0;
            alu_result_out <= 32'd0;
            mem_data_out   <= 32'd0;
            pc_out         <= 32'd0;
            reg_we_out     <= 1'b0;
            mem_to_reg_out <= 1'b0;
            jump_out       <= 1'b0;
        end else if (!stall) begin
            rd_out         <= rd_in;
            alu_result_out <= alu_result_in;
            mem_data_out   <= mem_data_in;
            pc_out         <= pc_in;
            reg_we_out     <= reg_we_in;
            mem_to_reg_out <= mem_to_reg_in;
            jump_out       <= jump_in;
        end
    end

endmodule
