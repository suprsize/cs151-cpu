module branch_comp #(
    parameter W_SIZE = 32
) (
    input [W_SIZE-1:0] a,
    input [W_SIZE-1:0] b,
    input [2:0] BrSel,
    output BrTaken
);

    wire BrUn, BrEq, BrLt;
    assign = BrSel == 3'd6 || BrSel == 3'd7;
    assign BrEq = BrUn? a == b  : $signed(a) == $signed(b);
    assign BrLt = BrUn? a < b   : $signed(a) < $signed(b);

endmodule
