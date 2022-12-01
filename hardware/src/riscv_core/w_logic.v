module w_logic #(
    parameter W_SIZE = 32
) (
    input [W_SIZE-1:0] inst_w,
    input [W_SIZE-1:0] inst_fd, // Need to add inst_fd as an input in order to cover for jal special case calculate the pcSel.
    input [W_SIZE-1:0] Addr,  //ALU result
    input BrTaken,
    input BIOSRest,
    output Flush,
    output [1:0] PCSel, 
    output RegWEn, 
    output CSRWen,
    output [2:0] WBSel
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
    UART_RECEIVER_W = 3'd3,
    UART_CONTROL_W  = 3'd4,
    BIOS_W          = 3'd5,
    CYC_COUNTER_W   = 3'd6,
    INST_COUNTER_W  = 3'd7;

    localparam
    UART_CONTROL_ADDR   = 32'h80000000,
    UART_RECEIVER_ADDR  = 32'h80000004,
    CYCLE_COUNTER_ADDR  = 32'h80000010,
    INST_COUNTER_ADDR   = 32'h80000014;

    localparam
    I_OPCODE        = 7'h13,
    LOAD_OPCODE     = 7'h03,
    JALR_OPCODE     = 7'h67,
    CSR_OPCODE      = 7'h73,
    JAL_OPCODE      = 7'h6f;

    localparam
    CSRWI_FUNC3     = 3'h5;

    

    wire [6:0] opcode_w; 
    wire [2:0] func3_w;
    wire [2:0] type_w;
    inst_splitter w_split(
        .inst(inst_w),
        .opcode(opcode_w),
        .func3(func3_w),
        .inst_type(type_w)
    );

    reg [1:0] pc_sel;
    reg reg_write_enable;
    reg [2:0] write_back_sel;
    reg [2:0] load_result;      



    wire opcode_fd = inst_fd[6:0];
    wire is_jal_special =  opcode_fd == JAL_OPCODE;
    wire is_jalr = opcode_w == JALR_OPCODE;
    wire is_bios_addr = Addr[31:28] == 4'b0100;


    assign PCSel  = pc_sel;
    assign RegWEn = reg_write_enable;
    assign WBSel  = write_back_sel;

    assign Flush  = BrTaken;
    assign CSRWen = opcode_w == CSR_OPCODE;      // NEEDS TO COVER CSR TO MAKE SURE IT IS THE CORRECT ADDRESS


    always @(*) begin
      if (BIOSRest)               pc_sel = BIOS_REST_P;
      else if (is_jal_special)    pc_sel = JAL_SPECIAL_P;
      // else if (is_jalr)           pc_sel = ALU_OUTPUT_P;
      else                        pc_sel = PC_PLUS_4_P;
    end

    always @(*) begin
      case(type_w) 
      R_TYPE,
      U_TYPE,
      J_TYPE,  
      I_TYPE:  reg_write_enable = TRUE; // TODO: I_TYPE DOESN'T NEED TO DEPEND ON CSR IF C_TYPE IS SEPARATED.
      default: reg_write_enable = FALSE;  // S and B types are covered
      endcase
    end

    always @(*) begin
      case (Addr)
        UART_CONTROL_ADDR:  load_result = UART_CONTROL_W;
        UART_RECEIVER_ADDR: load_result = UART_RECEIVER_W;
        CYCLE_COUNTER_ADDR: load_result = CYC_COUNTER_W;
        INST_COUNTER_ADDR:  load_result = INST_COUNTER_W;
        default: begin
          if (is_bios_addr) load_result = BIOS_W;
          else load_result = DMEM_W;
        end
      endcase
    end

    always @(*) begin
      case(opcode_w) 
        LOAD_OPCODE: write_back_sel = load_result;
        JAL_OPCODE,
        JALR_OPCODE:    write_back_sel = PC_PLUS_4_W;
        default:        write_back_sel = ALU_OUTPUT_W;
      endcase         
    end

endmodule
