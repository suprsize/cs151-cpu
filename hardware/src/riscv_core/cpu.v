module cpu #(
    parameter CPU_CLOCK_FREQ = 50_000_000,
    parameter RESET_PC = 32'h4000_0000,
    parameter BAUD_RATE = 115200
) (
    input clk,
    input rst,
    input bp_enable,
    input serial_in,
    output serial_out
);
    localparam
    PC_PLUS_4_P     = 2'd0,
    RS1_PLUS_IMM_P    = 2'd1,
    PC_PLUS_IMM_P   = 2'd2,
    BIOS_REST_P     = 2'd3;
    localparam NOP 	= 32'h0000_0013; //addi X0, X0, 0
    localparam
    RS1_A   = 1'd0,
    RS2_B   = 1'd0,
    PC_XM_A = 1'd1,
    IMM_B   = 1'd1;
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
    B_OPCODE        = 7'h63;


    // BIOS Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    wire [11:0] bios_addra;
    wire [11:0] bios_addrb;
    wire [31:0] bios_douta, bios_doutb;
    wire bios_ena; //todo, don't know
    wire bios_enb;
    bios_mem bios_mem (
      .clk(clk),
      .ena(bios_ena),
      .addra(bios_addra),
      .douta(bios_douta),
      .enb(bios_enb),
      .addrb(bios_addrb),
      .doutb(bios_doutb)
    );

    // Data Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    // Write-byte-enable: select which of the four bytes to write
    wire [13:0] dmem_addr;
    wire [31:0] dmem_din;
    wire [31:0] dmem_dout;
    wire [3:0] dmem_we;
    wire dmem_en = 'd1;
    dmem dmem (
      .clk(clk),
      .en(dmem_en),
      .we(dmem_we),
      .addr(dmem_addr),
      .din(dmem_din),
      .dout(dmem_dout)
    );

    // Instruction Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    // Write-byte-enable: select which of the four bytes to write
    wire [31:0] imem_dina;
    wire [31:0] imem_doutb;
    wire [13:0] imem_addra; 
    wire [13:0] imem_addrb;
    wire [3:0] imem_wea;
    wire imem_ena;
    imem imem (
      .clk(clk),
      .ena(imem_ena),
      .wea(imem_wea),
      .addra(imem_addra),
      .dina(imem_dina),
      .addrb(imem_addrb),
      .doutb(imem_doutb)
    );

    // Register file
    // Asynchronous read: read data is available in the same cycle
    // Synchronous write: write takes one cycle
    wire we;
    wire [4:0] ra1;
    wire [4:0] ra2;
    wire [4:0] wa;
    wire [31:0] wd;
    wire [31:0] rd1, rd2;
    reg_file rf (
        .clk(clk),
        .we(we),
        .ra1(ra1), .ra2(ra2), .wa(wa),
        .wd(wd),
        .rd1(rd1), .rd2(rd2)
    );

    // On-chip UART
    //// UART Receiver
    wire [7:0] uart_rx_data_out;
    wire uart_rx_data_out_valid;
    wire uart_rx_data_out_ready;
    //// UART Transmitter
    wire [7:0] uart_tx_data_in;
    wire uart_tx_data_in_valid;
    wire uart_tx_data_in_ready;
    uart #(
        .CLOCK_FREQ(CPU_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) on_chip_uart (
        .clk(clk),
        .reset(rst),

        .serial_in(serial_in),
        .data_out(uart_rx_data_out),
        .data_out_valid(uart_rx_data_out_valid),
        .data_out_ready(uart_rx_data_out_ready),

        .serial_out(serial_out),
        .data_in(uart_tx_data_in),
        .data_in_valid(uart_tx_data_in_valid),
        .data_in_ready(uart_tx_data_in_ready)
    );


    // TODO: Your code to implement a fully functioning RISC-V core
    // Add as many modules as you want
    // Feel free to move the memory modules around

    wire [31:0] alu_a;
    wire [31:0] alu_b;
    wire [3:0] alu_sel;
    wire [31:0] alu_result;
    alu alu (
      .a(alu_a),
      .b(alu_b),
      .ALUSel(alu_sel),
      .result(alu_result)
    );

    wire [31:0] imm_inst;
    wire [2:0] imm_sel;
    wire [31:0] imm_result;
    imm_gen imm_gen (
      .inst(imm_inst),
      .ImmSel(imm_sel),
      .imm(imm_result)
    );

    wire [31:0] branch_a;
    wire [31:0] branch_b;
    wire [2:0] branch_sel;
    wire branch_result;
    branch_comp branch_comp (
      .a(branch_a),
      .b(branch_b),
      .BrSel(branch_sel),
      .Br(branch_result)
    );

    wire [31:0] imem_store_din; 
    wire [15:0] imem_store_addr;
    wire [2:0] imem_store_func3xm;
    wire imem_store_we;
    wire [31:0] imem_store_dout;
    wire [13:0] imem_store_addr_out;
    wire [3:0] ImemRw4;
    store imem_store (
      .din(imem_store_din),
      .addr(imem_store_addr),
      .func3(imem_store_func3xm),
      .we(imem_store_we),
      .store_data(imem_store_dout),
      .mem_addr(imem_store_addr_out),
      .MemRw4(ImemRw4)
    );

    wire [31:0] mem_store_din; 
    wire [15:0] mem_store_addr;
    wire [2:0] mem_store_func3xm;
    wire mem_store_we;
    wire [31:0] mem_store_dout;
    wire [13:0] mem_store_addr_out;
    wire [3:0] MemRw4;
    store mem_store (
      .din(mem_store_din),
      .addr(mem_store_addr),
      .func3(mem_store_func3xm),
      .we(mem_store_we),
      .store_data(mem_store_dout),
      .mem_addr(mem_store_addr_out),
      .MemRw4(MemRw4)
    );

    wire [31:0] load_din;
    wire [15:0] load_addr;
    wire [2:0] load_func3;
    wire [31:0] load_result;
    load load (
      .mem_data(load_din),
      .addr(load_addr),
      .func3(load_func3),
      .load_data(load_result)
    );
    
	wire [31:0] bios_load_din;
    wire [15:0] bios_load_addr;
    wire [2:0] bios_load_func3;
    wire [31:0] bios_load_result;
    load bios_load (
      .mem_data(bios_load_din),
      .addr(bios_load_addr),
      .func3(bios_load_func3),
      .load_data(bios_load_result)
    );

    wire [31:0] frwd_inst_fd;
    wire [31:0] frwd_inst_xm;
    wire [31:0] frwd_inst_w;
    wire AFrwd1;
    wire BFrwd1;
    wire AFrwd2;
    wire BFrwd2;
    wire JalrFrwd;
    forward_logic frwd_logic (
      .inst_fd(frwd_inst_fd),
      .inst_xm(frwd_inst_xm),
      .inst_w(frwd_inst_w),
      .AFrwd1(AFrwd1),
      .BFrwd1(BFrwd1),
      .AFrwd2(AFrwd2),
      .BFrwd2(BFrwd2),
      .JalrFrwd(JalrFrwd)
    );

    wire [31:0] fd_logic_inst_fd;
    wire [31:0] fd_logic_pc_fd;
    wire InstSel;
    wire [2:0] ImmSel;
    fd_logic fd_logic (
      .inst_fd(fd_logic_inst_fd),
      .PC_fd(fd_logic_pc_fd),
      .InstSel(InstSel),
      .ImmSel(ImmSel)
    );

    wire [31:0] xm_logic_inst_xm;
    wire [31:0] xm_logic_addr;
    wire [31:0] xm_logic_pc_xm;
    wire [31:0] xm_logic_pc_fd;
    wire xm_logic_branch_result; 
    wire xm_log_br_pred_taken;
    wire ASel;
    wire BSel;
    wire [3:0] ALUSel;
    wire [2:0] BrSel;       
    wire Flush;
    wire DoNotBranch;
    wire CorrectBrPred;
    wire MemRW; 
    wire IMemWE;
    wire UART_Write_valid;
    wire UART_Ready_To_Receive;
    wire ResetCounters;
    xm_logic xm_logic (
      .inst_xm(xm_logic_inst_xm),
      .Addr(xm_logic_addr),
      .PC_XM(xm_logic_pc_xm),
      .PC_FD(xm_logic_pc_fd),
      .Br(xm_logic_branch_result),
      .br_pred_taken_xm(xm_log_br_pred_taken),
      .ASel(ASel),
      .BSel(BSel),
      .ALUSel(ALUSel),
      .BrSel(BrSel),       
      .Flush(Flush),
      .DoNotBranch(DoNotBranch),
      .CorrectBrPred(CorrectBrPred),
      .MemRW(MemRW),
      .IMemWE(IMemWE),
      .UART_Write_valid(UART_Write_valid),
      .UART_Ready_To_Receive(UART_Ready_To_Receive),
      .ResetCounters(ResetCounters)
    );

    wire [31:0] w_logic_inst_w; 
    wire [31:0] w_logic_inst_fd;
    wire [31:0] w_logic_addr;
    wire w_logic_BIOSRest;
    wire w_logic_br_pred_taken;
    wire [1:0] PCSel;
    wire RegWEn;
    wire CSRWen;
    wire [3:0] WBSel;
    w_logic w_logic (
      .inst_w(w_logic_inst_w),
      .inst_fd(w_logic_inst_fd),
      .Addr(w_logic_addr),
      .BIOSRest(w_logic_BIOSRest),
      .br_pred_taken(w_logic_br_pred_taken),
      .PCSel(PCSel),
      .RegWEn(RegWEn),
      .CSRWen(CSRWen),
      .WBSel(WBSel)
    );

    wire  [31:0] br_pred_pc_fd;
    wire br_pred_is_br_fd;
    wire  [31:0] br_pred_pc_xm;
    wire br_pred_is_br_xm;
    wire br_pred_br_taken_check;
    wire br_pred_result;
    branch_predictor br_predictor (
      .clk(clk),
      .reset(rst),
      .pc_guess(br_pred_pc_fd),
      .is_br_guess(br_pred_is_br_fd),
      .pc_check(br_pred_pc_xm),
      .is_br_check(br_pred_is_br_xm),
      .br_taken_check(br_pred_br_taken_check),
      .br_pred_taken(br_pred_result)
    );

