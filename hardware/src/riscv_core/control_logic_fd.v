module control_logic #(
    parameter W_SIZE = 32
) (
    input [W_SIZE-1:0] inst_fd,
    input [W_SIZE-1:0] PC_fd, 
    output InstSel,
    output [2:0] ImmSel 
);

    assign InstSel = PC_fd[30]; 
    inst_splitter fd_split(
        .inst(inst_fd),
        .inst_type(ImmSel)
    );

endmodule
