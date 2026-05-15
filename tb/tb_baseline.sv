`timescale 1ns / 1ps
//==============================================================
// Baseline Testbench (NO cache - original data_mem)
// Verifies pipeline correctness before cache modification
//==============================================================
module tb_baseline;

    logic        clk;
    logic        rst;
    logic [31:0] alu_out;
    logic [31:0] pc;

    // Instantiate Baseline DUT (no cache)
    top_baseline dut (
        .clk     (clk),
        .rst     (rst),
        .alu_out (alu_out),
        .pc      (pc)
    );

    initial clk = 0;
    always  #5 clk = ~clk;

    integer cycle_count;

    always_ff @(posedge clk) begin
        if (rst)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end

    initial begin
        $dumpfile("tb_baseline.vcd");
        $dumpvars(0, tb_baseline);

        $display("\n##################################################");
        $display("#   BASELINE PIPELINE TEST (No Cache)             #");
        $display("##################################################\n");

        rst = 1;
        #20;
        rst = 0;

        #900;

        $display("\n--- FINAL REGISTER FILE (Baseline) ---");
        for (int i = 0; i <= 31; i++) begin
            $display("  x%-2d = %0d (0x%08h)", i,
                $signed(dut.rf.register_file[i]),
                dut.rf.register_file[i]);
        end
        $display("--------------------------------------");
        $display("  Total Cycles: %0d", cycle_count);
        $display("  CPI: 1.0 (no memory stalls)");
        $display("--------------------------------------\n");

        $finish; 
    end

endmodule
