module control_logic #(
    parameter W_SIZE = 32
) (
  //TODO: need to add inst_fd as an input in order to cover for jal special case calculate the pcSel.
    input [W_SIZE-1:0] inst_w,
    input [W_SIZE-1:0] inst_fd,
    input BrTaken,
    input JalSpecial,
    input BIOSRest,
    output [1:0] PCSel, 
    output Flush,
    output RegWEn, 
    output CSRWen,
    output [2:0] WBSel
);
    localparam 
    ADD = 4'b0_000,
    SUB = 4'b1_000,
    AND = 4'b0_111,
    OR  = 4'b0_110,
    XOR = 4'b0_100,
    SLL = 4'b0_001,
    SRL = 4'b0_101,
    SRA = 4'b1_101,
    SLT = 4'b0_010,
    SLTU= 4'b0_011;

    reg [W_SIZE-1:0] out;
    assign result = out;

    always @(*) begin
      case(ALUSel)
        ADD:    out = a + b;
        SUB:    out = a - b;
        AND:    out = a & b;
        OR:     out = a | b;
        XOR:    out = a ^ b;
        SLL:    out = a << b[4:0];
        SRL:    out = a >> b[4:0];
        SRA:    out = $signed(a) >>> b[4:0];
        SLT:    out = $signed(a) < $signed(b) ? 'd1 : 'd0;
        SLTU:   out = a < b ? 'd1 : 'd0;
        default: out = b; // Need to only pass b for the lui instruction
      endcase
    end


endmodule