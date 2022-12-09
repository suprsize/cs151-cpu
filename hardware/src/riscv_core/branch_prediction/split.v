/*
A cache module for storing branch prediction data.

Inputs: 2 asynchronous read ports and 1 synchronous write port.
Outputs: data and cache hit (for each read port)
*/

module split #(
    parameter AWIDTH=32,  // Address bit width
    parameter DWIDTH=32,  // Data bit width
    parameter LINES=128   // Number of cache lines
    parameter INDEXWIDTH=$clog2(LINES),
    parameter TAGWIDTH=AWIDTH - INDEXWIDTH,
    parameter ENTRYWIDTH= DWIDTH + TAGWIDTH + 1,
    parameter CACHEWIDTH= 1 + (ENTRYWIDTH << 1),
) (
    input [CACHEWIDTH-1:0] cache_line,
    input [AWIDTH-1:0] wa,
    input [DWIDTH-1:0] din,
    output [CACHEWIDTH-1:0] out_cache_line
);
    localparam
    LRU0 = 1'b0,
    LRU1 = 1'b1;
    // each cache line will contain the fifo bit, and tag, valid bit, and data for two entries

    
    wire [INDEXWIDTH-1:0] index_wa = wa[INDEXWIDTH-1:0];
    wire [TAGWIDTH-1:0] tag_wa = wa[AWIDTH-1:INDEXWIDTH];
    wire [ENTRYWIDTH-1:0] new_entry = {din, tag_wa, 1'b1};
    
	wire [ENTRYWIDTH-1:0] entry_1 = cache_line[ENTRYWIDTH-1:0];
	wire [ENTRYWIDTH-1:0] entry_2 = cache_line[CACHEWIDTH-2:ENTRYWIDTH];
	wire fifo_flag = cache_line[CACHEWIDTH-1];
	wire entry_v_1 = entry_1[0];
	wire entry_v_2 = entry_2[0];
	wire [TAGWIDTH-1:0] entry_tag_1 = entry_1[TAGWIDTH:1];
	wire [TAGWIDTH-1:0] entry_tag_2 = entry_2[TAGWIDTH:1];
	wire [DWIDTH-1:0] data_entry_1 = entry_1[ENTRYWIDTH-1:TAGWIDTH+1];
	wire [DWIDTH-1:0] data_entry_2 = entry_2[ENTRYWIDTH-1:TAGWIDTH+1];
	
	wire e_hit_1 = (entry_tag_1 == tag_wa) && entry_v_1;
	wire e_hit_2 = (entry_tag_2 == tag_wa) && entry_v_2;
	wire [CACHEWIDTH-1:0] first_entry_replaced  = {1'b1, entry_2, new_entry};
	wire [CACHEWIDTH-1:0] second_entry_replaced = {1'b0, new_entry, entry_1};

    reg [CACHEWIDTH-1:0] out;
    assign out_cache_line = out;

    always @(*) begin
        if (e_hit_1) 		out = first_entry_replaced;
        else if (e_hit_2) 	out = second_entry_replaced;
        else begin
            case (fifo_flag)
                LRU0: out = first_entry_replaced;
                LRU1: out = second_entry_replaced;
            endcase 
        end
    end
            

endmodule
