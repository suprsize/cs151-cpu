module branch_comp #(
    parameter W_SIZE = 32
) (
    input [W_SIZE-1:0] a,
    input [W_SIZE-1:0] b,
    input BrUn,
    output BrEq,
    output BrLt
);

    assign BrEq = BrUn? a == b  : $signed(a) == $signed(b);
    assign BrLt = BrUn? a < b   : $signed(a) < $signed(b);

endmodule
