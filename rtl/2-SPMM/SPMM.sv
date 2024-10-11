module SPMM #(
  //* ========== parameter ===========
  parameter DATA_WIDTH        = 8,
  parameter DOT_PRODUCT_SIZE  = 1433,
  // -- H
  parameter H_NUM_OF_COLS     = DOT_PRODUCT_SIZE,
  parameter H_NUM_OF_ROWS     = 20,
  parameter COL_INDEX_SIZE    = 8,
  parameter VALUE_SIZE        = 8,
  parameter NODE_INFO_SIZE    = H_NUM_OF_ROWS,
  // -- W
  parameter W_NUM_OF_ROWS     = DOT_PRODUCT_SIZE,
  parameter W_NUM_OF_COLS     = 1,

  //* ========= localparams ==========
  // -- col_idx
  parameter COL_IDX_WIDTH     = $clog2(H_NUM_OF_COLS),
  // -- value
  parameter VALUE_WIDTH       = DATA_WIDTH,
  // -- row_info
  parameter ROW_LEN_WIDTH     = $clog2(H_NUM_OF_COLS),
  parameter NODE_INFO_WIDTH   = ROW_LEN_WIDTH + 1,
  parameter FF_DATA_WIDTH     = COL_IDX_WIDTH + VALUE_WIDTH
)(
  input clk,
  input rst_n,
  input                           h_ready_i                                                 ,
  // -- H
  // -- -- col_idx & value
  input   [FF_DATA_WIDTH-1:0]     H_data_o        [0:H_NUM_OF_ROWS-1]                       ,
  input   [H_NUM_OF_ROWS-1:0]     H_full                                                    ,
  input   [H_NUM_OF_ROWS-1:0]     H_empty                                                   ,
  output  [H_NUM_OF_ROWS-1:0]     H_rd_valid                                                ,
  // -- -- node_info
  input   [NODE_INFO_WIDTH-1:0]   node_info_i     [0:H_NUM_OF_ROWS-1]                       ,
  // -- W
  input   [DATA_WIDTH-1:0]        weight_i        [0:W_NUM_OF_COLS-1] [0:W_NUM_OF_ROWS-1]   ,
  // -- outputs
  output  [DATA_WIDTH-1:0]        wh_o            [0:H_NUM_OF_ROWS-1] [0:W_NUM_OF_COLS-1]
);
  //* ========== wire declaration ===========
  wire    [DATA_WIDTH-1:0]        wh_T            [0:W_NUM_OF_COLS-1] [0:H_NUM_OF_ROWS-1]   ;

  //* ========= internal declaration ========
  genvar i, k;

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
        .DATA_WIDTH       (DATA_WIDTH       ),
        .DOT_PRODUCT_SIZE (DOT_PRODUCT_SIZE ),
        .H_NUM_OF_COLS    (H_NUM_OF_COLS    ),
        .H_NUM_OF_ROWS    (H_NUM_OF_ROWS    ),
        .COL_INDEX_SIZE   (COL_INDEX_SIZE   ),
        .VALUE_SIZE       (VALUE_SIZE       ),
        .NODE_INFO_SIZE   (NODE_INFO_SIZE   ),
        .W_NUM_OF_ROWS    (W_NUM_OF_ROWS    ),
        .W_NUM_OF_COLS    (W_NUM_OF_COLS    )
      ) u_SPV (
        .clk              (clk              ),
        .rst_n            (rst_n            ),
        .h_ready_i        (h_ready_i        ),

        .H_data_o         (H_data_o         ),
        .H_full           (H_full           ),
        .H_empty          (H_empty          ),
        .H_rd_valid       (H_rd_valid       ),
        .node_info_i      (node_info_i      ),

        .weight_i         (weight_i[i]      ),
        .result_o         (wh_T[i]          )
      );
    end
  endgenerate
endmodule