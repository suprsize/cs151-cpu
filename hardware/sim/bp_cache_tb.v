`timescale 1ns/1ns

`define SECOND 1000000000
`define MS 1000000
`define CLK_PERIOD 8

module bp_cache_tb();
    // Generate 125 Mhz clock
    reg clk = 0;
    always #(`CLK_PERIOD/2) clk = ~clk;

    // I/O
    localparam AWIDTH = 32;
    localparam DWIDTH = 2; 
    localparam LINES = 8;
    reg rst;
    reg [AWIDTH-1:0] ra0, ra1, wa;
    wire [DWIDTH-1:0] dout0, dout1;
    reg [DWIDTH-1:0] din;
    wire hit0, hit1;
    reg we;

    bp_cache #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .LINES(LINES)
    ) DUT (
        .clk(clk),
        .reset(rst),
        .ra0(ra0),
        .dout0(dout0),
        .hit0(hit0),
        .ra1(ra1),
        .dout1(dout1),
        .hit1(hit1),
        .wa(wa),
        .din(din),
        .we(we)
    );

    initial begin
        `ifdef IVERILOG
            $dumpfile("bp_cache_tb.fst");
            $dumpvars(0, bp_cache_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
            $vcdplusmemon;
        `endif

        ra0 = 32'h0000_0007;
        #(2);
        assert(hit0 == 1'b0); // compulsory miss

        // write
        wa = 32'h0000_0007;
        din = 2'b11;
        we = 1'b1;
        @(posedge clk); #2;

        assert(hit0 == 1'b1); // cache hit
        assert(dout0 == 2'b11); // correct data is read

        din = 2'b01;
        @(posedge clk); #2;

        assert(hit0 == 1'b1); // cache hit
        assert(dout0 == 2'b01); // updated data due to second write

        ra1 = 32'h0000_0001;
        #(2);
        assert(hit1 == 1'b0); // compulsory miss

        // write
        wa = 32'h0000_0001;
        din = 2'b10;
        we = 1'b1;
        @(posedge clk); #2;

        assert(hit1 == 1'b1); // cache hit
        assert(dout1 == 2'b10); // correct data is read

        ra1 = 32'h1111_0007;
        #(2);
        assert(hit1 == 1'b0); // cache miss bc different tag

        // write 
        wa = 32'h1111_0007;
        din = 2'b00;
        we = 1'b1;
        @(posedge clk); #2;

        assert(hit1 == 1'b1); // should be a hit
        assert(dout1 == 2'b00); // eviction
        
        `ifndef IVERILOG
            $vcdplusoff;
        `endif
        $finish();
    end
endmodule
