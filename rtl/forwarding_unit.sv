`timescale 1ns / 1ps
// Forwarding Unit
// - Detects EX/MEM → EX and MEM/WB → EX data hazards
module forwarding_unit (
    input  wire [4:0] id_ex_rs1,
    input  wire [4:0] id_ex_rs2,
    input  wire [4:0] ex_mem_rd,
    input  wire       ex_mem_reg_we,
    input  wire [4:0] mem_wb_rd,
    input  wire       mem_wb_reg_we,
    output reg  [1:0] forward_a,   // 00=none, 01=EX/MEM, 10=MEM/WB
    output reg  [1:0] forward_b    // 00=none, 01=EX/MEM, 10=MEM/WB
);

    // Forwarding for operand A (rs1)
    always @(*) begin
        if (ex_mem_reg_we && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1))
            forward_a = 2'b01;   // EX/MEM forward
        else if (mem_wb_reg_we && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs1))
            forward_a = 2'b10;   // MEM/WB forward
        else
            forward_a = 2'b00;   // no forwarding
    end

    // Forwarding for operand B (rs2)
    always @(*) begin
        if (ex_mem_reg_we && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs2))
            forward_b = 2'b01;
        else if (mem_wb_reg_we && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs2))
            forward_b = 2'b10;
        else
            forward_b = 2'b00;
    end

endmodule
