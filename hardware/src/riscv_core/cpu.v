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
    ALU_OUTPUT_P    = 2'd1,
    JAL_SPECIAL_P   = 2'd2,
    BIOS_REST_P     = 2'd3;
    localparam NOP = 32'h0;
    localparam
    RS1_A   = 1'd0,
    RS2_B   = 1'd0,
    PC_XM_A = 1'd1,
    IMM_B   = 1'd1;
    localparam
    PC_PLUS_4_W     = 3'd0,
    ALU_OUTPUT_W    = 3'd1,
    DMEM_W          = 3'd2,
    UART_RECEIVER_W = 3'd3,
    UART_CONTROL_W  = 3'd4,
    BIOS_W          = 3'd5,
    CYC_COUNTER_W   = 3'd6,
    INST_COUNTER_W  = 3'd7;


    // BIOS Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    wire [11:0] bios_addra = pc_wire_2[13:2];
    wire [11:0] bios_addrb = alu_result[13:2];
    wire [31:0] bios_douta, bios_doutb;
    wire bios_ena = 'd1; //todo, don't know
    wire bios_enb = 'd1;
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
    wire [13:0] dmem_addr = mem_store_addr_out;
    wire [31:0] dmem_din = mem_store_dout;
    wire [31:0] dmem_dout;
    wire [3:0] dmem_we = MemRw4;
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
    wire [31:0] imem_dina = imem_store_dout;
    wire [31:0] imem_doutb;
    wire [13:0] imem_addra = imem_store_addr_out; 
    wire [13:0] imem_addrb = pc_wire_2[15:2];
    wire [3:0] imem_wea = ImemRw4;
    wire imem_ena = pc_xm[30]; //TODO: I don't know about this
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
    wire we = RegWEn;
    wire [4:0] ra1 = a_fd;
    wire [4:0] ra2 = b_fd;
    wire [4:0] wa = rd_w;
    wire [31:0] wd = write_back_data;
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
    wire uart_rx_data_out_ready = UART_Ready_To_Receive;
    //// UART Transmitter
    wire [7:0] uart_tx_data_in = b_updated[7:0];
    wire uart_tx_data_in_valid = UART_Write_valid;
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

    reg [31:0] tohost_csr = csr_51e; //TODO

    // TODO: Your code to implement a fully functioning RISC-V core
    // Add as many modules as you want
    // Feel free to move the memory modules around

    wire [31:0] alu_a = ASel == PC_XM_A? pc_xm : a_updated;
    wire [31:0] alu_b = BSel == IMM_B? imm : b_updated;
    wire [3:0] alu_sel = ALUSel;
    wire [31:0] alu_result;
    alu alu (
      .a(alu_a),
      .b(alu_b),
      .ALUSel(alu_sel),
      .result(alu_result)
    );

    wire [31:0] imm_inst = inst_fd;
    wire [2:0] imm_sel = ImmSel;
    wire [31:0] imm_result;
    imm_gen imm_gen (
      .inst(imm_inst),
      .ImmSel(imm_sel),
      .imm(imm_result)
    );

    wire [31:0] branch_a = a_updated;
    wire [31:0] branch_b = b_updated;
    wire [2:0] branch_sel = BrSel;
    wire branch_result;
    branch_comp branch_comp (
      .a(branch_a),
      .b(branch_b),
      .BrSel(branch_sel),
      .Br(branch_result)
    );

    wire [31:0] imem_store_din = b_updated;
    wire [15:0] imem_store_addr = alu_result[15:0];
    wire [2:0] imem_store_func3xm = func3_xm;
    wire imem_store_we = IMemWE;
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

    wire [31:0] mem_store_din = b_updated;
    wire [15:0] mem_store_addr = alu_result[15:0];
    wire [2:0] mem_store_func3xm = func3_xm;
    wire mem_store_we = MemRW;
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

    wire [31:0] load_din = dmem_dout;
    wire [15:0] load_addr = alu_result_w[15:0];
    wire [2:0] load_func3 = func3_w;
    wire [31:0] load_result;
    load load (
      .mem_data(load_din),
      .addr(load_addr),
      .func3(load_func3),
      .load_data(load_result)
    );

    wire [31:0] frwd_inst_fd = inst_fd;
    wire [31:0] frwd_inst_xm = real_inst_xm;
    wire [31:0] frwd_inst_w = inst_xm;
    wire AFrwd1;
    wire BFrwd1;
    wire AFrwd2;
    wire BFrwd2;
    forward_logic frwd_logic (
      .inst_fd(frwd_inst_fd),
      .inst_xm(frwd_inst_xm),
      .inst_w(frwd_inst_w),
      .AFrwd1(AFrwd1),
      .BFrwd1(BFrwd1),
      .AFrwd2(AFrwd2),
      .BFrwd2(BFrwd2)
    );

    wire [31:0] fd_logic_inst_fd = inst_fd;
    wire [31:0] fd_logic_pc_fd = pc_fd;
    wire InstSel;
    wire [2:0] ImmSel;
    fd_logic fd_logic (
      .inst_fd(fd_logic_inst_fd),
      .PC_fd(fd_logic_pc_fd),
      .InstSel(InstSel),
      .ImmSel(ImmSel)
    );

    wire [31:0] xm_logic_inst_xm = real_inst_xm;
    wire [31:0] xm_logic_addr = alu_result;
    wire [31:0] xm_logic_pc_xm = pc_xm;
    wire xm_logic_branch_result = branch_result;
    wire ASel;
    wire BSel;
    wire [3:0] ALUSel;
    wire [2:0] BrSel;       
    wire BrTaken;
    wire MemRW; 
    wire IMemWE;
    wire UART_Write_valid;
    wire UART_Ready_To_Receive;
    wire ResetCounters;
    xm_logic xm_logic (
      .inst_xm(xm_logic_inst_xm),
      .Addr(xm_logic_addr),
      .PC_XM(xm_logic_pc_xm),
      .Br(xm_logic_branch_result),
      .ASel(ASel),
      .BSel(BSel),
      .ALUSel(ALUSel),
      .BrSel(BrSel),       
      .BrTaken(BrTaken),
      .MemRW(MemRW),
      .IMemWE(IMemWE),
      .UART_Write_valid(UART_Write_valid),
      .UART_Ready_To_Receive(UART_Ready_To_Receive),
      .ResetCounters(ResetCounters)
    );

    wire [31:0] w_logic_inst_w = inst_w;
    wire [31:0] w_logic_inst_fd = inst_fd;
    wire [31:0] w_logic_addr = alu_result_w;
    wire w_logic_BrTaken = BrTaken_w;
    wire w_logic_BIOSRest = rst;
    wire Flush;
    wire [1:0] PCSel;
    wire RegWEn;
    wire CSRWen;
    wire [2:0] WBSel;
    w_logic w_logic (
      .inst_w(w_logic_inst_w),
      .inst_fd(w_logic_inst_fd),
      .Addr(w_logic_addr),
      .BrTaken(w_logic_BrTaken),
      .BIOSRest(w_logic_BIOSRest),
      .Flush(Flush),
      .PCSel(PCSel),
      .RegWEn(RegWEn),
      .CSRWen(CSRWen),
      .WBSel(WBSel)
    );


