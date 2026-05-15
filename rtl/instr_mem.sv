`timescale 1ns / 1ps
//============================================================
// Instruction Memory (ROM)
// - Combinational read, word-aligned

module instr_mem (
    input  wire [31:0] addr,
    output wire [31:0] instr
);

    reg [31:0] mem [0:255];   // 1 KB instruction space

    initial begin
        $readmemh("instr_thrash.mem", mem);
//        $readmemh("instr_thrash_9.mem", mem);
//        $readmemh("instr_spatial.mem", mem);
    end

    assign instr = mem[addr[31:2]];  // word-aligned access

endmodule
