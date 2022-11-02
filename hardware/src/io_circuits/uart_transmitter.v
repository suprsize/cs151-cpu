module uart_transmitter #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200)
(
    input clk,
    input reset,

    input [7:0] data_in,
    input data_in_valid,
    output data_in_ready,

    output serial_out
);
    // See diagram in the lab guide
    localparam  SYMBOL_EDGE_TIME    =   CLOCK_FREQ / BAUD_RATE;
    localparam  CLOCK_COUNTER_WIDTH =   $clog2(SYMBOL_EDGE_TIME);

    // Remove these assignments when implementing this module
 


    wire symbol_edge;
    wire start;
    wire rx_running;

    reg [9:0] rx_shift;
    reg [3:0] bit_counter;
    reg [CLOCK_COUNTER_WIDTH-1:0] clock_counter;

    //--|Signal Assignments|------------------------------------------------------

    // Goes high at every symbol edge
    /* verilator lint_off WIDTH */
    assign symbol_edge = clock_counter == (SYMBOL_EDGE_TIME - 1);
    /* lint_on */


    // Goes high when it is time to start sending a new character
    assign start = data_in_valid && !rx_running;

    // Goes high while we are receiving a character
    assign rx_running = bit_counter != 4'd0;

    // Outputs
    assign serial_out = rx_shift[0];
    assign data_in_ready = !rx_running;
    

    //--|Counters|----------------------------------------------------------------

    // Counts cycles until a single symbol is done
    always @ (posedge clk) begin
        clock_counter <= (start || reset || symbol_edge) ? 0 : clock_counter + 1;
    end

    // Counts down from 10 bits for every character
    always @ (posedge clk) begin
        if (reset) begin
            bit_counter <= 0;
        end else if (start) begin
            bit_counter <= 10;
        end else if (symbol_edge && rx_running) begin
            bit_counter <= bit_counter - 1;
        end
    end

    //--|Shift Register|----------------------------------------------------------
    always @(posedge clk) begin
        if (reset) rx_shift <= 1;
        else if (start) rx_shift <= {1'b1, data_in, 1'b0};
        else if (symbol_edge && rx_running) rx_shift <= {1'b1, rx_shift[9:1]};
    end


endmodule