reg [31:0] pc_fd, pc_xm, pc_w;
reg [31:0] csr_51e;
reg [31:0] a, b, imm;
reg [31:0] inst_xm, inst_w;
reg BrTaken_w;
reg [31:0] alu_result_w;
reg [31:0] inst_counter, cycle_counter;



reg [31:0] pc_wire_1;
always @(*) begin
  case(PCSel)
    PC_PLUS_4_P   : pc_wire_1 = pc_fd + 'd4;
    ALU_OUTPUT_P  : pc_wire_1 = alu_result_w;
    JAL_SPECIAL_P : pc_wire_1 = pc_fd + imm_result;
    BIOS_REST_P   : pc_wire_1 = RESET_PC;
  endcase
end
wire [31:0] pc_wire_2 = !BrTaken || rst? pc_wire_1 : alu_result;

always @(posedge clk) begin
  pc_fd <= pc_wire_2;
end

wire [31:0] inst_fd = pc_fd[30]? bios_douta : imem_doutb;

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
        .inst(inst_xm),
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
  if (AFrwd2) a <= write_back_data;
  else a <= rd1;
end  
always @(posedge clk) begin
  if (BFrwd2) b <= write_back_data;
  else b <= rd2;
end 
always @(posedge clk) begin
  imm <= imm_result;
end  
always @(posedge clk) begin
  inst_xm <= inst_fd;
end 

wire [31:0] real_inst_xm;
assign real_inst_xm = Flush? NOP : inst_xm;

wire[31:0] a_updated, b_updated;
assign a_updated = AFrwd1? write_back_data : a;
assign b_updated = BFrwd1? write_back_data : b;


always @(posedge clk) begin
  pc_w <= pc_xm;
end 
always @(posedge clk) begin
  alu_result_w <= alu_result;
end 
always @(posedge clk) begin
  BrTaken_w <= BrTaken;
end 
always @(posedge clk) begin
  inst_w <= real_inst_xm;
end 

reg [31:0] write_back_data;

always @(*) begin
  case(WBSel) 
    PC_PLUS_4_W     : write_back_data = pc_w + 'd4;
    ALU_OUTPUT_W    : write_back_data = alu_result_w;
    DMEM_W          : write_back_data = load_result;
    UART_RECEIVER_W : write_back_data = {24'b0, uart_rx_data_out};
    UART_CONTROL_W  : write_back_data = {30'b0, uart_rx_data_out_valid, uart_tx_data_in_ready};
    BIOS_W          : write_back_data = bios_doutb;
    CYC_COUNTER_W   : write_back_data = cycle_counter;
    INST_COUNTER_W  : write_back_data = inst_counter;
  endcase
end 

always @(posedge clk) begin
  if(CSRWen) csr_51e <= alu_result_w;
end 
always @(posedge clk) begin
  if(rst) cycle_counter <= 'd0;
  else cycle_counter <= cycle_counter + 'd1;
end 
always @(posedge clk) begin
  if(rst) inst_counter <= 'd0;
  else if (Flush) inst_counter <= inst_counter - 'd1; //TODO: don't know how to count instructions
  else inst_counter <= cycle_counter + 'd1;
end 



endmodule
