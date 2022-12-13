module f_logic #(
    parameter W_SIZE = 32
) (
    input [6:0] opcode_d,
    input BIOSRest,
    input br_pred_taken,
    output [1:0] PCSel, 

    );

    localparam
    PC_PLUS_4_P     = 2'd0,
    RS1_PLUS_IMM_P  = 2'd1,
    PC_PLUS_IMM_P   = 2'd2,
    BIOS_REST_P     = 2'd3;

    localparam
    I_OPCODE        = 7'h13,
    LOAD_OPCODE     = 7'h03,
    JALR_OPCODE     = 7'h67,
    CSR_OPCODE      = 7'h73,
    JAL_OPCODE      = 7'h6f;

    reg [1:0] pc_sel;  
    assign PCSel  = pc_sel;

    wire is_jal_spec =  opcode_fd == JAL_OPCODE;
    wire is_jalr_spec = opcode_fd == JALR_OPCODE;

    always @(*) begin
      if (BIOSRest)                           pc_sel = BIOS_REST_P;
      else if (is_jalr_spec)                  pc_sel = RS1_PLUS_IMM_P;
      else if (is_jal_spec || br_pred_taken)  pc_sel = PC_PLUS_IMM_P;
      else                                    pc_sel = PC_PLUS_4_P;
    end
endmodule
