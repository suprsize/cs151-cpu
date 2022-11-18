module w_logic #(
    parameter W_SIZE = 32
) (
  //TODO: need to add inst_fd as an input in order to cover for jal special case calculate the pcSel.
    input [W_SIZE-1:0] inst_w,
    input [W_SIZE-1:0] inst_fd,
    input BrTaken,
    input BIOSRest,
    output [1:0] PCSel, 
    output Flush,
    output RegWEn, 
    output CSRWen,
    output [2:0] WBSel
);


endmodule
