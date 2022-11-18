module inst_splitter #(
    parameter W_SIZE = 32
) (
    input [W_SIZE-1:0] inst,
    output [6:0] opcode, 
    output [4:0] rd, 
    output [2:0] funct3,
    output [4:0] rs1, 
    output [4:0] rs2,
    output [6:0] funct7,
    output [2:0] inst_type
);

    localparam
    R_TYPE = 3'd0, 
    I_TYPE = 3'd1,
    S_TYPE = 3'd2,
    B_TYPE = 3'd3,
    U_TYPE = 3'd4,
    J_TYPE = 3'd5;

    localparam
    R_OPCODE        = 7'h33,
    I_OPCODE        = 7'h13,
    LOADING_OPCODE  = 7'h03,
    JALR_OPCODE     = 7'h67,
    CSR_OPCODE      = 7'h73,
    S_OPCODE        = 7'h23,
    B_OPCODE        = 7'h63,
    LUI_OPCODE      = 7'h37,
    AUIPC_OPCODE    = 7'h17,
    JAL_OPCODE      = 7'h6f;

    reg type;

    assign opcode = inst[6:0];
    assign rd = inst[11:7];
    assign func3 = inst[14:12];
    assign rs1 = inst[19:15];
    assign rs2 = inst[24:20];
    assign funct7 = inst[31:25];
    assign inst_type = type;

    always @(*) begin
      case(opcode)
        R_OPCODE: type = R_TYPE;
        LOADING_OPCODE,
        JALR_OPCODE,
        CSR_OPCODE,
        I_OPCODE: type = I_TYPE;
        S_OPCODE: type = S_TYPE;
        B_OPCODE: type = B_TYPE;
        LUI_OPCODE,
        AUIPC_OPCODE: type = U_TYPE;
        JAL_OPCODE: type = J_TYPE;
        default: type = R_TYPE;     // COULD BE A PROBLOM
      endcase
    end


endmodule
