module fd_logic #(
    parameter W_SIZE = 32
) (
    input [W_SIZE-1:0] inst_fd,
    input [W_SIZE-1:0] PC_fd, 
    output InstSel,
    output [2:0] ImmSel 
);

    assign InstSel = PC_fd[30]; 
    assign ImmSel = inst_type;
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

endmodule
