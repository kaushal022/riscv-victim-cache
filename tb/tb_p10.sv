`timescale 1ns / 1ps
module tb_p10;

    reg clk;
    reg rst;
    wire [31:0] alu_out;
    wire [31:0] pc_out;

    rv32i_top_p10 DUT (
        .clk(clk), .rst(rst),
        .alu_out(alu_out), .pc_out(pc_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    real hit_rate;
    real cpi;
    integer cycles = 0;
    integer i;
    integer instr_count = 140; // Approx 14 instructions per loop * 10 loops
    reg done = 0;

    integer trap_count = 0;

    always @(posedge clk) begin
        if (!rst && !done) begin
            cycles = cycles + 1;
            
            // To avoid pipeline sequential fetch hazards and optimized wire issues,
            // we simply count how many times the PC hits the trap instructions.
            // During normal execution, it might hit them sequentially a few times,
            // but in the infinite loop trap, it hits them continuously!
            if (pc_out == 32'h00000038 || pc_out == 32'h00000070 || pc_out == 32'h00000074) begin
                trap_count = trap_count + 1;
                if (trap_count > 20 && !done) begin
                    $display("  [DEBUG] trap_count reached 20 at time %0t. Setting done=1.", $time);
                    done = 1;
                end
            end
        end
    end

    initial begin
        $dumpfile("p10_vc.vcd");
        $dumpvars(0, tb_p10);
        
        $readmemh("instr_thrash.mem", DUT.IMEM.mem);
        
        rst = 1;
        #20;
        rst = 0;

        // Safety timeout block to see if done ever triggers
        fork
            wait(done);
            begin
                #2000;
                $display("  [DEBUG] SIMULATION TIMEOUT at %0t! done=%b, trap_count=%0d, pc_out=0x%08h", $time, done, trap_count, pc_out);
            end
        join_any
        disable fork; // Kill the timeout if done triggered

        #500; // Allow pipeline to drain even during cache misses

        hit_rate = (DUT.CACHE.hit_l1_count + DUT.CACHE.hit_vc_count) * 100.0 / DUT.CACHE.mem_access_count;
        cpi = cycles * 1.0 / instr_count;
        
        // Print register file contents
        $display("  Register File Dump:");
        for (i = 0; i < 32; i = i + 1) begin
            $display("    x%-2d = 0x%08h (%0d)",
                     i, DUT.RF.registers[i], $signed(DUT.RF.registers[i]));
        end
        
        $display("========================================");
        $display("  ARCHITECTURE: DM (16) + VC (4)");
        $display("========================================");
        $display("  Workload:   Thrashing (5 Addresses)");
        $display("  L1 Hits:    %0d", DUT.CACHE.hit_l1_count);
        $display("  VC Hits:    %0d", DUT.CACHE.hit_vc_count);
        $display("  Misses:     %0d", DUT.CACHE.miss_total_count);
        $display("  Hit Rate:   %0.2f%%", hit_rate);
        $display("  Cycles:     %0d", cycles);
        $display("  Approx CPI: %0.2f", cpi);
        $display("========================================");
       
        $stop;
    end
endmodule
