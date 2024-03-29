module edge_detector #(
    parameter WIDTH = 1
)(
    input clk,
    input [WIDTH-1:0] signal_in,
    output [WIDTH-1:0] edge_detect_pulse
);
    // TODO: implement a multi-bit edge detector that detects a rising edge of 'signal_in[x]'
    // and outputs a one-cycle pulse 'edge_detect_pulse[x]' at the next clock edge
    // Feel free to use as many number of registers you like

    // Remove this line once you create your edge detector
    reg [WIDTH - 1:0] a= 0;
    always @(posedge clk) begin
		a <= signal_in;
    end
    assign edge_detect_pulse = signal_in & (~a);
    

endmodule
