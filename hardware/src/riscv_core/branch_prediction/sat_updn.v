/*
A saturating incrementer/decrementer.
Adds +/-1 to the input with saturation to prevent overflow.
*/

module sat_updn #(
    parameter WIDTH=2
) (
    input [WIDTH-1:0] in,
    input up,
    input dn,

    output [WIDTH-1:0] out
);

    // TODO: Your code
    localparam 
    MIN = {WIDTH{1'b0}},
    MAX = {WIDTH{1'b1}};

    reg [WIDTH-1:0] sat_cnt;
    assign out = sat_cnt;

    always @(*) begin 
        if (up) sat_cnt = (in == MAX) ? MAX : in + 'b1;
        else if (dn) sat_cnt = (in == MIN) ? MIN : in - 'b1;
        else sat_cnt = 'b0;
    end

endmodule
