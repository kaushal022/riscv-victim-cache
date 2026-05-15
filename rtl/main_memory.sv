`timescale 1ns / 1ps

module main_memory (
    input  wire        clk,
    input  wire        rst,
    input  wire [27:0] mem_addr,  // Block address
    input  wire [127:0]data_in,
    input  wire        mem_we,
    input  wire        mem_re,
    output reg [127:0] data_out,
    output reg         ready
);

    parameter LATENCY = 10;
    
    reg [127:0] memory [0:1023]; // 16 KB
    reg [3:0] timer;
    reg busy;

    initial begin
         $readmemh("data_block.mem", memory);
    end

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            timer <= 0;
            busy <= 0;
            ready <= 0;
            data_out <= 0;
            // memory array initialization handled by $readmemh in initial block
        end else begin
            if (ready) begin
                ready <= 0;
            end
            
            if (!busy && (mem_re || mem_we)) begin
                busy <= 1;
                timer <= LATENCY - 1;
            end else if (busy) begin
                if (timer == 0) begin
                    busy <= 0;
                    ready <= 1;
                    if (mem_we) begin
                        memory[mem_addr[9:0]] <= data_in;
                    end
                    if (mem_re) begin
                        data_out <= memory[mem_addr[9:0]];
                    end
                end else begin
                    timer <= timer - 1;
                end
            end
        end
    end
endmodule
