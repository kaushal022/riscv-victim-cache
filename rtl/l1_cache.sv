`timescale 1ns / 1ps

module l1_cache (
    input  wire        clk,
    input  wire        rst,
    
    // CPU Interface
    input  wire [31:0] cpu_addr,
    input  wire [31:0] cpu_data_in,
    input  wire [2:0]  cpu_byte_en,
    input  wire        cpu_we,
    input  wire        cpu_re,
    output reg  [31:0] cpu_data_out,
    output wire        l1_hit,
    
    // Cache Controller Interface
    input  wire        refill_en,
    input  wire [127:0]refill_data,
    input  wire [23:0] refill_tag,
    input  wire        refill_dirty,
    
    output wire [127:0]evict_data,
    output wire [23:0] evict_tag,
    output wire        evict_valid,
    output wire        evict_dirty
);

    reg [127:0] data_array [0:15];
    reg [23:0]  tag_array  [0:15];
    reg         valid_array[0:15];
    reg         dirty_array[0:15];

    wire [3:0]  idx = cpu_addr[7:4];
    wire [23:0] tag = cpu_addr[31:8];
    wire [3:0]  offset = cpu_addr[3:0];

    assign l1_hit = valid_array[idx] && (tag_array[idx] == tag) && (cpu_re || cpu_we);
    
    assign evict_data  = data_array[idx];
    assign evict_tag   = tag_array[idx];
    assign evict_valid = valid_array[idx];
    assign evict_dirty = dirty_array[idx];

    wire [127:0] hit_block = data_array[idx];
    
    wire [7:0] hb_bytes [0:15];
    genvar g;
    generate
        for (g=0; g<16; g=g+1) begin : gen_hb
            assign hb_bytes[g] = hit_block[g*8 +: 8];
        end
    endgenerate

    wire [31:0] word_data = (offset <= 12) ? {hb_bytes[offset+3], hb_bytes[offset+2], hb_bytes[offset+1], hb_bytes[offset]} : 32'd0;

    always @(*) begin
        cpu_data_out = 32'd0;
        if (cpu_re && l1_hit) begin
            case (cpu_byte_en)
                3'b000: cpu_data_out = {{24{hb_bytes[offset][7]}}, hb_bytes[offset]};
                3'b001: cpu_data_out = {{16{hb_bytes[offset+1][7]}}, hb_bytes[offset+1], hb_bytes[offset]};
                3'b010: cpu_data_out = word_data;
                3'b100: cpu_data_out = {24'd0, hb_bytes[offset]};
                3'b101: cpu_data_out = {16'd0, hb_bytes[offset+1], hb_bytes[offset]};
                default: cpu_data_out = word_data;
            endcase
        end
    end

    reg [127:0] new_l1_data;
    always @(*) begin
        new_l1_data = data_array[idx];
        if (cpu_we) begin
            case (cpu_byte_en)
                3'b000: new_l1_data[offset*8 +: 8] = cpu_data_in[7:0];
                3'b001: begin
                    new_l1_data[offset*8 +: 8] = cpu_data_in[7:0];
                    new_l1_data[(offset+1)*8 +: 8] = cpu_data_in[15:8];
                end
                3'b010: begin
                    new_l1_data[offset*8 +: 8] = cpu_data_in[7:0];
                    new_l1_data[(offset+1)*8 +: 8] = cpu_data_in[15:8];
                    new_l1_data[(offset+2)*8 +: 8] = cpu_data_in[23:16];
                    new_l1_data[(offset+3)*8 +: 8] = cpu_data_in[31:24];
                end
                default: begin end
            endcase
        end
    end

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i=0; i<16; i=i+1) begin
                valid_array[i] <= 0;
                dirty_array[i] <= 0;
                tag_array[i]   <= 24'd0;  // FIX: Explicitly clear the tags!
                data_array[i]  <= 128'd0; // FIX: Explicitly clear the data!
            end
        end else begin
            if (refill_en) begin
                data_array[idx] <= refill_data;
                tag_array[idx] <= refill_tag;
                valid_array[idx] <= 1'b1;
                dirty_array[idx] <= refill_dirty;
            end else if (cpu_we && l1_hit) begin
                data_array[idx] <= new_l1_data;
                dirty_array[idx] <= 1'b1;
            end
        end
    end
endmodule
