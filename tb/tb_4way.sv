`timescale 1ns / 1ps
module tb_4way;
    reg clk, rst;
    wire [31:0] alu_out, pc_out;
    rv32i_top_4way DUT (.clk(clk), .rst(rst), .alu_out(alu_out), .pc_out(pc_out));
    initial clk = 0;
    always #5 clk = ~clk;

    integer cycles = 0;
    integer instr_count = 86; 
    reg done = 0;
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            cycles <= 0;
            done <= 0;
        end else if (!done) begin
            cycles <= cycles + 1;
            if (DUT.memwb_pc == 32'h28 || DUT.memwb_pc == 32'h38 || DUT.memwb_pc == 32'h58) done <= 1;
        end
    end

    initial begin
        $readmemh("instr_thrash.mem", DUT.IMEM.mem);
        $readmemh("data_block.mem", DUT.CACHE_4WAY.main_mem);
        rst = 1; #20; rst = 0;
        #20000;
        if (!done) done = 1;
        $display("========================================");
        $display("  ARCHITECTURE: 4-Way SA Cache");
        $display("========================================");
        $display("  Workload:   instr_thrash / Summation");
        $display("  Cache Hits: %0d", DUT.CACHE_4WAY.hit_count);
        $display("  Misses:     %0d", DUT.CACHE_4WAY.miss_count);
        $display("  Hit Rate:   %0.2f%%", DUT.CACHE_4WAY.hit_count * 100.0 / DUT.CACHE_4WAY.mem_access_count);
        $display("  Approx CPI: %0.2f", cycles * 1.0 / instr_count);
        $display("----------------------------------------");
        for (i = 0; i < 32; i = i + 1) $display("    x%-2d = 0x%08h", i, DUT.RF.registers[i]);
        $display("========================================");
        $finish;
    end
endmodule
