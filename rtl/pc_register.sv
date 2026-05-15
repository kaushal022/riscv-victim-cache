`timescale 1ns / 1ps
//============================================================
// Program Counter Register

module pc_register (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,
    input  wire [31:0] next_pc,
    output reg  [31:0] pc
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'd0;
        else if (!stall)
            pc <= next_pc;
    end

endmodule
