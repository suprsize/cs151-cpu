module control_logic #(
    parameter W_SIZE = 32
) (
    input [W_SIZE-1:0] inst_xm,
    input BrEq, 
    input BrLt,
    output BrUn,
    output ASel,
    output BSel,
    output MemRW, 
    output IMemWE,
    output [3:0] ALUSel,
    output UART_Write_valid,
    output UART_Ready_To_Receive
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
