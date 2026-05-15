`timescale 1ns / 1ps
// Register File — 32 x 32-bit
module reg_file (
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] data_in,
    output wire [31:0] reg_out_1,
    output wire [31:0] reg_out_2
);

    reg [31:0] registers [0:31];
    integer i;

    // Synchronous write on negative edge to avoid WB-ID conflict
    always @(negedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'd0;
        end else if (we && rd != 5'd0) begin
            registers[rd] <= data_in;
        end
    end

    // Combinational read; x0 always returns 0
    assign reg_out_1 = (rs1 == 5'd0) ? 32'd0 : registers[rs1];
    assign reg_out_2 = (rs2 == 5'd0) ? 32'd0 : registers[rs2];

endmodule
