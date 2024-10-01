module scheduler #(
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
  parameter W_NUM_OF_COLS     = 3,

  //* ========= localparams ==========
  // -- inputs
  // -- -- col_idx
  parameter COL_IDX_WIDTH     = $clog2(H_NUM_OF_COLS),
  // -- -- value
  parameter VALUE_WIDTH       = DATA_WIDTH,
  // -- -- node_info = [idx, row_len, flag]
  parameter INDEX_WIDTH       = $clog2(COL_INDEX_SIZE),
  parameter ROW_LEN_WIDTH     = $clog2(H_NUM_OF_COLS),
  parameter NODE_INFO_WIDTH   = INDEX_WIDTH + ROW_LEN_WIDTH + 1,
  // -- outputs
  // -- -- row_info = [row_len, flag]
  parameter ROW_INFO_WIDTH    = ROW_LEN_WIDTH + 1
)(
  input clk,
  input rst_n,

  input                         h_valid_i                                               ,
  input [COL_IDX_WIDTH-1:0]     col_idx_i       [0:COL_INDEX_SIZE-1]                    ,
  input [VALUE_WIDTH-1:0]       value_i         [0:VALUE_SIZE-1]                        ,
  input [NODE_INFO_WIDTH-1:0]   node_info_i     [0:NODE_INFO_SIZE-1]                    ,
  input [DATA_WIDTH-1:0]        weight_i        [0:W_NUM_OF_ROWS-1] [0:W_NUM_OF_COLS-1]
);
  wire  [COL_IDX_WIDTH-1:0]     row_col_idx_o   [0:H_NUM_OF_ROWS-1] [0:H_NUM_OF_COLS-1] ;
  wire  [VALUE_WIDTH-1:0]       row_value_o     [0:H_NUM_OF_ROWS-1] [0:H_NUM_OF_COLS-1] ;
  wire  [ROW_INFO_WIDTH-1:0]    row_info_o      [0:H_NUM_OF_ROWS-1]                     ;
  wire  [DATA_WIDTH-1:0]        weight          [0:W_NUM_OF_COLS-1] [0:W_NUM_OF_ROWS-1] ;

  H_loader #(
    .DATA_WIDTH     (DATA_WIDTH     ),
    .NUM_OF_COLS    (H_NUM_OF_COLS  ),
    .NUM_OF_ROWS    (H_NUM_OF_ROWS  ),
    .COL_INDEX_SIZE (COL_INDEX_SIZE ),
    .VALUE_SIZE     (VALUE_SIZE     ),
    .NODE_INFO_SIZE (NODE_INFO_SIZE )
  ) u_H_loader (
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .h_valid_i      (h_valid_i      ),
    .col_idx_i      (col_idx_i      ),
    .value_i        (value_i        ),
    .node_info_i    (node_info_i    ),
    .row_col_idx_o  (row_col_idx_o  ),
    .row_value_o    (row_value_o    ),
    .row_info_o     (row_info_o     )
  );

  W_loader #(
    .DATA_WIDTH     (DATA_WIDTH     ),
    .W_NUM_OF_COLS  (W_NUM_OF_COLS  ),
    .W_NUM_OF_ROWS  (W_NUM_OF_ROWS  )
  ) u_W_loader (
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .weight_i       (weight_i       ),
    .weight_o       (weight         )
  );

  SPMM #(
    .DATA_WIDTH       (DATA_WIDTH       ),
    .DOT_PRODUCT_SIZE (DOT_PRODUCT_SIZE ),
    .H_NUM_OF_COLS    (H_NUM_OF_COLS    ),
    .H_NUM_OF_ROWS    (H_NUM_OF_ROWS    ),
    .COL_INDEX_SIZE   (COL_INDEX_SIZE   ),
    .VALUE_SIZE       (VALUE_SIZE       ),
    .NODE_INFO_SIZE   (NODE_INFO_SIZE   ),
    .W_NUM_OF_ROWS    (W_NUM_OF_ROWS    ),
    .W_NUM_OF_COLS    (W_NUM_OF_COLS    )
  ) u_SPMM (
    .clk              (clk              ),
    .rst_n            (rst_n            ),
    .row_col_idx_i    (row_col_idx_o    ),
    .row_value_i      (row_value_o      ),
    .row_info_i       (row_info_o       ),
    .weight_i         (weight           )
  );
endmodule