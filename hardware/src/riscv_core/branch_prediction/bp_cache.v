/*
A cache module for storing branch prediction data.

Inputs: 2 asynchronous read ports and 1 synchronous write port.
Outputs: data and cache hit (for each read port)
*/

module bp_cache #(
    parameter AWIDTH=32,  // Address bit width
    parameter DWIDTH=32,  // Data bit width
    parameter LINES=128   // Number of cache lines
) (
    input clk,
    input reset,

    // IO for 1st read port
    input [AWIDTH-1:0] ra0,
    output [DWIDTH-1:0] dout0,
    output hit0,

    // IO for 2nd read port
    input [AWIDTH-1:0] ra1,
    output [DWIDTH-1:0] dout1,
    output hit1,

    // IO for write port
    input [AWIDTH-1:0] wa,
    input [DWIDTH-1:0] din,
    input we

);

    /*
    // TODO: Your code
    
    // Using TIO model to build direct-mapped cache
    // No byte offset bits b/c data is just 2-bit saturating counter
    localparam 
    INDEXWIDTH = $clog2(LINES),
    TAGWIDTH = AWIDTH - INDEXWIDTH,
    CACHEWIDTH = TAGWIDTH + 1 + DWIDTH; // each cache line will contain the tag, valid bit, and data (2-bit saturating counter)

    reg [CACHEWIDTH-1:0] buffer [LINES-1:0];
    integer k; 
    initial begin
        for (k = 0; k < LINES; k = k + 1) begin
            buffer[k] = 'b0;
        end
    end

    reg [CACHEWIDTH-1:0] buf0;
    reg [CACHEWIDTH-1:0] buf1;

    wire [TAGWIDTH-1:0] tag_ra0 = ra0[AWIDTH-1:INDEXWIDTH];
    wire [TAGWIDTH-1:0] tag_ra1 = ra1[AWIDTH-1:INDEXWIDTH];

    wire [TAGWIDTH-1:0] tag_buf0 = buf0[CACHEWIDTH-1:CACHEWIDTH-TAGWIDTH];
    wire [TAGWIDTH-1:0] tag_buf1 = buf1[CACHEWIDTH-1:CACHEWIDTH-TAGWIDTH];

    wire valid_buf0 = buf0[DWIDTH];
    wire valid_buf1 = buf1[DWIDTH];

    wire [DWIDTH-1:0] data_buf0 = buf0[DWIDTH-1:0];
    wire [DWIDTH-1:0] data_buf1 = buf1[DWIDTH-1:0];

    assign dout0 = hit0 ? data_buf0 : 'b0;
    assign dout1 = hit1 ? data_buf1 : 'b0;
    assign hit0  = valid_buf0 && tag_buf0 == tag_ra0; // check tags are equal and valid bit on
    assign hit1  = valid_buf1 && tag_buf1 == tag_ra1;

    always @(*) begin
        buf0 = buffer[ra0[INDEXWIDTH-1:0]];
        buf1 = buffer[ra1[INDEXWIDTH-1:0]];
    end


    genvar i;
    generate
	    for (i = 0; i < LINES; i = i + 1) begin
	        always @(posedge clk) begin
		        if (reset) buffer[i] <= 'b0;
		        else if (we && wa[INDEXWIDTH-1:0] == i) buffer[i] <= {wa[AWIDTH-1:INDEXWIDTH], 1'b1, din};
		         
            end
        end    
    endgenerate
    */

    // Using TIO model to build direct-mapped cache
    // No byte offset bits b/c data is just 2-bit saturating counter
    localparam 
    INDICES = LINES >> 1,
    INDEXWIDTH = $clog2(INDICES),
    TAGWIDTH = AWIDTH - INDEXWIDTH,
    CACHEWIDTH = 1 + TAGWIDTH + 1 + DWIDTH + TAGWIDTH + 1 + DWIDTH,
    LRU0 = 1'b0,
    LRU1 = 1'b1;
    // each cache line will contain the fifo bit, and tag, valid bit, and data for two entries

    reg [CACHEWIDTH-1:0] buffer [INDICES-1:0];

    integer j; 
    initial begin
        for (j = 0; j < INDICES; j = j + 1) begin
            buffer[j] = 'b0;
        end
    end

    reg [CACHEWIDTH-1:0] buf0;
    reg [CACHEWIDTH-1:0] buf1;

    wire [TAGWIDTH-1:0] tag_ra0 = ra0[AWIDTH-1:INDEXWIDTH];
    wire [TAGWIDTH-1:0] tag_ra1 = ra1[AWIDTH-1:INDEXWIDTH];

    wire [TAGWIDTH-1:0] tag_buf0_1 = buf0[CACHEWIDTH-2:CACHEWIDTH-1-TAGWIDTH];
    wire [TAGWIDTH-1:0] tag_buf0_2 = buf0[TAGWIDTH+DWIDTH:1+DWIDTH];
    wire [TAGWIDTH-1:0] tag_buf1_1 = buf1[CACHEWIDTH-2:CACHEWIDTH-1-TAGWIDTH];
    wire [TAGWIDTH-1:0] tag_buf1_2 = buf1[TAGWIDTH+DWIDTH:1+DWIDTH];

    wire valid_buf0_1 = buf0[CACHEWIDTH-2-TAGWIDTH];
    wire valid_buf0_2 = buf0[DWIDTH];
    wire valid_buf1_1 = buf1[CACHEWIDTH-2-TAGWIDTH];
    wire valid_buf1_2 = buf1[DWIDTH];

    wire hit0_1 = (tag_buf0_1 == tag_ra0) && valid_buf0_1;
    wire hit0_2 = (tag_buf0_2 == tag_ra0) && valid_buf0_2;
    wire hit1_1 = (tag_buf1_1 == tag_ra1) && valid_buf1_1;
    wire hit1_2 = (tag_buf1_2 == tag_ra1) && valid_buf1_2;

    wire [DWIDTH-1:0] data_buf0_1 = buf0[TAGWIDTH+DWIDTH+DWIDTH:TAGWIDTH+1+DWIDTH];
    wire [DWIDTH-1:0] data_buf0_2 = buf0[DWIDTH-1:0];
    wire [DWIDTH-1:0] data_buf1_1 = buf1[TAGWIDTH+DWIDTH+DWIDTH:TAGWIDTH+1+DWIDTH];
    wire [DWIDTH-1:0] data_buf1_2 = buf1[DWIDTH-1:0];

    assign dout0 = hit0_1 ? data_buf0_1 : (hit0_2 ? data_buf0_2 : 'b0);
    assign dout1 = hit1_1 ? data_buf1_1 : (hit1_2 ? data_buf1_2 : 'b0);
    assign hit0  = hit0_1 || hit0_2;
    assign hit1  = hit1_1 || hit1_2;

    always @(*) begin
        buf0 = buffer[ra0[INDEXWIDTH-1:0]];
        buf1 = buffer[ra1[INDEXWIDTH-1:0]];
    end

    reg [CACHEWIDTH-1:0] cache_line;

    genvar i;
    generate
	    for (i = 0; i < INDICES; i = i + 1) begin
	        always @(posedge clk) begin
		        if (reset) buffer[i] <= 'b0;
		        else if (we && wa[INDEXWIDTH-1:0] == i) begin
                    cache_line <= buffer[i];
                    case (cache_line[CACHEWIDTH-1])
                        LRU0: buffer[i] <= {1'b1, wa[AWIDTH-1:INDEXWIDTH], 1'b1, din, cache_line[TAGWIDTH+DWIDTH:0]};
                        LRU1: buffer[i] <= {1'b0, cache_line[CACHEWIDTH-2:TAGWIDTH+1+DWIDTH], wa[AWIDTH-1:INDEXWIDTH], 1'b1, din};
                        default: buffer[i] <= {1'b1, wa[AWIDTH-1:INDEXWIDTH], 1'b1, din, cache_line[TAGWIDTH+DWIDTH:0]};
                    endcase 
                end   
            end
        end    
    endgenerate
endmodule
