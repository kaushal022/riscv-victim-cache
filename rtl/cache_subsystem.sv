`timescale 1ns / 1ps

module cache_subsystem (
    input  wire        clk,
    input  wire        rst,
    input  wire [2:0]  byte_en,
    input  wire        mem_we,
    input  wire        mem_re,
    input  wire [31:0] addr,
    input  wire [31:0] data_in,
    output wire [31:0] data_out,
    output wire        cache_stall,
    output reg  [31:0] hit_l1_count,
    output reg  [31:0] hit_vc_count,
    output reg  [31:0] miss_total_count,
    output reg  [31:0] mem_access_count
);

    wire l1_hit;
    wire [127:0] l1_evict_data;
    wire [23:0]  l1_evict_tag;
    wire l1_evict_valid;
    wire l1_evict_dirty;
    
    reg l1_refill_en;
    reg [127:0] l1_refill_data;
    reg [23:0]  l1_refill_tag;
    reg l1_refill_dirty;

    l1_cache L1 (
        .clk(clk),
        .rst(rst),
        .cpu_addr(addr),
        .cpu_data_in(data_in),
        .cpu_byte_en(byte_en),
        .cpu_we(mem_we),
        .cpu_re(mem_re),
        .cpu_data_out(data_out),
        .l1_hit(l1_hit),
        
        .refill_en(l1_refill_en),
        .refill_data(l1_refill_data),
        .refill_tag(l1_refill_tag),
        .refill_dirty(l1_refill_dirty),
        
        .evict_data(l1_evict_data),
        .evict_tag(l1_evict_tag),
        .evict_valid(l1_evict_valid),
        .evict_dirty(l1_evict_dirty)
    );

    wire [27:0] block_addr = addr[31:4];
    wire vc_hit;
    wire [127:0] vc_hit_data;
    wire vc_hit_dirty;
    
    reg vc_insert_en;
    reg vc_swap_en;
    
    wire [27:0] vc_evict_addr;
    wire [127:0] vc_evict_data;
    wire vc_evict_valid;
    wire vc_evict_dirty;

    victim_cache VC (
        .clk(clk),
        .rst(rst),
        .lookup_addr(block_addr),
        .vc_hit(vc_hit),
        .hit_data(vc_hit_data),
        .hit_dirty(vc_hit_dirty),
        
        .insert_en(vc_insert_en),
        .swap_en(vc_swap_en),
        .insert_addr({l1_evict_tag, addr[7:4]}),
        .insert_data(l1_evict_data),
        .insert_dirty(l1_evict_dirty),
        
        .evict_addr(vc_evict_addr),
        .evict_data(vc_evict_data),
        .evict_valid(vc_evict_valid),
        .evict_dirty(vc_evict_dirty)
    );

    reg mm_we;
    reg mm_re;
    reg [27:0] mm_addr;
    reg [127:0] mm_data_in;
    wire [127:0] mm_data_out;
    wire mm_ready;

    main_memory MM (
        .clk(clk),
        .rst(rst),
        .mem_addr(mm_addr),
        .data_in(mm_data_in),
        .mem_we(mm_we),
        .mem_re(mm_re),
        .data_out(mm_data_out),
        .ready(mm_ready)
    );

    localparam IDLE      = 3'd0;
    localparam SWAP      = 3'd1;
    localparam MEM_WB    = 3'd2;
    localparam MEM_FETCH = 3'd3;
    localparam UPDATE    = 3'd4;

    reg [2:0] state;
    reg miss_handled;

    assign cache_stall = (mem_re || mem_we) && (!l1_hit || state != IDLE);

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            hit_l1_count <= 0;
            hit_vc_count <= 0;
            miss_total_count <= 0;
            mem_access_count <= 0;
            l1_refill_en <= 0;
            vc_insert_en <= 0;
            vc_swap_en <= 0;
            mm_we <= 0;
            mm_re <= 0;
            miss_handled <= 0;
        end else begin
            // Default pulse signals
            l1_refill_en <= 0;
            vc_insert_en <= 0;
            vc_swap_en <= 0;
            
            if (state == IDLE && (mem_re || mem_we) && l1_hit) begin
                miss_handled <= 0;
            end else if (state == SWAP || state == UPDATE) begin
                miss_handled <= 1;
            end

            case (state)
                IDLE: begin
                    if (mem_re || mem_we) begin
                        if (l1_hit) begin
                            if (!miss_handled) begin
                                mem_access_count <= mem_access_count + 1;
                                hit_l1_count <= hit_l1_count + 1;
                            end
                        end else begin
                            if (!miss_handled) begin
                                mem_access_count <= mem_access_count + 1;
                                if (vc_hit) begin
                                    hit_vc_count <= hit_vc_count + 1;
                                    state <= SWAP;
                                end else begin
                                    miss_total_count <= miss_total_count + 1;
                                    if (l1_evict_valid && vc_evict_valid && vc_evict_dirty) begin
                                        state <= MEM_WB;
                                        mm_we <= 1;
                                        mm_addr <= vc_evict_addr;
                                        mm_data_in <= vc_evict_data;
                                    end else begin
                                        state <= MEM_FETCH;
                                        mm_re <= 1;
                                        mm_addr <= block_addr;
                                    end
                                end
                            end
                        end
                    end
                end
                
                SWAP: begin
                    l1_refill_en <= 1;
                    l1_refill_data <= vc_hit_data;
                    l1_refill_tag <= block_addr[27:4];
                    l1_refill_dirty <= vc_hit_dirty;
                    
                    vc_swap_en <= 1;
                    state <= IDLE;
                end
                
                MEM_WB: begin
                    if (mm_ready) begin
                        mm_we <= 0;
                        state <= MEM_FETCH;
                        mm_re <= 1;
                        mm_addr <= block_addr;
                    end
                end
                
                MEM_FETCH: begin
                    if (mm_ready) begin
                        mm_re <= 0;
                        state <= UPDATE;
                    end
                end
                
                UPDATE: begin
                    if (l1_evict_valid) begin
                        vc_insert_en <= 1;
                    end
                    l1_refill_en <= 1;
                    l1_refill_data <= mm_data_out;
                    l1_refill_tag <= addr[31:8];
                    l1_refill_dirty <= 1'b0;
                    
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
