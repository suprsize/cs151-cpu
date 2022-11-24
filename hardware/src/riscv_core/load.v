module load #(
    parameter W_SIZE = 32
) (
    input [W_SIZE-1:0] mem_data,
    input [15:0] addr,
    input [2:0] func3,
    output [W_SIZE-1:0] load_data
);
    localparam LB_FUNC3     = 3'd0;
    localparam LH_FUNC3     = 3'd1;
    localparam LW_FUNC3     = 3'd2;  
    localparam LBU_FUNC3    = 3'd4;
    localparam LHU_FUNC3    = 3'd5;  

    reg [W_SIZE-1:0] out;
    wire [W_SIZE-1:0] shifted_data;
    wire [4:0] bytes_to_shift;

    assign load_data = out; 
    assign bytes_to_shift = {addr[1:0], 3'd0};
    assign shifted_data = mem_data >> bytes_to_shift;
 

    always @(*) begin
      case(func3)
        LB_FUNC3:  out = { {24{shifted_data[7]}}, shifted_data[7:0] };
        LH_FUNC3:  out = { {16{shifted_data[15]}}, shifted_data[15:0]};
        LW_FUNC3:  out = mem_data;
        LBU_FUNC3: out = {24'b0, shifted_data[7:0]};
        LHU_FUNC3: out = {16'b0, shifted_data[15:0]};
        default:   out = mem_data;
      endcase
    end


endmodule
