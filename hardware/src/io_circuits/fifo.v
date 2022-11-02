module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 32,
    parameter POINTER_WIDTH = $clog2(DEPTH)
) (
    input clk, rst,

    // Write side
    input wr_en,
    input [WIDTH-1:0] din,
    output full,

    // Read side
    input rd_en,
    output [WIDTH-1:0] dout,
    output empty
);

	reg [POINTER_WIDTH:0] wr_pointer;
	reg [POINTER_WIDTH:0] rd_pointer;
	reg [WIDTH-1:0] stack [DEPTH-1:0]; 
	reg [WIDTH-1:0] read_out;
	
	//--|Signal Assignments|------------------------------------------------------

    assign empty = wr_pointer[POINTER_WIDTH:0] == rd_pointer[POINTER_WIDTH:0];
    assign full = wr_pointer[POINTER_WIDTH-1:0] == rd_pointer[POINTER_WIDTH-1:0]  && (wr_pointer[POINTER_WIDTH] != rd_pointer[POINTER_WIDTH]);
    assign dout = read_out; 
    
    //-- WRITE
    always @(posedge clk) begin
		if (rst) wr_pointer <= 0;
		else if (wr_en && !full) begin
				stack[wr_pointer[POINTER_WIDTH-1:0]] <= din;
				wr_pointer <= wr_pointer + 1;
		end
    end
    
    //-- READ
    always @(posedge clk) begin
		if (rst) rd_pointer <= 0;
		else if (rd_en && !empty) begin
				read_out <= stack[rd_pointer[POINTER_WIDTH-1:0]];
				rd_pointer <= rd_pointer + 1;
		end
    end
    
    
    
endmodule
