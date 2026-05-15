`timescale 1ns / 1ps

module cache_4way (
    input  wire        clk,
    input  wire        rst,
    input  wire [2:0]  byte_en,
    input  wire        mem_we,
    input  wire        mem_re,
    input  wire [31:0] addr,
    input  wire [31:0] data_in,
    output reg  [31:0] data_out,
    output wire        cache_stall,
    output reg  [31:0] hit_count,
    output reg  [31:0] miss_count,
    output reg  [31:0] mem_access_count
);

    // Memory Parameters
    parameter MEM_LATENCY = 10;
    
    // Main Memory (16 KB)
    reg [127:0] main_mem [0:1023];
    integer i, j;

    initial begin
        $readmemh("data_block.mem", main_mem);
    end

    // 4-Way SA Cache (256 bytes, 16 blocks, 4 sets, 4 ways)
    reg [127:0] cache_data [0:3][0:3];
    reg [25:0]  cache_tag  [0:3][0:3];
    reg         cache_valid[0:3][0:3];
    reg         cache_dirty[0:3][0:3];
    reg [1:0]   cache_lru  [0:3][0:3];

    // Address Parsing
    wire [3:0]  offset = addr[3:0];
    wire [1:0]  set_idx = addr[5:4];
    wire [25:0] tag_in = addr[31:6];
    wire [27:0] block_addr = addr[31:4];

    // Hit Logic
    wire hit_0 = (cache_valid[set_idx][0] && (cache_tag[set_idx][0] == tag_in));
    wire hit_1 = (cache_valid[set_idx][1] && (cache_tag[set_idx][1] == tag_in));
    wire hit_2 = (cache_valid[set_idx][2] && (cache_tag[set_idx][2] == tag_in));
    wire hit_3 = (cache_valid[set_idx][3] && (cache_tag[set_idx][3] == tag_in));
    wire cache_hit = hit_0 | hit_1 | hit_2 | hit_3;
    
    wire [1:0] hit_way = hit_3 ? 2'd3 : 
                         hit_2 ? 2'd2 : 
                         hit_1 ? 2'd1 : 2'd0;

    // Data Extraction for Combinational Read
    wire [127:0] hit_block = cache_data[set_idx][hit_way];
    wire [31:0]  word_data;
    
    wire [7:0] hb_bytes [0:15];
    genvar g;
    generate
        for (g = 0; g < 16; g = g + 1) begin : gen_hb
            assign hb_bytes[g] = hit_block[g*8 +: 8];
        end
    endgenerate

    assign word_data = (offset <= 12) ? 
        {hb_bytes[offset+3], hb_bytes[offset+2], hb_bytes[offset+1], hb_bytes[offset]} : 32'd0;

    always @(*) begin
        data_out = 32'd0;
        if (mem_re && cache_hit) begin
            case (byte_en)
                3'b000: data_out = {{24{hb_bytes[offset][7]}}, hb_bytes[offset]};
                3'b001: data_out = {{16{hb_bytes[offset+1][7]}}, hb_bytes[offset+1], hb_bytes[offset]};
                3'b010: data_out = word_data;
                3'b100: data_out = {24'd0, hb_bytes[offset]};
                3'b101: data_out = {16'd0, hb_bytes[offset+1], hb_bytes[offset]};
                default: data_out = word_data;
            endcase
        end
    end

    // FSM States
    localparam IDLE = 2'd0;
    localparam MEM_WB = 2'd1;
    localparam MEM_FETCH = 2'd2;
    localparam UPDATE = 2'd3;

    reg [1:0] state;
    reg [3:0] timer;
    reg miss_handled;

    // Find LRU in set
    wire [1:0] lru_way = (cache_lru[set_idx][0] == 2'd0) ? 2'd0 :
                         (cache_lru[set_idx][1] == 2'd0) ? 2'd1 :
                         (cache_lru[set_idx][2] == 2'd0) ? 2'd2 : 2'd3;

    assign cache_stall = (mem_re || mem_we) && (!cache_hit || state != IDLE);

    reg [127:0] fetched_data;
    
    reg [127:0] new_cache_data;
    always @(*) begin
        new_cache_data = cache_data[set_idx][hit_way];
        if (mem_we) begin
            case (byte_en)
                3'b000: new_cache_data[offset*8 +: 8] = data_in[7:0];
                3'b001: begin
                    new_cache_data[offset*8 +: 8] = data_in[7:0];
                    new_cache_data[(offset+1)*8 +: 8] = data_in[15:8];
                end
                3'b010: begin
                    new_cache_data[offset*8 +: 8] = data_in[7:0];
                    new_cache_data[(offset+1)*8 +: 8] = data_in[15:8];
                    new_cache_data[(offset+2)*8 +: 8] = data_in[23:16];
                    new_cache_data[(offset+3)*8 +: 8] = data_in[31:24];
                end
                default: begin end
            endcase
        end
    end

    integer k;
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            timer <= 0;
            hit_count <= 0;
            miss_count <= 0;
            mem_access_count <= 0;
            miss_handled <= 0;
            for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 4; j = j + 1) begin
                    cache_valid[i][j] <= 0;
                    cache_dirty[i][j] <= 0;
                    cache_lru[i][j] <= j;
                end
            end
            // main_mem array initialization handled by $readmemh in initial block
        end else begin
            if (state == IDLE && (mem_re || mem_we) && cache_hit) begin
                miss_handled <= 0;
            end else if (state == UPDATE) begin
                miss_handled <= 1;
            end

            case (state)
                IDLE: begin
                    if (mem_re || mem_we) begin
                        if (cache_hit) begin
                            if (!miss_handled) begin
                                mem_access_count <= mem_access_count + 1;
                                hit_count <= hit_count + 1;
                            end
                            if (mem_we) begin
                                cache_data[set_idx][hit_way] <= new_cache_data;
                                cache_dirty[set_idx][hit_way] <= 1'b1;
                            end
                            // Update LRU on hit
                            for (k = 0; k < 4; k = k + 1) begin
                                if (k == hit_way) cache_lru[set_idx][k] <= 2'd3;
                                else if (cache_lru[set_idx][k] > cache_lru[set_idx][hit_way]) 
                                    cache_lru[set_idx][k] <= cache_lru[set_idx][k] - 1;
                            end
                        end else begin
                            if (!miss_handled) begin
                                miss_count <= miss_count + 1;
                                mem_access_count <= mem_access_count + 1;
                                if (cache_valid[set_idx][lru_way] && cache_dirty[set_idx][lru_way]) begin
                                    state <= MEM_WB;
                                    timer <= MEM_LATENCY;
                                end else begin
                                    state <= MEM_FETCH;
                                    timer <= MEM_LATENCY;
                                end
                            end
                        end
                    end
                end
                
                MEM_WB: begin
                    if (timer == 1) begin
                        main_mem[{cache_tag[set_idx][lru_way][7:0], set_idx}] <= cache_data[set_idx][lru_way];
                        state <= MEM_FETCH;
                        timer <= MEM_LATENCY;
                    end else begin
                        timer <= timer - 1;
                    end
                end
                
                MEM_FETCH: begin
                    if (timer == 1) begin
                        fetched_data <= main_mem[block_addr[9:0]];
                        state <= UPDATE;
                    end else begin
                        timer <= timer - 1;
                    end
                end
                
                UPDATE: begin
                    cache_data[set_idx][lru_way] <= fetched_data;
                    cache_tag[set_idx][lru_way] <= tag_in;
                    cache_dirty[set_idx][lru_way] <= 1'b0;
                    cache_valid[set_idx][lru_way] <= 1'b1;
                    
                    // Update LRU
                    for (k = 0; k < 4; k = k + 1) begin
                        if (k == lru_way) cache_lru[set_idx][k] <= 2'd3;
                        else if (cache_lru[set_idx][k] > cache_lru[set_idx][lru_way]) 
                            cache_lru[set_idx][k] <= cache_lru[set_idx][k] - 1;
                    end
                    
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
