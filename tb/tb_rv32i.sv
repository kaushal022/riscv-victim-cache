`timescale 1ns / 1ps
module tb_rv32i #(
    parameter string INSTR_FILE  = "instr.mem",
    parameter string DATA_FILE   = "data.mem",
    parameter string WORKLOAD    = "Custom Program",
    parameter int    INSTR_COUNT = 38 // Put the expected instruction count here
);

    reg clk, rst;
    wire [31:0] alu_out, pc_out;
    rv32i_top DUT (.clk(clk), .rst(rst), .alu_out(alu_out), .pc_out(pc_out));
    
    initial clk = 0;
    always #5 clk = ~clk;

    integer cycles = 0;
    reg done = 0;
    reg [31:0] prev_pc;
    integer stable_count = 0;
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            cycles <= 0;
            done <= 0;
            prev_pc <= 32'hFFFFFFFF;
            stable_count <= 0;
        end else if (!done) begin
            cycles <= cycles + 1;
            prev_pc <= pc_out;
            
            if (pc_out == prev_pc && pc_out != 0) begin
                stable_count <= stable_count + 1;
                if (stable_count > 5) done <= 1; 
            end else begin
                stable_count <= 0;
            end
        end
    end

    initial begin
        $readmemh(INSTR_FILE, DUT.IMEM.mem);
        $readmemh(DATA_FILE, DUT.DMEM.mem); 
        rst = 1; #20; rst = 0;
        
        // Wait until the infinite loop detector triggers 'done', with a 50us timeout fallback
        fork
            wait(done);
            #50000 $display("WARNING: Simulation Timeout reached!");
        join_any
        disable fork; // Kill the timeout if done triggered first
        
        $display("========================================");
        $display("  ARCHITECTURE: Baseline (No Cache)");
        $display("========================================");
        for (i = 0; i < 32; i = i + 1) $display("    x%-2d = 0x%08h", i, DUT.RF.registers[i]);
        $display("========================================");
        $finish;
    end
endmodule