module store #(
    parameter W_SIZE = 32
) (
    input [W_SIZE-1:0] din,
    input [15:0] addr,
    input [2:0] func3,
    input we,
    output [W_SIZE-1:0] store_data,
    output [13:0] mem_addr,
    output [3:0] MemRw4
);
    localparam STORE_OPCODE = 7'h23; // 23 in hex
    localparam SB_FUNC3 = 3'd0;
    localparam SH_FUNC3 = 3'd1;
    localparam SW_FUNC3 = 3'd2;  



    reg [W_SIZE-1:0] out;
    reg [3:0] mask;
    wire [W_SIZE-1:0] shifted_data;
    wire [4:0] bytes_to_shift;

    assign bytes_to_shift = {addr[1:0], 3'd0};
    assign shifted_data = din << bytes_to_shift;
    assign mem_addr = addr[15:2];

    assign store_data = shifted_data;    
    assign MemRw4 = we? mask : 4'd0;

    always @(*) begin
      case(func3)
        SB_FUNC3:  mask = 4'b0001 << addr[1:0];
        SH_FUNC3:  mask = 4'b0011 << addr[1:0];
        SW_FUNC3:  mask = 4'b1111;
        default:   mask = 4'd0;
      endcase
    end


endmodule
