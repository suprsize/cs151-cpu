module m_logic #(
    parameter W_SIZE = 32
) (
    input [6:0] opcode_m,
    input [W_SIZE-1:0] addr,  //ALU result
    output [3:0] WBSel
    );

    localparam
    PC_PLUS_4_W         = 4'd0,
    ALU_OUTPUT_W        = 4'd1,
    DMEM_W              = 4'd2,
    UART_RECEIVER_W     = 4'd3,
    UART_CONTROL_W      = 4'd4,
    BIOS_W              = 4'd5,
    CYC_COUNTER_W       = 4'd6,
    INST_COUNTER_W      = 4'd7,
    BR_COUNTER_W        = 4'd8,
    CORR_BR_COUNTER_W   = 4'd9;

    localparam
    UART_CONTROL_ADDR           = 32'h80000000,
    UART_RECEIVER_ADDR          = 32'h80000004,
    CYCLE_COUNTER_ADDR          = 32'h80000010,
    INST_COUNTER_ADDR           = 32'h80000014,
    TOTAL_BRANCH_COUNTER_ADDR   = 32'h8000001c,
    CORRECT_BRANCH_COUNTER_ADDR = 32'h80000020;

    localparam
    I_OPCODE        = 7'h13,
    LOAD_OPCODE     = 7'h03,
    JALR_OPCODE     = 7'h67,
    CSR_OPCODE      = 7'h73,
    JAL_OPCODE      = 7'h6f;


    reg [3:0] write_back_sel;
    reg [3:0] load_result;      

    wire is_bios_addr = addr[31:28] == 4'b0100;
    assign WBSel  = write_back_sel;

    always @(*) begin
      case (addr)
        UART_CONTROL_ADDR:            load_result = UART_CONTROL_W;
        UART_RECEIVER_ADDR:           load_result = UART_RECEIVER_W;
        CYCLE_COUNTER_ADDR:           load_result = CYC_COUNTER_W;
        INST_COUNTER_ADDR:            load_result = INST_COUNTER_W;
        TOTAL_BRANCH_COUNTER_ADDR:    load_result = BR_COUNTER_W;        
        CORRECT_BRANCH_COUNTER_ADDR:  load_result = CORR_BR_COUNTER_W;   
        default: begin
          if (is_bios_addr) load_result = BIOS_W;
          else load_result = DMEM_W;
        end
      endcase
    end

    always @(*) begin
      case(opcode_m) 
        LOAD_OPCODE: 	write_back_sel = load_result;
        JAL_OPCODE,
        JALR_OPCODE:    write_back_sel = PC_PLUS_4_W;
        default:        write_back_sel = ALU_OUTPUT_W;
      endcase         
    end
endmodule
