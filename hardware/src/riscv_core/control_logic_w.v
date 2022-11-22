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
    ALU_P           = 2'd1,
    JAL_SPECIAL_P   = 2'd2,
    BIOS_REST_P     = 2'd3;

    localparam
    PC_PLUS_4_W   = 3'd0
    ALU_RESULT_W    = 3'd1,
    DMEM_W          = 3'd2,
    UART_W          = 3'd3,
    UART_SIGS_W     = 3'd4,
    BIOS_W          = 3'd5,
    CYC_COUNTER_W   = 3'd6,
    INST_COUNTER_W  = 3'd7;




    

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
    reg [2:0] write_back_sel;
    reg reset_counters;

    assign Flush = BrTaken;

    assign PCSel  = pc_sel;
    assign RegWEn = reg_write_enable;
    assign CSRWen = csr_write_enable;
    assign WBSel = write_back_sel;
    assign ResetCounters = reset_counters;


   

    always @(*) begin
      case(type_xm) 
        R_TYPE: begin
          pc_sel = 
          reg_write_enabl = 
          csr_write_enabl = 
          write_back_sel = 
          reset_counters = 
        end

        I_TYPE: begin
          pc_sel = PC_PLUS_4;
          reg_write_enabl = TRUE;
          csr_write_enabl = FALSE;
          write_back_sel = ALU_RESULT
          reset_counters = 
        end

        S_TYPE: begin
          br_sel = 'd0; //xx
          branch_taken = FALSE;
          a_sel = RS1_A;
          b_sel = IMM_B;
          alu_sel = ADD;
          //TODO: NEED TO MAKE SURE I SELECT THE CORRECT MEMEORY AND HANDSHAKE
          mem_rw = Addr[31:30] == 2'd00 && Addr[28];
          imem_rw = BIOS_mode && Addr[31:29] == 3'b001;
          UART_write_valid = Addr == UART_TRANSMITTER_ADDR;
          UART_ready_to_receive = FALSE;
        end

        B_TYPE: begin
          br_sel = funct3_xm;
          branch_taken = Br;
          a_sel = PC_XM_A;
          b_sel = IMM_B;
          alu_sel = ADD;
          mem_rw = FALSE;
          imem_rw = FALSE;
          UART_write_valid = FALSE;
          UART_ready_to_receive = FALSE;
        end

        U_TYPE: begin
          br_sel = 'd0; //xx
          branch_taken = FALSE;
          a_sel = opcode_xm == AUIPC_OPCODE;
          b_sel = IMM_B;
          alu_sel = ADD;
          mem_rw = FALSE;
          imem_rw = FALSE;
          UART_write_valid = FALSE;
          UART_ready_to_receive = FALSE;
        end

        
        default: begin
          br_sel = 'd0; //xx
          branch_taken = FALSE;
          a_sel = PC_XM_A;
          b_sel = IMM_B;
          alu_sel = ADD;
          mem_rw = FALSE;
          imem_rw = FALSE;
          UART_write_valid = FALSE;
          UART_ready_to_receive = FALSE;
        end

      endcase
    end



endmodule
