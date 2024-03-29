module debouncer #(
    parameter WIDTH              = 1,
    parameter SAMPLE_CNT_MAX     = 62500,
    parameter PULSE_CNT_MAX      = 200,
    parameter WRAPPING_CNT_WIDTH = $clog2(SAMPLE_CNT_MAX),
    parameter SAT_CNT_WIDTH      = $clog2(PULSE_CNT_MAX) + 1
) (
    input clk,
    input [WIDTH-1:0] glitchy_signal,
    output reg [WIDTH-1:0] debounced_signal
);
    // TODO: fill in neccesary logic to implement the wrapping counter and the saturating counters
    // Some initial code has been provided to you, but feel free to change it however you like
    // One wrapping counter is required
    // One saturating counter is needed for each bit of glitchy_signal
    // You need to think of the conditions for reseting, clock enable, etc. those registers
    // Refer to the block diagram in the spec

    // Remove this line once you have created your debouncer

    reg [SAT_CNT_WIDTH-1:0] saturating_counter [WIDTH-1:0];
    integer i;
    initial begin
        for (i = 0; i < WIDTH; i = i +1) begin
            saturating_counter[i] = 0;
        end
    end
    
    reg [WRAPPING_CNT_WIDTH - 1: 0] wrapper_counter = 0;
    wire [WRAPPING_CNT_WIDTH - 1: 0] sample_max = SAMPLE_CNT_MAX[WRAPPING_CNT_WIDTH - 1: 0];
    wire [SAT_CNT_WIDTH-1:0] pulse_max = PULSE_CNT_MAX[SAT_CNT_WIDTH - 1: 0];


    always @(posedge clk) begin
        if (wrapper_counter == sample_max) wrapper_counter <= 0;
        else wrapper_counter <= wrapper_counter + 1;
    end

    genvar k;
    generate
        for (k = 0; k < WIDTH; k = k +1) begin
            always @(posedge clk) begin
                // debouncer
                if (glitchy_signal[k]) begin
				    if (wrapper_counter == sample_max) begin 
                        if (saturating_counter[k] != pulse_max) saturating_counter[k] <= saturating_counter[k] + 1;
                    end
                end
                else saturating_counter[k] <= 0;
            end
        end
    endgenerate    


    generate
        for (k = 0; k < WIDTH; k = k +1) begin
            always @(*) begin
                debounced_signal[k] = (saturating_counter[k] == pulse_max);
            end
        end

    endgenerate 

endmodule
