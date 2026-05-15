`timescale 1ns / 1ps
//============================================================
// Data Memory
// - Byte-addressable, supports LB/LH/LW/LBU/LHU/SB/SH/SW
// - Synchronous write, combinational read
//============================================================
module data_mem (
    input  wire        clk,
    input  wire        rst,
    input  wire [2:0]  byte_en,    // func3 field for byte/half/word
    input  wire        mem_we,
    input  wire        mem_re,
    input  wire [31:0] addr,
    input  wire [31:0] data_in,
    output reg  [31:0] data_out
);

    reg [7:0] mem [0:1023];   // 1 KB data memory
    integer i;

    wire [31:0] word_data;
    assign word_data = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};

    // Combinational read with sign/zero extension
    always @(*) begin
        data_out = 32'd0;
        if (mem_re) begin
            case (byte_en)
                3'b000: data_out = {{24{mem[addr][7]}}, mem[addr]};              // LB
                3'b001: data_out = {{16{mem[addr+1][7]}}, mem[addr+1], mem[addr]}; // LH
                3'b010: data_out = word_data;                                      // LW
                3'b100: data_out = {24'd0, mem[addr]};                             // LBU
                3'b101: data_out = {16'd0, mem[addr+1], mem[addr]};                // LHU
                default: data_out = word_data;
            endcase
        end
    end

    // Synchronous write
    always @(posedge clk) begin
        if (rst) begin
            $readmemh("data.mem",mem);
        end else if (mem_we) begin
            case (byte_en)
                3'b000: begin   // SB
                    mem[addr] <= data_in[7:0];
                end
                3'b001: begin   // SH
                    mem[addr]   <= data_in[7:0];
                    mem[addr+1] <= data_in[15:8];
                end
                3'b010: begin   // SW
                    mem[addr]   <= data_in[7:0];
                    mem[addr+1] <= data_in[15:8];
                    mem[addr+2] <= data_in[23:16];
                    mem[addr+3] <= data_in[31:24];
                end
                default: begin end
            endcase
        end
    end

endmodule
