`timescale 1ns / 1ps

module victim_cache (
    input  wire        clk,
    input  wire        rst,
    
    // Lookup Interface
    input  wire [27:0] lookup_addr,
    output wire        vc_hit,
    output wire [127:0]hit_data,
    output wire        hit_dirty,
    
    // Insertion Interface
    input  wire        insert_en,     // Inserts at LRU
    input  wire        swap_en,       // Replaces HIT entry
    input  wire [27:0] insert_addr,
    input  wire [127:0]insert_data,
    input  wire        insert_dirty,
    
    // Eviction Interface (Output of LRU entry)
    output wire [27:0] evict_addr,
    output wire [127:0]evict_data,
    output wire        evict_valid,
    output wire        evict_dirty
);

    // =========================================================================
    // MEMORY SIZING INFO:
    // This is a 4-entry Fully Associative Victim Cache.
    // Each entry contains:
    //   - Data Block: 128 bits (16 Bytes)
    //   - Tag Address: 28 bits (Full 32-bit address minus 4-bit block offset)
    //   - Valid Bit:    1 bit
    //   - Dirty Bit:    1 bit
    //   - LRU counter:  2 bits (Values 0 to 3 to track 4 entries)
    // 
    // Size per entry: 128 + 28 + 1 + 1 + 2 = 160 bits
    // Total Cache Size (4 entries): 4 * 160 = 640 bits total storage
    // Total Data Capacity: 4 * 16 Bytes = 64 Bytes
    // =========================================================================

    reg [127:0] data_array [0:3];
    reg [27:0]  tag_array  [0:3];
    reg         valid_array[0:3];
    reg         dirty_array[0:3];
    reg [1:0]   lru_array  [0:3];

    wire hit_0 = valid_array[0] && (tag_array[0] == lookup_addr);
    wire hit_1 = valid_array[1] && (tag_array[1] == lookup_addr);
    wire hit_2 = valid_array[2] && (tag_array[2] == lookup_addr);
    wire hit_3 = valid_array[3] && (tag_array[3] == lookup_addr);

    assign vc_hit = hit_0 | hit_1 | hit_2 | hit_3;
    
    wire [1:0] hit_idx = hit_3 ? 2'd3 :
                         hit_2 ? 2'd2 :
                         hit_1 ? 2'd1 : 2'd0;
                         
    assign hit_data  = data_array[hit_idx];
    assign hit_dirty = dirty_array[hit_idx];

    wire [1:0] lru_idx = (lru_array[0] == 2'd0) ? 2'd0 :
                         (lru_array[1] == 2'd0) ? 2'd1 :
                         (lru_array[2] == 2'd0) ? 2'd2 : 2'd3;

    assign evict_addr  = tag_array[lru_idx];
    assign evict_data  = data_array[lru_idx];
    assign evict_valid = valid_array[lru_idx];
    assign evict_dirty = dirty_array[lru_idx];

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i=0; i<4; i=i+1) begin
                valid_array[i] <= 0;
                dirty_array[i] <= 0;
                lru_array[i] <= i;
                tag_array[i]   <= 28'd0;  
                data_array[i]  <= 128'd0;
            end
        end else begin
            if (swap_en && vc_hit) begin
                data_array[hit_idx] <= insert_data;
                tag_array[hit_idx] <= insert_addr;
                dirty_array[hit_idx] <= insert_dirty;
                valid_array[hit_idx] <= 1'b1;
                // Update LRU: hit_idx becomes MRU
                for (i=0; i<4; i=i+1) begin
                    if (i == hit_idx) lru_array[i] <= 2'd3;
                    else if (lru_array[i] > lru_array[hit_idx]) lru_array[i] <= lru_array[i] - 1;
                end
            end else if (insert_en) begin
                data_array[lru_idx] <= insert_data;
                tag_array[lru_idx] <= insert_addr;
                dirty_array[lru_idx] <= insert_dirty;
                valid_array[lru_idx] <= 1'b1;
                // Update LRU: lru_idx becomes MRU
                for (i=0; i<4; i=i+1) begin
                    if (i == lru_idx) lru_array[i] <= 2'd3;
                    else if (lru_array[i] > lru_array[lru_idx]) lru_array[i] <= lru_array[i] - 1;
                end
            end
        end
    end
endmodule
