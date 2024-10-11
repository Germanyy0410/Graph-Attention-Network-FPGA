module SPV #(
  //* ========== parameter ===========
  parameter DATA_WIDTH        = 8,
  parameter DOT_PRODUCT_SIZE  = 5,
  // -- H
  parameter H_NUM_OF_COLS     = DOT_PRODUCT_SIZE,
  parameter H_NUM_OF_ROWS     = 5,
  parameter COL_INDEX_SIZE    = 8,
  parameter VALUE_SIZE        = 8,
  parameter NODE_INFO_SIZE    = H_NUM_OF_ROWS,
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
  parameter NODE_INFO_WIDTH   = ROW_LEN_WIDTH + 1,
  parameter FF_DATA_WIDTH     = COL_IDX_WIDTH + VALUE_WIDTH
)(
  input clk,
  input rst_n,
  // -- inputs
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
  input   [DATA_WIDTH-1:0]        weight_i        [0:W_NUM_OF_ROWS-1]                       ,
  // -- outputs
  output  [DATA_WIDTH-1:0]        result_o        [0:H_NUM_OF_ROWS-1]
);
  //* ========== wire declaration ===========
  wire spv_ready [0:DOT_PRODUCT_SIZE-1];

  //* ========= internal declaration ========
  genvar i;

  //* ============ instantiation ============
  generate
    for (i = 0; i < H_NUM_OF_ROWS; i = i + 1) begin
      SP_PE #(
        .DATA_WIDTH       (DATA_WIDTH       ),
        .DOT_PRODUCT_SIZE (DOT_PRODUCT_SIZE )
      ) u_SP_PE (
        .clk              (clk              ),
        .rst_n            (rst_n            ),
        .pe_valid_i       (h_ready_i        ),

        .H_data_o         (H_data_o[i]      ),
        .H_full           (H_full[i]        ),
        .H_empty          (H_empty[i]       ),
        .H_rd_valid       (H_rd_valid[i]    ),
        .node_info_i      (node_info_i[i]   ),

        .weight_i         (weight_i         ),
        .pe_ready_o       (spv_ready[i]     ),
        .result_o         (result_o[i]      )
      );
    end
  endgenerate
endmodule