wire br_pred_taken = br_pred_result && bp_enable;
reg [31:0] pc_fd, pc_xm, pc_w;
reg [31:0] a, b, imm;
reg br_pred_taken_xm;
reg [31:0] inst_xm, inst_w;
reg flush_w;
reg [31:0] alu_result_w;
reg [31:0] inst_counter, cycle_counter, total_branch_counter, correct_branch_counter;
reg [31:0] tohost_csr; //TODO


wire [31:0] jalr_a;
reg [31:0] pc_wire_1;
always @(*) begin
  case(PCSel)
    PC_PLUS_4_P     : pc_wire_1 = pc_fd + 'd4;
    RS1_PLUS_IMM_P  : pc_wire_1 = jalr_a + imm_result;
    PC_PLUS_IMM_P   : pc_wire_1 = pc_fd + imm_result;
    BIOS_REST_P     : pc_wire_1 = RESET_PC;
  endcase
end
wire [31:0] flush_to_pc = DoNotBranch? pc_xm + 'd4: alu_result;
wire [31:0] pc_wire_2 = !Flush || rst? pc_wire_1 : flush_to_pc;

reg [31:0] write_back_data;

always @(*) begin
  case(WBSel) 
    PC_PLUS_4_W       : write_back_data = pc_w + 'd4;
    ALU_OUTPUT_W      : write_back_data = alu_result_w;
    DMEM_W            : write_back_data = load_result;
    UART_RECEIVER_W   : write_back_data = {24'b0, uart_rx_data_out};
    UART_CONTROL_W    : write_back_data = {30'b0, uart_rx_data_out_valid, uart_tx_data_in_ready};
    BIOS_W            : write_back_data = bios_load_result;
    CYC_COUNTER_W     : write_back_data = cycle_counter;
    INST_COUNTER_W    : write_back_data = inst_counter;
    BR_COUNTER_W      : write_back_data = total_branch_counter;
    CORR_BR_COUNTER_W : write_back_data = correct_branch_counter;
    default			  : write_back_data = pc_w + 'd4;
  endcase
end 

always @(posedge clk) begin
  pc_fd <= pc_wire_2;
end

wire [31:0] inst_fd = pc_fd[30]? bios_douta : imem_doutb;

wire[31:0] a_updated_fd, b_updated_fd;
assign a_updated_fd = AFrwd2? write_back_data : rd1;
assign b_updated_fd = BFrwd2? write_back_data : rd2;
assign jalr_a = JalrFrwd? alu_result : a_updated_fd;

always @(posedge clk) begin
	if (rst) a <= 'd0;
	else a <= a_updated_fd;
end  
always @(posedge clk) begin
	if (rst) b <= 'd0;
	else b <= b_updated_fd;
end 

always @(posedge clk) begin
	if (rst) pc_xm <= 'd0;
	else pc_xm <= pc_fd;
end  
always @(posedge clk) begin
	if (rst) imm <= 'd0;
	else imm <= imm_result;
end  
always @(posedge clk) begin
  if(rst) inst_xm <= NOP;
  else inst_xm <= inst_fd;
end 
always @(posedge clk) begin
  if(rst) br_pred_taken_xm <= 'd0;
  else br_pred_taken_xm <= br_pred_taken;
end 


wire [31:0] real_inst_xm;
assign real_inst_xm = flush_w? NOP : inst_xm;

wire[31:0] a_updated_xm, b_updated_xm;
assign a_updated_xm = AFrwd1? write_back_data : a;
assign b_updated_xm = BFrwd1? write_back_data : b;

    wire [6:0] opcode_fd; 
    wire [4:0] rd_fd;
    wire [2:0] func3_fd;
    wire [4:0] a_fd, b_fd;
    wire [6:0] func7_fd;
    wire [2:0] type_fd;
    inst_splitter fd_split(
        .inst(inst_fd),
        .opcode(opcode_fd),
        .rd(rd_fd),
        .func3(func3_fd),
        .rs1(a_fd), .rs2(b_fd),
        .func7(func7_fd),
        .inst_type(type_fd)
    );

    wire [6:0] opcode_xm; 
    wire [4:0] rd_xm;
    wire [2:0] func3_xm;
    wire [4:0] a_xm, b_xm;
    wire [6:0] func7_xm;
    wire [2:0] type_xm;
    inst_splitter xm_split(
        .inst(real_inst_xm),
        .opcode(opcode_xm),
        .rd(rd_xm),
        .func3(func3_xm),
        .rs1(a_xm), .rs2(b_xm),
        .func7(func7_xm),
        .inst_type(type_xm)
    );

    wire [6:0] opcode_w; 
    wire [4:0] rd_w;
    wire [2:0] func3_w;
    wire [4:0] a_w, b_w;
    wire [6:0] func7_w;
    wire [2:0] type_w;
    inst_splitter w_split(
        .inst(inst_w),
        .opcode(opcode_w),
        .rd(rd_w),
        .func3(func3_w),
        .rs1(a_w), .rs2(b_w),
        .func7(func7_w),
        .inst_type(type_w)
    );
    
always @(posedge clk) begin
	if (rst) pc_w <= 'd0;
	else pc_w <= pc_xm;
end 
always @(posedge clk) begin
	if (rst) alu_result_w <= 'd0;
	else alu_result_w <= alu_result;
end 
always @(posedge clk) begin
  if (rst) flush_w <= 'd0;
  else flush_w <= Flush;
end 
always @(posedge clk) begin
  if (rst) inst_w <= NOP;
  else inst_w <= real_inst_xm;
end 



always @(posedge clk) begin
  if (rst) tohost_csr <= 'd0;
  else begin
	if(CSRWen) tohost_csr <= alu_result_w;
  end
  
end 
always @(posedge clk) begin
  if(rst || ResetCounters) cycle_counter <= 'd0;
  else cycle_counter <= cycle_counter + 'd1;
end 
always @(posedge clk) begin
  if(rst || ResetCounters) inst_counter <= 'd0;
  else if (inst_w != NOP) inst_counter <= inst_counter + 'd1;
end 
always @(posedge clk) begin
  if(rst || ResetCounters) total_branch_counter <= 'd0;
  else total_branch_counter <= total_branch_counter + {31'd0, opcode_xm == B_OPCODE};
end 
always @(posedge clk) begin
  if(rst || ResetCounters) correct_branch_counter <= 'd0;
  else correct_branch_counter <= correct_branch_counter + {31'd0, CorrectBrPred};
end 




assign bios_addra = pc_wire_2[13:2];
assign bios_addrb = alu_result[13:2];
assign bios_ena = pc_wire_2[30]; //todo, don't know
assign bios_enb = alu_result[30];

assign dmem_addr = mem_store_addr_out;
assign dmem_din = mem_store_dout;
assign dmem_we = MemRw4;

assign imem_dina = imem_store_dout;
assign imem_addra = imem_store_addr_out; 
assign imem_addrb = pc_wire_2[15:2];
assign imem_wea   = ImemRw4;
assign imem_ena = pc_xm[30]; //todo not sure

assign we = RegWEn;
assign ra1 = a_fd;
assign ra2 = b_fd;
assign wa = rd_w;
assign wd = write_back_data;

assign uart_rx_data_out_ready = UART_Ready_To_Receive;

assign uart_tx_data_in = b_updated_xm[7:0];
assign uart_tx_data_in_valid = UART_Write_valid;

assign alu_a = ASel == PC_XM_A? pc_xm : a_updated_xm;
assign alu_b = BSel == IMM_B? imm : b_updated_xm;
assign alu_sel = ALUSel;

assign imm_inst = inst_fd;
assign imm_sel = ImmSel;

assign branch_a = a_updated_xm;
assign branch_b = b_updated_xm;
assign branch_sel = BrSel;


assign imem_store_din = b_updated_xm;
assign imem_store_addr = alu_result[15:0];
assign imem_store_func3xm = func3_xm;
assign imem_store_we = IMemWE;

assign mem_store_din = b_updated_xm;
assign mem_store_addr = alu_result[15:0];
assign mem_store_func3xm = func3_xm;
assign mem_store_we = MemRW;

assign load_din = dmem_dout;
assign load_addr = alu_result_w[15:0];
assign load_func3 = func3_w;

assign bios_load_din = bios_doutb;
assign bios_load_addr = alu_result_w[15:0];
assign bios_load_func3 = func3_w;

assign frwd_inst_fd = inst_fd;
assign frwd_inst_xm = real_inst_xm;
assign frwd_inst_w = inst_w;

assign fd_logic_inst_fd = inst_fd;
assign fd_logic_pc_fd = pc_fd;

assign xm_logic_inst_xm = real_inst_xm;
assign xm_logic_addr = alu_result;
assign xm_logic_pc_xm = pc_xm;
assign xm_logic_pc_fd = pc_fd;
assign xm_logic_branch_result = branch_result;
assign xm_log_br_pred_taken = br_pred_taken_xm;

assign w_logic_inst_w = inst_w;
assign w_logic_inst_fd = inst_fd;
assign w_logic_addr = alu_result_w;
assign w_logic_BIOSRest = rst;
assign w_logic_br_pred_taken = br_pred_taken;

assign br_pred_pc_fd = pc_fd;
assign br_pred_is_br_fd = opcode_fd == B_OPCODE;
assign br_pred_pc_xm = pc_xm;
assign br_pred_is_br_xm = opcode_xm == B_OPCODE;
assign br_pred_br_taken_check = branch_result;

endmodule
