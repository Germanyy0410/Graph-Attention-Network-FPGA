module SPMM #(
  //* ========== parameter ===========
  parameter DATA_WIDTH        = 8,
  parameter DOT_PRODUCT_SIZE  = 5,
  // -- H
  parameter H_NUM_OF_COLS     = DOT_PRODUCT_SIZE,
  parameter H_NUM_OF_ROWS     = 5,
  parameter COL_INDEX_SIZE    = 8,
  parameter VALUE_SIZE        = 8,
  parameter NODE_INFO_SIZE    = 5,
  // -- W
  parameter W_NUM_OF_ROWS     = DOT_PRODUCT_SIZE,
  parameter W_NUM_OF_COLS     = 5,

  //* ========= localparams ==========
  // -- col_idx
  parameter COL_IDX_WIDTH     = $clog2(H_NUM_OF_COLS),
  // -- value
  parameter VALUE_WIDTH       = DATA_WIDTH,
  // -- row_info
  parameter ROW_LEN_WIDTH     = $clog2(H_NUM_OF_COLS),
  parameter ROW_INFO_WIDTH    = ROW_LEN_WIDTH + 1
)(
  input clk,
  input rst_n,
  // -- inputs
  // -- -- H
  input   [COL_IDX_WIDTH-1:0]     row_col_idx_i   [0:H_NUM_OF_ROWS-1] [0:H_NUM_OF_COLS-1]   ,
  input   [VALUE_WIDTH-1:0]       row_value_i     [0:H_NUM_OF_ROWS-1] [0:H_NUM_OF_COLS-1]   ,
  input   [ROW_INFO_WIDTH-1:0]    row_info_i      [0:H_NUM_OF_ROWS-1]                       ,
  // -- -- W
  input   [DATA_WIDTH-1:0]        weight_i        [0:W_NUM_OF_ROWS-1] [0:W_NUM_OF_COLS-1]   ,
  // -- outputs
  output  [DATA_WIDTH-1:0]        wh_o            [0:H_NUM_OF_ROWS-1] [0:W_NUM_OF_COLS-1]
);
  //* ========== wire declaration ===========
  wire    [DATA_WIDTH-1:0]        weight_T        [0:W_NUM_OF_COLS-1] [0:W_NUM_OF_ROWS-1]   ;
  wire    [DATA_WIDTH-1:0]        wh_T            [0:W_NUM_OF_COLS-1] [0:H_NUM_OF_ROWS-1]   ;

  //* ========= internal declaration ========
  genvar i, k;

  //* ======= [weight transpose w^T] ========
  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      for (k = 0; k < W_NUM_OF_ROWS; k = k + 1) begin
        assign weight_T[i][k] = weight_i[k][i];
      end
    end
  endgenerate

  //* =========== [(wh)^T -> wh] ============
  generate
    for (i = 0; i < H_NUM_OF_ROWS; i = i + 1) begin
      for (k = 0; k < W_NUM_OF_COLS; k = k + 1) begin
        assign wh_o[i][k] = wh_T[k][i];
      end
    end
  endgenerate

  //* ============ instantiation ============
  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      SPV #(
        .DATA_WIDTH(DATA_WIDTH),
        .DOT_PRODUCT_SIZE(DOT_PRODUCT_SIZE),
        .H_NUM_OF_COLS(H_NUM_OF_COLS),
        .H_NUM_OF_ROWS(H_NUM_OF_ROWS),

        .COL_INDEX_SIZE(COL_INDEX_SIZE),
        .VALUE_SIZE(VALUE_SIZE),
        .NODE_INFO_SIZE(NODE_INFO_SIZE),

        .W_NUM_OF_ROWS(W_NUM_OF_ROWS),
        .W_NUM_OF_COLS(W_NUM_OF_COLS)
      ) u_SPV (
        .clk(clk),
        .rst_n(rst_n),

        .row_col_idx_i(row_col_idx_i),
        .row_value_i(row_value_i),
        .row_info_i(row_info_i),

        .weight_i(weight_T[i]),

        .result_o(wh_T[i])
      );
    end
  endgenerate
endmodule