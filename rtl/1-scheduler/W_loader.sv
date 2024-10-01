module W_loader #(
  //* ========== parameter ===========
  parameter DATA_WIDTH        = 8,
  parameter W_NUM_OF_ROWS     = 5,
  parameter W_NUM_OF_COLS     = 3
)(
  input clk,
  input rst_n,

  input   [DATA_WIDTH-1:0]    weight_i    [0:W_NUM_OF_ROWS-1] [0:W_NUM_OF_COLS-1] ,
  output  [DATA_WIDTH-1:0]    weight_o    [0:W_NUM_OF_COLS-1] [0:W_NUM_OF_ROWS-1]
);
  genvar i, k;

  //* ======= [weight transpose w^T] ========
  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      for (k = 0; k < W_NUM_OF_ROWS; k = k + 1) begin
        assign weight_o[i][k] = weight_i[k][i];
      end
    end
  endgenerate
endmodule