module mult_8_bit #(
  parameter MULT_MODE       = 0,
  parameter IN_DATA_WIDTH   = 8,
  parameter OUT_DATA_WIDTH  = 12
)(
  input                               clk,
  input signed  [IN_DATA_WIDTH-1:0]   a_i,
  input signed  [IN_DATA_WIDTH-1:0]   b_i,
  output signed [OUT_DATA_WIDTH-1:0]  p_o
);

  logic [IN_DATA_WIDTH-1:0]   a_abs;
  logic [IN_DATA_WIDTH-1:0]   b_abs;
  logic [OUT_DATA_WIDTH-1:0]  p_abs;

  generate
    if (MULT_MODE == 0) begin : OPTIMIZED
      assign p_o    = (~(b_i[7] ^ a_i[7])) ? p_abs : (~p_abs + 1);

      assign a_abs  = a_i[7] ? (~(a_i - 1)) : a_i;
      assign b_abs  = b_i[7] ? (~(b_i - 1)) : b_i;
      assign p_abs  = (b_abs[6] ? {a_abs, 6'b0} : 0) +
                      (b_abs[5] ? {a_abs, 5'b0} : 0) +
                      (b_abs[4] ? {a_abs, 4'b0} : 0) +
                      (b_abs[3] ? {a_abs, 3'b0} : 0) +
                      (b_abs[2] ? {a_abs, 2'b0} : 0) +
                      (b_abs[1] ? {a_abs, 1'b0} : 0) +
                      (b_abs[0] ? {a_abs, 0'b0} : 0);
    end
    else if (MULT_MODE == 1) begin : ONE_STAGE_OPTIMIZED
      logic signed  [OUT_DATA_WIDTH:0]    p;
      logic signed  [OUT_DATA_WIDTH:0]    p_reg;

      assign p_o    = p_reg;
      assign p      = ((b_i[7] ^ a_i[7])) ? (~p_abs + 1) : p_abs;

      assign a_abs  = a_i[7] ? (~(a_i - 1)) : a_i;
      assign b_abs  = b_i[7] ? (~(b_i - 1)) : b_i;
      assign p_abs  = (b_abs[6] ? {a_abs, 6'b0} : 0) +
                      (b_abs[5] ? {a_abs, 5'b0} : 0) +
                      (b_abs[4] ? {a_abs, 4'b0} : 0) +
                      (b_abs[3] ? {a_abs, 3'b0} : 0) +
                      (b_abs[2] ? {a_abs, 2'b0} : 0) +
                      (b_abs[1] ? {a_abs, 1'b0} : 0) +
                      (b_abs[0] ? {a_abs, 0'b0} : 0);

      always_ff @(posedge clk) begin
        p_reg <= p;
      end
    end
    else if (MULT_MODE == 2) begin : NORMAL
      assign p_o = $signed(a_i) * $signed(b_i);
    end
    else if (MULT_MODE == 3) begin : ONE_STAGE_NORMAL
      logic signed  [OUT_DATA_WIDTH:0]    p;
      logic signed  [OUT_DATA_WIDTH:0]    p_reg;

      assign p_o = p_reg;
      assign p   = $signed(a_i) * $signed(b_i);

      always_ff @(posedge clk) begin
        p_reg <= p;
      end
    end
  endgenerate
endmodule