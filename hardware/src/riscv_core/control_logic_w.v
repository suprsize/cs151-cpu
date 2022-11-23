module w_logic #(
    parameter W_SIZE = 32
) (
  //TODO: need to add inst_fd as an input in order to cover for jal special case calculate the pcSel.
    input [W_SIZE-1:0] inst_w,
    input [W_SIZE-1:0] inst_fd,
    input BrTaken,
    input BIOSRest,
    output Flush,
    output [1:0] PCSel, 
    output RegWEn, 
    output CSRWen,
    output CSRSel,
    output [2:0] WBSel,
    output ResetCounters
);


    localparam
    R_TYPE = 3'd0, 
    I_TYPE = 3'd1,
    S_TYPE = 3'd2,
    B_TYPE = 3'd3,
    U_TYPE = 3'd4,
    J_TYPE = 3'd5,
    C_TYPE = 3'd6;

    localparam
    FALSE = 1'd0,
    TRUE = 1'd1;

    localparam
    PC_PLUS_4_P     = 2'd0,
    ALU_OUTPUT_P    = 2'd1,
    JAL_SPECIAL_P   = 2'd2,
    BIOS_REST_P     = 2'd3;

    localparam
    PC_PLUS_4_W     = 3'd0,
    ALU_OUTPUT_W    = 3'd1,
    DMEM_W          = 3'd2,
    UART_W          = 3'd3,
    UART_SIGS_W     = 3'd4,
    BIOS_W          = 3'd5,
    CYC_COUNTER_W   = 3'd6,
    INST_COUNTER_W  = 3'd7;

    localparam
    I_OPCODE        = 7'h13,
    LOADING_OPCODE  = 7'h03,
    JALR_OPCODE     = 7'h67,
    CSR_OPCODE      = 7'h73,
    JAL_OPCODE      = 7'h6f;

    localparam
    CSRWI_FUNC3     = 3'h5;

    

    wire [6:0] opcode_w; 
    wire [4:0] rd_w;
    wire [2:0] funct3_w;
    wire [4:0] a_w, b_w;
    wire [6:0] funct7_w;
    wire [2:0] type_w;
    inst_splitter w_split(
        .inst(inst_w),
        .opcode(opcode_w),
        .rd(rd_w),
        .funct3(funct3_w),
        .rs1(a_w), .rs2(b_w),
        .funct7(funct7_w),
        .inst_type(type_w)
    );

    reg [1:0] pc_sel;
    reg reg_write_enable;
    reg csr_write_enable;
    reg csr_sel;
    reg [2:0] write_back_sel;
    reg reset_counters;


    wire opcode_w = inst_w[6:0];
    wire is_jal =  opcode_w == JAL_OPCODE;
    wire is_load = opcode_w == LOADING_OPCODE;
    wire is_imm = opcode_w == I_OPCODE;
    wire is_jalr = opcode_w == JALR_OPCODE;
    wire is_csr = opcode_w == CSR_OPCODE;
    wire is_csr_imm = is_csr && funct3_w == CSRWI_FUNC3;

    wire load_result = ALU; // SHOULD BE THE RESULT OF EITHER DMEM, BIOS, UART

    assign Flush = BrTaken;
    assign CSRSel = is_csr_imm;   // 0->RS1 AND 1->IMM
    assign CSRWen = is_csr;  //NEEDS TO COVER CSR TO MAKE SURE IT IS THE CORRECT ADDRESS

    assign PCSel  = pc_sel;
    assign RegWEn = reg_write_enable;
    assign WBSel = write_back_sel;
    assign ResetCounters = reset_counters;


   

    always @(*) begin
      case(type_xm) 
        R_TYPE: begin
          pc_sel = PC_PLUS_4_P;
          reg_write_enable = TRUE;
          write_back_sel = ALU_OUTPUT_W;
          reset_counters = FALSE;
        end

        I_TYPE: begin
          pc_sel = PC_PLUS_4_P;
          reg_write_enable = !csr_write_enable;
          if (is_imm) write_back_sel = ALU_OUTPUT_W;
          else if (is_load) write_back_sel = load_result; // load_result needs to be correct
          else write_back_sel = PC_PLUS_4_W;  // Covers JALR case.

          reset_counters = FALSE;     //NEEDS TO COVER THIS TOO
        end

        S_TYPE: begin
          pc_sel = PC_PLUS_4_P;
          reg_write_enable = FALSE;
          write_back_sel = PC_PLUS_4_W;
          reset_counters = FALSE;     //NEEDS TO COVER THIS TOO
        end

        B_TYPE: begin
          pc_sel = BrTaken;
          reg_write_enable = FALSE;
          write_back_sel = 'd0;
          reset_counters = FALSE;
        end

        U_TYPE: begin
          pc_sel = PC_PLUS_4_P;
          reg_write_enable = TRUE;
          write_back_sel = ALU_OUTPUT_W;
          reset_counters = FALSE;     //NEEDS TO COVER THIS TOO
        end

        
        default: begin
          pc_sel = ALU_OUTPUT_P;
          reg_write_enable = TRUE;
          write_back_sel = PC_PLUS_4_W;
          reset_counters = FALSE;     //NEEDS TO COVER THIS TOO
        end

      endcase
    end



endmodule
