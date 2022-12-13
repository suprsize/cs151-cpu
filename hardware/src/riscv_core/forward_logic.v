module forward_logic #(
    parameter W_SIZE = 32
) (
    input [W_SIZE-1:0] inst_fd,
    input [W_SIZE-1:0] inst_xm, 
    input [W_SIZE-1:0] inst_w,
    output AFrwd1, 
    output BFrwd1, 
    output BFrwd2,
    output AFrwd2,
    output JalrFrwd 
);

    localparam
    R_TYPE = 3'd0, 
    I_TYPE = 3'd1,
    S_TYPE = 3'd2,
    B_TYPE = 3'd3,
    U_TYPE = 3'd4,
    J_TYPE = 3'd5;


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

    wire write_back_w   = type_w != S_TYPE && type_w != B_TYPE && rd_w != 'd0;
    wire write_back_xm  = type_xm != S_TYPE && type_xm != B_TYPE && rd_xm != 'd0;

    assign AFrwd1   = rd_w == a_xm && write_back_w;
    assign BFrwd1   = rd_w == b_xm && write_back_w;
    assign AFrwd2   = rd_w == a_fd && write_back_w;
    assign BFrwd2   = rd_w == b_fd && write_back_w;
    assign JalrFrwd = rd_xm == a_fd && write_back_xm;

    

endmodule
