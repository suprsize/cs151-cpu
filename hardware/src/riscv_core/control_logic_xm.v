module control_logic #(
    parameter W_SIZE = 32
) (
    input [W_SIZE-1:0] inst_xm,
    output [2:0] BrSel, // Basically Func3
    output ASel,
    output BSel,
    output MemRW, 
    output IMemWE,
    output [3:0] ALUSel,
    output UART_Write_valid,
    output UART_Ready_To_Receive
);



endmodule
