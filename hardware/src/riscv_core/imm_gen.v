module imm_gen #(
    parameter W_SIZE = 32
) (
    input [W_SIZE-1:0] inst,
    input [2:0] ImmSel,
    output [W_SIZE-1:0] imm
);
    localparam 
    R_TYPE = 3'd0,
    I_TYPE = 3'd1,
    S_TYPE = 3'd2,
    B_TYPE = 3'd3,
    U_TYPE = 3'd4,
    J_TYPE = 3'd5, 
    C_TYPE = 3'd6;

    reg [W_SIZE-1:0] out;
    assign imm = out;

    always @(*) begin
      case(ImmSel)
        I_TYPE: out = { {20{inst[31]}}, inst[31:20] };
        S_TYPE: out = { {20{inst[31]}}, inst[31:25], inst[11:7] };
        B_TYPE: out = { {20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0 };
        U_TYPE: out = { inst[31:12], 12'b0 };
        J_TYPE: out = { {10{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0 };
        C_TYPE: out = { {27{inst[19]}}, inst[19:15] };
        default: out = 'd0;
      endcase
    end


endmodule
