module scheduler #(
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
  parameter W_NUM_OF_COLS     = 3,

  //* ========= localparams ==========
  // -- inputs
  // -- -- col_idx
  parameter COL_IDX_WIDTH     = $clog2(H_NUM_OF_COLS),
  // -- -- value
  parameter VALUE_WIDTH       = DATA_WIDTH,
  // -- -- node_info = [row_len, flag]
  parameter ROW_LEN_WIDTH     = $clog2(H_NUM_OF_COLS),
  parameter NODE_INFO_WIDTH   = ROW_LEN_WIDTH + 1,
  // -- outputs
  // -- -- row_info = [row_len, flag]
  parameter ROW_INFO_WIDTH    = ROW_LEN_WIDTH + 1,
  parameter FF_DATA_WIDTH     = COL_IDX_WIDTH + VALUE_WIDTH
)(
  input clk,
  input rst_n,

  input                         h_valid_i                                               ,
  input [COL_IDX_WIDTH-1:0]     col_idx_i       [0:COL_INDEX_SIZE-1]                    ,
  input [VALUE_WIDTH-1:0]       value_i         [0:VALUE_SIZE-1]                        ,
  input [NODE_INFO_WIDTH-1:0]   node_info_i     [0:NODE_INFO_SIZE-1]                    ,
  input [DATA_WIDTH-1:0]        weight_i        [0:W_NUM_OF_ROWS-1] [0:W_NUM_OF_COLS-1] ,
  output                        h_ready_o
);
  wire  [DATA_WIDTH-1:0]        weight          [0:W_NUM_OF_COLS-1] [0:W_NUM_OF_ROWS-1] ;

  wire  [FF_DATA_WIDTH-1:0]     H_data_i        [0:H_NUM_OF_ROWS-1]                     ;
  wire  [FF_DATA_WIDTH-1:0]     H_data_o        [0:H_NUM_OF_ROWS-1]                     ;
  wire  [H_NUM_OF_ROWS-1:0]     H_rd_valid                                              ;
  wire  [H_NUM_OF_ROWS-1:0]     H_wr_valid                                              ;
  wire  [H_NUM_OF_ROWS-1:0]     H_full                                                  ;
  wire  [H_NUM_OF_ROWS-1:0]     H_empty                                                 ;

  genvar i;

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
    .H_data_i       (H_data_i       ),
    .H_wr_valid     (H_wr_valid     ),
    .h_ready_o      (h_ready_o      )
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

    .H_data_o         (H_data_o         ),
    .H_full           (H_full           ),
    .H_empty          (H_empty          ),
    .H_rd_valid       (H_rd_valid       ),
    .node_info_i      (node_info_i      ),

    .weight_i         (weight           ),
    .h_ready_i        (h_ready_o        )
  );

  generate
    for (i = 0; i < H_NUM_OF_ROWS; i = i + 1) begin
      fifo #(
        .DATA_WIDTH (FF_DATA_WIDTH    ),
        .FIFO_DEPTH (H_NUM_OF_COLS    )
      ) u_H_row_fifo (
        .clk        (clk              ),
        .rst_n      (rst_n            ),
        .data_i     (H_data_i[i]      ),
        .data_o     (H_data_o[i]      ),
        .wr_valid_i (H_wr_valid[i]    ),
        .rd_valid_i (H_rd_valid[i]    ),
        .full_o     (H_full[i]        ),
        .empty_o    (H_empty[i]       )
      );
    end
  endgenerate

  ////////////////////////////////
  // wire  [12:0]                  addra           [0:H_NUM_OF_ROWS-1]                     ;
  // wire  [12:0]                  addrb           [0:H_NUM_OF_ROWS-1]                     ;
  // wire  [31:0]                  dina            [0:H_NUM_OF_ROWS-1]                     ;
  // wire  [31:0]                  doutb_0         [0:H_NUM_OF_ROWS-1]                     ;
  // wire  [H_NUM_OF_ROWS-1:0]     ena                                                     ;
  // wire  [H_NUM_OF_ROWS-1:0]     enb                                                     ;
  // wire  [H_NUM_OF_ROWS-1:0]     wea                                                     ;

  // reg   [H_NUM_OF_ROWS-1:0]     bram_valid                                              ;
  // reg   [H_NUM_OF_ROWS-1:0]     bram_valid_reg                                          ;
  // reg   [H_NUM_OF_ROWS-1:0]     bram_ready                                              ;
  // reg   [H_NUM_OF_ROWS-1:0]     bram_ready_reg                                          ;

  // reg   [COL_IDX_WIDTH-1:0]     counter         [0:H_NUM_OF_ROWS-1]                     ;
  // reg   [COL_IDX_WIDTH-1:0]     counter_reg     [0:H_NUM_OF_ROWS-1]                     ;

//   generate
//     for (i = 0; i < H_NUM_OF_ROWS; i = i + 1) begin
//       BRAM_wrapper u_BRAM (
//         .clka_0   (clk        ),
//         .clkb_0   (clk        ),
//         .addra    (addra[i]   ),
//         .addrb    (addrb[i]   ),
//         .dina     (dina[i]    ),
//         .doutb_0  (doutb_0[i] ),
//         .ena      (ena[i]     ),
//         .enb      (enb[i]     ),
//         .wea      (wea[i]     )
//       );
//     end
//   endgenerate

//   always @(posedge clk) begin
//     if (!rst_n) begin
//       bram_valid_reg <= 0;
//       bram_ready_reg <= 0;
//     end else begin
//       bram_valid_reg <= bram_valid;
//       bram_ready_reg <= bram_ready;
//     end
//   end

//   integer k;
//   always @(*) begin
//     for (k = 0; k < H_NUM_OF_ROWS; k = k + 1) begin
//       counter[k] = counter_reg[k];
//     end
//     bram_valid = bram_valid_reg;
//     bram_ready = bram_ready_reg;

//     for (k = 0; k < H_NUM_OF_ROWS; k = k + 1) begin
//       if (bram_valid_reg[k]) begin
//         if (counter_reg[k] <= row_info_o[k][ROW_INFO_WIDTH-1:1]) begin
//           counter[k] = counter_reg[k] + 1;
//         end else begin
//           bram_ready[k] = 1'b1;
//           bram_valid[k] = 1'b0;
//         end
//       end else if (h_ready_o) begin
//         bram_valid[k] = 1'b1;
//       end
//     end
//   end

//   generate
//     for (i = 0; i < H_NUM_OF_ROWS; i = i + 1) begin
//       always @(posedge clk) begin
//         if (!rst_n) begin
//           counter_reg[i] <= 0;
//         end else begin
//           counter_reg[i] <= counter[i];
//         end
//       end
//     end
//   endgenerate

//   generate
//     for (i = 0; i < H_NUM_OF_ROWS; i = i + 1) begin
//       assign dina[i] = {row_col_idx_o[i][counter_reg[i]], row_value_o[i][counter_reg[i]]};
//       assign addra[i] = counter_reg[i];
//       assign ena[i] = (bram_valid_reg[i]) ? 1'b1 : 1'b0;
//       assign wea[i] = (bram_valid_reg[i]) ? 1'b1 : 1'b0;
//     end
//   endgenerate
  ////////////////////////////////
endmodule


