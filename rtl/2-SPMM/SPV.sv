module SPV #(
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
  input   [DATA_WIDTH-1:0]        weight_i        [0:W_NUM_OF_ROWS-1]                       ,
  // -- outputs
  output  [DATA_WIDTH-1:0]        result_o        [0:DOT_PRODUCT_SIZE-1]
);
  //* ========== wire declaration ===========
  wire spv_ready [0:DOT_PRODUCT_SIZE-1];

  //* ========= internal declaration ========
  genvar i;

  //* ============ instantiation ============
  generate
    for (i = 0; i < DOT_PRODUCT_SIZE; i = i + 1) begin
      SP_PE #(
        .DATA_WIDTH(DATA_WIDTH),
        .DOT_PRODUCT_SIZE(DOT_PRODUCT_SIZE)
      ) u_SP_PE (
        .clk(clk),
        .rst_n(rst_n),

        .pe_valid_i(1'b1),
        .col_idx_i(row_col_idx_i[i]),
        .value_i(row_value_i[i]),
        .node_info_i(row_info_i[i]),
        .weight_i(weight_i),

        .pe_ready_o(spv_ready[i]),
        .result_o(result_o[i])
      );
    end
  endgenerate
endmodule