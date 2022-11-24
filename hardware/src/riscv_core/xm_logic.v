module xm_logic #(
    parameter W_SIZE = 32
) (
    input [W_SIZE-1:0] inst_xm,
    input [W_SIZE-1:0] Addr,  //ALU result
    input [W_SIZE-1:0] PC_XM, 
    input Br,
    output ASel,
    output BSel,
    output [3:0] ALUSel,
    output [2:0] BrSel,       // Func3 of inst_xm
    output BrTaken,
    output MemRW, 
    output IMemWE,
    output UART_Write_valid,
    output UART_Ready_To_Receive,
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
    ADD = 4'b0_000,
    SUB = 4'b1_000,
    AND = 4'b0_111,
    OR  = 4'b0_110,
    XOR = 4'b0_100,
    SLL = 4'b0_001,
    SRL = 4'b0_101,
    SRA = 4'b1_101,
    SLT = 4'b0_010,
    SLTU= 4'b0_011,
    A   = 4'b1_111,
    B   = 4'b1_110;
    localparam
    UART_TRANSMITTER_ADDR     = 32'h80000008,
    UART_COUNTERS_RESET_ADDR  = 32'h80000018,
    UART_RECEIVER_ADDR        = 32'h80000004;
    localparam
    LOAD_OPCODE  = 7'h03,
    AUIPC_OPCODE    = 7'h17;
    localparam
    RS1_A   = 1'd0,
    RS2_B   = 1'd0,
    PC_XM_A = 1'd1,
    IMM_B   = 1'd1;
    localparam
    FALSE = 1'd0,
    TRUE = 1'd1;
    localparam
    CSRWI_FUNC3     = 3'h5;
    

    wire [6:0] opcode_xm; 
    wire [4:0] rd_xm;
    wire [2:0] funct3_xm;
    wire [4:0] a_xm, b_xm;
    wire [6:0] funct7_xm;
    wire [2:0] type_xm;
    inst_splitter xm_split(
        .inst(inst_xm),
        .opcode(opcode_xm),
        .rd(rd_xm),
        .funct3(funct3_xm),
        .rs1(a_xm), .rs2(b_xm),
        .funct7(funct7_xm),
        .inst_type(type_xm)
    );

    reg a_sel;
    reg b_sel;
    reg [3:0] alu_sel;
    assign ASel = a_sel;
    assign BSel = b_sel;
    assign ALUSel = alu_sel;

    assign BrSel                  = funct3_xm;
    assign BrTaken                = type_xm == B_TYPE? Br : FALSE;
    assign MemRW                  = type_xm == S_TYPE ? Addr[31:30] == 2'd00 && Addr[28]     : FALSE;
    assign IMemWE                 = type_xm == S_TYPE ? BIOS_mode && Addr[31:29] == 3'b001   : FALSE;
    assign UART_Write_valid       = type_xm == S_TYPE ? Addr == UART_TRANSMITTER_ADDR        : FALSE;
    assign UART_Ready_To_Receive  = opcode_xm == LOAD_OPCODE ? Addr == UART_RECEIVER_ADDR : FALSE;
    assign ResetCounters          = type_xm == S_TYPE && Addr == UART_COUNTERS_RESET_ADDR;
    
    wire is_srai = type_xm == I_TYPE && SRA == {funct7_xm[5], funct3_xm};
    wire BIOS_mode = PC_XM[30];

    always @(*) begin
      case(type_xm) 
        R_TYPE: begin
          a_sel = RS1_A;
          b_sel = RS2_B;
          alu_sel = {funct7_xm[5], funct3_xm};
        end

        I_TYPE: begin     
          a_sel = RS1_A;
          b_sel = IMM_B;
          alu_sel = {is_srai, funct3_xm};  
        end

        S_TYPE: begin
          a_sel = RS1_A;
          b_sel = IMM_B;
          alu_sel = ADD;
        end

        B_TYPE: begin
          a_sel = PC_XM_A;
          b_sel = IMM_B;
          alu_sel = ADD;
        end

        U_TYPE: begin
          a_sel = PC_XM_A; 
          b_sel = IMM_B;
          alu_sel = opcode_xm == AUIPC_OPCODE? ADD : B;
        end

        C_TYPE: begin
          a_sel = RS1_A;
          b_sel = IMM_B;
          alu_sel = funct3_xm == CSRWI_FUNC3? B : A;
        end

        default: begin // jal is already covered by special case of jal. not really needed.
          a_sel = PC_XM_A;
          b_sel = IMM_B; 
          alu_sel = ADD;
        end
      endcase
    end



endmodule
