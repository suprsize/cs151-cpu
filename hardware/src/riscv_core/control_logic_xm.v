module xm_logic #(
    parameter W_SIZE = 32
) (
    input [W_SIZE-1:0] inst_xm,
    input Br,
    input [W_SIZE-1:0] Addr,  //ALU result
    input [W_SIZE-1:0] PC_XM, 
    output [2:0] BrSel,       // Func3 of PC_XM
    output BrTaken,
    output ASel,
    output BSel,
    output [3:0] ALUSel,
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
    SLTU= 4'b0_011;
    localparam
    UART_TRANSMITTER_ADDR     = 32'h80000008,
    UART_COUNTERS_RESET_ADDR  = 32'h80000018;
    localparam
    AUIPC_OPCODE    = 7'h17;
    localparam
    RS1_A   = 1'd0,
    RS2_B   = 1'd0,
    PC_XM_A = 1'd1,
    IMM_B   = 1'd1;
    localparam
    FALSE = 1'd0,
    TRUE = 1'd1;

    

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
    reg [2:0] br_sel;
    reg branch_taken;
    reg a_sel;
    reg b_sel;
    reg [3:0] alu_sel;
    reg mem_rw;
    reg imem_rw;
    reg UART_write_valid;
    reg UART_ready_to_receive;

    assign BrSel =  br_sel;
    assign BrTaken = branch_taken;
    assign ASel = a_sel;
    assign BSel = b_sel;
    assign MemRW = mem_rw;
    assign IMemWE = imem_rw;
    assign ALUSel = alu_sel;
    assign UART_Write_valid = UART_write_valid;
    assign UART_Ready_To_Receive = UART_ready_to_receive;
    assign ResetCounters = type_xm == S_TYPE && Addr == UART_COUNTERS_RESET_ADDR;
    
    wire is_srai = type_xm == I_TYPE && SRA == {funct7_xm[5], funct3_xm};
    wire BIOS_mode = PC_XM[30];
   

    always @(*) begin
      case(type_xm) 
        R_TYPE: begin
          br_sel = 'd0; //xx
          branch_taken = FALSE;
          a_sel = RS1_A;
          b_sel = RS2_B;
          alu_sel = {funct7_xm[5], funct3_xm};
          mem_rw = FALSE;
          imem_rw = FALSE;
          UART_write_valid = FALSE;
          UART_ready_to_receive = FALSE;
        end

        I_TYPE: begin
          br_sel = 'd0; //xx
          branch_taken = FALSE;
          a_sel = RS1_A;
          b_sel = IMM_B;
          alu_sel = {is_srai? 1'd1 : 1'd0, funct3_xm};
          mem_rw = FALSE;
          imem_rw = FALSE;
          UART_write_valid = FALSE;
          UART_ready_to_receive = FALSE;
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
