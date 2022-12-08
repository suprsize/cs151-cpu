`timescale 1ns/1ns
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
        .we()
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
        
        rst = 1;
        @(posedge clk); #1;
        rst = 0;

        ra0 = 32'h00000000;
        #1;
        assert(hit0 == 1'b0); // compulsory miss

        ra0 = 32'h00000000;
        #1;
        assert(hit0 == 1'b1); // cache hit
        
        `ifndef IVERILOG
            $vcdplusoff;
        `endif
        $finish();
    end
endmodule
