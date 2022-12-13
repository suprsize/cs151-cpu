module w_logic #(
    parameter W_SIZE = 32
) (
    input [2:0] type_w,
    input is_csr_w,
    output RegWEn, 
    output CSRWen
    );

    localparam
    R_TYPE = 3'd0, 
    I_TYPE = 3'd1,
    S_TYPE = 3'd2,
    B_TYPE = 3'd3,
    U_TYPE = 3'd4,
    J_TYPE = 3'd5,
    C_TYPE = 3'd6;

    reg reg_write_enable;
    assign RegWEn = reg_write_enable;
    assign CSRWen = is_csr_w;

    always @(*) begin
      case(type_w) 
      R_TYPE,
      U_TYPE,
      J_TYPE,  
      I_TYPE:  reg_write_enable = TRUE; // TODO: I_TYPE DOESN'T NEED TO DEPEND ON CSR IF C_TYPE IS SEPARATED.
      default: reg_write_enable = FALSE;  // S and B types are covered
      endcase
    end
endmodule
