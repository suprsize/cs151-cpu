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
    // BIOS Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    wire [11:0] bios_addra, bios_addrb;
    wire [31:0] bios_douta, bios_doutb;
    wire bios_ena, bios_enb;
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
    wire [31:0] dmem_din, dmem_dout;
    wire [3:0] dmem_we;
    wire dmem_en;
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
    wire [31:0] imem_dina, imem_doutb;
    wire [13:0] imem_addra, imem_addrb;
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
    wire [4:0] ra1, ra2, wa;
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

    reg [31:0] tohost_csr = 0;

    // TODO: Your code to implement a fully functioning RISC-V core
    // Add as many modules as you want
    // Feel free to move the memory modules around

    wire [31:0] alu_a, alu_b;
    wire [3:0] ALUSel;
    wire [31:0] alu_result;
    alu alu (
      .a(alu_a),
      .b(alu_b),
      .ALUSel(ALUSel),
      .result(alu_result)
    );

    wire [31:0] imm_inst;
    wire [2:0] ImmSel;
    wire [31:0] imm_result;
    imm_gen imm_gen (
      .inst(imm_inst),
      .ImmSel(ImmSel),
      .imm(imm_result)
    );

    wire [31:0] branch_a, branch_b;
    wire [2:0] BrSel;
    wire branch_result;
    branch_comp branch_comp (
      .a(branch_a),
      .b(branch_b),
      .BrSel(BrSel),
      .Br(branch_result)
    );

    wire [31:0] imem_store_din;
    wire [15:0] imem_store_addr;
    wire [2:0] imem_store_func3;
    wire ImemWe;
    wire [31:0] imem_din;
    wire [13:0] imem_addr;
    wire [3:0] ImemRw4;
    store imem_store (
      .din(imem_store_din),
      .addr(imem_store_addr),
      .func3(imem_store_func3),
      .we(ImemWe),
      .store_data(imem_din),
      .mem_addr(imem_addr),
      MemRW4(ImemRw4)
    );

    wire [31:0] mem_store_din;
    wire [15:0] mem_store_addr;
    wire [2:0] mem_store_func3;
    wire MemWe;
    wire [31:0] mem_din;
    wire [13:0] mem_addr;
    wire [3:0] MemRw4;
    store mem_store (
      .din(mem_store_din),
      .addr(mem_store_addr),
      .func3(mem_store_func3),
      .we(MemWe),
      .store_data(mem_din),
      .mem_addr(mem_addr),
      MemRW4(MemRw4)
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

    wire [31:0] frwd_inst_fd;
    wire [31:0] frwd_inst_xm;
    wire [31:0] frwd_inst_w;
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
    wire xm_logic_branch_result;
    wire ASel;
    wire BSel;
    wire [3:0] ALUSel;
    wire [2:0] BrSel;       
    wire BrTaken;
    wire MemRW; 
    wire IMemWE;
    wire UART_Write_valid;
    wire UART_Ready_To_Receive;
    wire ResetCounter;
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
      .ResetCounter(ResetCounter)
    );





  




endmodule
