module branch_comp #(
    parameter W_SIZE = 32
) (
    input [W_SIZE-1:0] a,
    input [W_SIZE-1:0] b,
    input [2:0] BrSel,
    output Br
);
    localparam 
    BEQ  = 3'b000,
    BNE  = 3'b001,
    BLT  = 3'b100,
    BGE  = 3'b101,
    BLTU = 3'b110,
    BGEU = 3'b111;


    wire BrUn, BrEq, BrLt;
    assign BrUn = (BrSel == BLTU || BrSel == BGEU);
    assign BrEq = BrUn? a == b  : $signed(a) == $signed(b);
    assign BrLt = BrUn? a < b   : $signed(a) < $signed(b);

    reg branch;
    assign Br = branch;
    
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
