module forward_logic #(
    parameter W_SIZE = 32
) (
    input [W_SIZE-1:0] inst_fd,
    input [W_SIZE-1:0] inst_xm, 
    input [W_SIZE-1:0] inst_w,
    output AFrwd1, 
    output AFrwd2, 
    output BFrwd1, 
    output BFrwd2
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
    wire [2:0] funct3_fd;
    wire [4:0] a_fd, b_fd;
    wire [6:0] funct7_fd;
    wire [2:0] type_fd;
    inst_splitter fd_split(
        .opcode(opcode_fd),
        .rd(rd_fd),
        .funct3(funct3_fd),
        .rs1(a_fd), .rs2(b_fd),
        .funct7(funct7_fd),
        .inst_type(type_fd)
    );

    wire [6:0] opcode_xm; 
    wire [4:0] rd_xm;
    wire [2:0] funct3_xm;
    wire [4:0] a_xm, b_xm;
    wire [6:0] funct7_xm;
    wire [2:0] type_xm;
    inst_splitter xm_split(
        .opcode(opcode_xm),
        .rd(rd_xm),
        .funct3(funct3_xm),
        .rs1(a_xm), .rs2(b_xm),
        .funct7(funct7_xm),
        .inst_type(type_xm)
    );

    wire [6:0] opcode_w; 
    wire [4:0] rd_w;
    wire [2:0] funct3_w;
    wire [4:0] a_w, b_w;
    wire [6:0] funct7_w;
    wire [2:0] type_w;
    inst_splitter w_split(
        .opcode(opcode_w),
        .rd(rd_w),
        .funct3(funct3_w),
        .rs1(a_w), .rs2(b_w),
        .funct7(funct7_w),
        .inst_type(type_w)
    );

    wire write_back;
    assign write_back = type_w != S_TYPE && type_w != B_TYPE && rd_w != 'd0;

    reg a_forward_1, b_forward_1, a_forward_2, b_forward_2;
    assign AFrwd1 = a_forward_1;
    assign BFrwd1 = b_forward_1;
    assign AFrwd2 = a_forward_2;
    assign BFrwd2 = b_forward_2;

    always @(*) begin
      if (write_back) begin
        a_forward_1 = rd_w == a_xm;
        b_forward_1 = rd_w == b_xm;
        a_forward_2 = rd_w == a_fd;
        b_forward_2 = rd_w == b_fd;
      end else begin
        a_forward_1 = 1'd0;
        b_forward_1 = 1'd0;
        a_forward_2 = 1'd0;
        b_forward_2 = 1'd0;
      end
    end

endmodule
