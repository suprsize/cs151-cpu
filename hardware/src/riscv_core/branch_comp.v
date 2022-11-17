module branch_comp #(
    parameter W_SIZE = 32
) (
    input [W_SIZE-1:0] a,
    input [W_SIZE-1:0] b,
    input [2:0] BrSel,
    output BrTaken
);
    localparam 
    BEQ     = 3'd0,
    BNE     = 3'd3,
    BLT     = 3'd4,
    BLTU    = 3'd6,
    BGE     = 3'd5,
    BGEU    = 3'd7;


    wire BrUn, BrEq, BrLt;
    assign BrUn = (BrSel == BLTU || BrSel == BGEU);
    assign BrEq = BrUn? a == b  : $signed(a) == $signed(b);
    assign BrLt = BrUn? a < b   : $signed(a) < $signed(b);

    reg branch;
    assign BrTaken = branch;
    
    always @(*) begin
        case(BrSel)
            BEQ: branch = BrEq;
            BNE: branch = !BrEq;
            BLT,
            BLTU: branch = BrLt;
            BGE, 
            BGEU: branch = !BrLt & BrEq;
            default: branch = 1'd0;
        endcase
    end

endmodule
