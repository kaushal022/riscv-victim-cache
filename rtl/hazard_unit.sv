`timescale 1ns / 1ps
// Hazard Detection Unit
// - Detects load-use hazards → stall pipeline + insert bubble
// - Detects branch/jump taken → flush IF/ID and ID/EX
module hazard_unit (
    // From ID stage
    input  wire [4:0] if_id_rs1,
    input  wire [4:0] if_id_rs2,
    input  wire [6:0] if_id_opcode,
    // From EX stage
    input  wire [4:0] id_ex_rd,
    input  wire       id_ex_mem_re,    // load in EX?
    input  wire       id_ex_branch,
    input  wire       id_ex_jump,
    input  wire [1:0] id_ex_pc_sel,
    input  wire       branch_taken,
    // Outputs
    output reg        stall,
    output reg        if_id_flush,
    output reg        id_ex_flush
);

    wire is_branch_or_jump = id_ex_branch | id_ex_jump;
    wire take_branch       = (id_ex_branch & branch_taken) |
                             (id_ex_pc_sel == 2'b01) |    // JAL
                             (id_ex_pc_sel == 2'b10);     // JALR

    // Determine if ID-stage instruction uses rs1/rs2
    wire id_uses_rs1 = (if_id_opcode == 7'b0110011) |  // R-type
                       (if_id_opcode == 7'b0010011) |  // I-type ALU
                       (if_id_opcode == 7'b0000011) |  // Load
                       (if_id_opcode == 7'b0100011) |  // Store
                       (if_id_opcode == 7'b1100011) |  // Branch
                       (if_id_opcode == 7'b1100111);   // JALR

    wire id_uses_rs2 = (if_id_opcode == 7'b0110011) |  // R-type
                       (if_id_opcode == 7'b0100011) |  // Store
                       (if_id_opcode == 7'b1100011);   // Branch

    // Load-use hazard: load in EX, dependent instruction in ID
    wire load_use = id_ex_mem_re && (id_ex_rd != 5'd0) &&
                    ((id_uses_rs1 && (id_ex_rd == if_id_rs1)) ||
                     (id_uses_rs2 && (id_ex_rd == if_id_rs2)));

    always @(*) begin
        stall       = 1'b0;
        if_id_flush = 1'b0;
        id_ex_flush = 1'b0;

        if (load_use) begin
            // Stall: hold PC and IF/ID, insert bubble in ID/EX
            stall       = 1'b1;
            id_ex_flush = 1'b1;
        end

        if (take_branch) begin
            // Flush both IF/ID and ID/EX (squash 2 in-flight instructions)
            if_id_flush = 1'b1;
            id_ex_flush = 1'b1;
        end
    end

endmodule
