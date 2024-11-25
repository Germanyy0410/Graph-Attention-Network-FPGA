module SPMM #(
  //* ========== parameter ===========
  parameter DATA_WIDTH          = 8,
  parameter WH_DATA_WIDTH       = 12,
  parameter DOT_PRODUCT_SIZE    = 1433,
  // -- H
  parameter H_NUM_OF_COLS       = 1433,
  parameter H_NUM_OF_ROWS       = 13264,
  // -- W
  parameter W_NUM_OF_ROWS       = 1433,
  parameter W_NUM_OF_COLS       = 16,
  // -- BRAM
  parameter COL_IDX_DEPTH       = 242101,
  parameter VALUE_DEPTH         = 242101,
  parameter NODE_INFO_DEPTH     = 13264,
  parameter WEIGHT_DEPTH        = 1433 * 16,
  parameter WH_DEPTH            = 242101,
// -- NUM_OF_NODES
  parameter NUM_OF_NODES        = 168,

  //* ========= localparams ==========
  // -- col_idx
  parameter COL_IDX_WIDTH       = $clog2(H_NUM_OF_COLS),
  parameter COL_IDX_ADDR_W      = $clog2(COL_IDX_DEPTH),
  // -- value
  parameter VALUE_WIDTH         = DATA_WIDTH,
  parameter VALUE_ADDR_W        = $clog2(VALUE_DEPTH),
  // -- row_info
  parameter ROW_LEN_WIDTH       = $clog2(H_NUM_OF_COLS),
  parameter NUM_NODE_WIDTH      = $clog2(NUM_OF_NODES),
  parameter NODE_INFO_WIDTH     = ROW_LEN_WIDTH + NUM_NODE_WIDTH + 1,
  parameter NODE_INFO_ADDR_W    = $clog2(NODE_INFO_DEPTH),
  // -- WH_BRAM
  parameter WH_WIDTH            = WH_DATA_WIDTH * W_NUM_OF_COLS + NUM_NODE_WIDTH + 1,
  parameter RESULT_WIDTH        = WH_DATA_WIDTH * W_NUM_OF_COLS,
  parameter WH_ADDR_W           = $clog2(WH_DEPTH),

  parameter WH_COL_WIDTH        = $clog2(H_NUM_OF_ROWS),
  parameter WH_ROW_WIDTH        = $clog2(W_NUM_OF_COLS),

  parameter MULT_WEIGHT_ADDR_W  = $clog2(W_NUM_OF_ROWS)
)(
  input                             clk                                                   ,
  input                             rst_n                                                 ,

  input                             spmm_valid_i                                          ,
  output  [W_NUM_OF_COLS-1:0]       pe_ready_o                                            ,
  // -- H_col_idx BRAM
  input   [COL_IDX_WIDTH-1:0]       H_col_idx_BRAM_dout                                   ,
  output  [COL_IDX_ADDR_W-1:0]      H_col_idx_BRAM_addrb                                  ,
  // -- H_value BRAM
  input   [VALUE_WIDTH-1:0]         H_value_BRAM_dout                                     ,
  output  [VALUE_ADDR_W-1:0]        H_value_BRAM_addrb                                    ,
  // -- H_node_info BRAM
  input   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout                                 ,
  input   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout_nxt                             ,
  output  [NODE_INFO_ADDR_W-1:0]    H_node_info_BRAM_addrb                                ,
  // -- Weight
  input   [DATA_WIDTH-1:0]          mult_weight_dout              [0:W_NUM_OF_COLS-1]     ,
  output  [MULT_WEIGHT_ADDR_W-1:0]  mult_weight_addrb             [0:W_NUM_OF_COLS-1]     ,
  // -- WH
  output  [WH_WIDTH-1:0]            WH_BRAM_din                                           ,
  output                            WH_BRAM_ena                                           ,
  output                            WH_BRAM_wea                                           ,
  output  [WH_ADDR_W-1:0]           WH_BRAM_addra
);

  typedef struct packed {
    bit [ROW_LEN_WIDTH-1:0]   row_length        ;
    bit [NUM_NODE_WIDTH-1:0]  num_of_nodes      ;
    bit                       source_node_flag  ;
  } node_info_t;

  typedef struct packed {
    bit [WH_DATA_WIDTH-1:0]   result_1          ;
    bit [WH_DATA_WIDTH-1:0]   result_2          ;
    bit [WH_DATA_WIDTH-1:0]   result_3          ;
    bit [WH_DATA_WIDTH-1:0]   result_4          ;
    bit [WH_DATA_WIDTH-1:0]   result_5          ;
    bit [WH_DATA_WIDTH-1:0]   result_6          ;
    bit [WH_DATA_WIDTH-1:0]   result_7          ;
    bit [WH_DATA_WIDTH-1:0]   result_8          ;
    bit [WH_DATA_WIDTH-1:0]   result_9          ;
    bit [WH_DATA_WIDTH-1:0]   result_10         ;
    bit [WH_DATA_WIDTH-1:0]   result_11         ;
    bit [WH_DATA_WIDTH-1:0]   result_12         ;
    bit [WH_DATA_WIDTH-1:0]   result_13         ;
    bit [WH_DATA_WIDTH-1:0]   result_14         ;
    bit [WH_DATA_WIDTH-1:0]   result_15         ;
    bit [WH_DATA_WIDTH-1:0]   result_16         ;
    bit [NUM_NODE_WIDTH-1:0]  num_of_nodes      ;
    bit                       source_node_flag  ;
  } WH_t;

  //* ======== internal declaration =========
  logic                         new_row_enable                          ;
  logic [ROW_LEN_WIDTH-1:0]     row_counter                             ;
  logic [ROW_LEN_WIDTH-1:0]     row_counter_reg                         ;

  // -- Address for H_BRAM
  logic [COL_IDX_ADDR_W-1:0]    data_addr                               ;
  logic [COL_IDX_ADDR_W-1:0]    data_addr_reg                           ;
  logic [NODE_INFO_ADDR_W-1:0]  node_info_addr                          ;
  logic [NODE_INFO_ADDR_W-1:0]  node_info_addr_reg                      ;

  // -- current data from BRAM
  logic [COL_IDX_WIDTH-1:0]     col_idx                                 ;
  logic [VALUE_WIDTH-1:0]       value                                   ;
  logic [ROW_LEN_WIDTH-1:0]     row_length                              ;
  logic                         source_node_flag                        ;
  logic [NUM_NODE_WIDTH-1:0]    num_of_nodes                            ;

  // -- next data from BRAM
  logic [ROW_LEN_WIDTH-1:0]     row_length_nxt                          ;
  logic                         source_node_flag_nxt                    ;
  logic [NUM_NODE_WIDTH-1:0]    num_of_nodes_nxt                        ;

  // -- FIFO
  node_info_t                   ff_data_i                               ;
  node_info_t                   ff_data_o                               ;
  logic                         ff_empty                                ;
  logic                         ff_full                                 ;
  logic                         ff_wr_valid                             ;
  logic                         ff_rd_valid                             ;
  node_info_t                   ff_node_info                            ;
  node_info_t                   ff_node_info_reg                        ;

  // -- data from FIFO
  logic [ROW_LEN_WIDTH-1:0]     ff_row_length                           ;
  logic [ROW_LEN_WIDTH-1:0]     ff_row_length_reg                       ;
  logic                         ff_source_node_flag                     ;
  logic                         ff_source_node_flag_reg                 ;
  logic [NUM_NODE_WIDTH-1:0]    ff_num_of_nodes                         ;
  logic [NUM_NODE_WIDTH-1:0]    ff_num_of_nodes_reg                     ;

  // -- SP-PE valid signal
  logic                         pe_valid                                ;
  logic                         pe_valid_reg                            ;
  logic                         spmm_valid_q1                           ;

  // -- SP-PE results
  logic [RESULT_WIDTH-1:0]      result_cat                              ;
  logic [WH_DATA_WIDTH-1:0]     result          [0:W_NUM_OF_COLS-1]     ;
  WH_t                          WH_data_i                               ;
  logic [WH_ADDR_W-1:0]         WH_addr                                 ;
  logic [WH_ADDR_W-1:0]         WH_addr_reg                             ;
  //* =======================================

  genvar i, k;
  integer x, y;

  //* ============ instantiation ============
  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      SP_PE #(
        .DATA_WIDTH       (DATA_WIDTH         ),
        .WH_DATA_WIDTH    (WH_DATA_WIDTH      ),
        .DOT_PRODUCT_SIZE (DOT_PRODUCT_SIZE   ),
        .WEIGHT_ADDR_W    (MULT_WEIGHT_ADDR_W )
      ) u_SP_PE (
        .clk                (clk                        ),
        .rst_n              (rst_n                      ),

        .pe_valid_i         (pe_valid                   ),
        .pe_ready_o         (pe_ready_o[i]              ),

        .col_idx_i          (col_idx                    ),
        .value_i            (value                      ),
        .row_length_i       (ff_row_length              ),

        .weight_addrb       (mult_weight_addrb[i]       ),
        .weight_dout        (mult_weight_dout[i]        ),
        .result_o           (result[i]                  )
      );
    end
  endgenerate

  fifo #(
    .DATA_WIDTH (NODE_INFO_WIDTH  ),
    .FIFO_DEPTH (NODE_INFO_DEPTH  )
  ) node_info_FIFO (
    .clk        (clk                    ),
    .rst_n      (rst_n                  ),

    .data_i     (H_node_info_BRAM_dout  ),
    .data_o     (ff_data_o              ),

    .wr_valid_i (ff_wr_valid            ),
    .rd_valid_i (ff_rd_valid            ),

    .empty_o    (ff_empty               ),
    .full_o     (ff_full                )
  );
  //* =======================================


  //* ====== assign result to WH BRAM =======
  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      assign result_cat[WH_DATA_WIDTH*(i+1)-1-:WH_DATA_WIDTH] = result[W_NUM_OF_COLS-1-i];
    end
  endgenerate
  assign WH_data_i      = { result_cat, ff_num_of_nodes_reg, ff_source_node_flag_reg };
  assign WH_BRAM_din    = WH_data_i;
  assign WH_BRAM_ena    = (&pe_ready_o);
  assign WH_BRAM_wea    = (&pe_ready_o);
  assign WH_BRAM_addra  = WH_addr_reg;

  assign WH_addr = (&pe_ready_o) ? (WH_addr_reg + 1) : WH_addr_reg;

  always @(posedge clk) begin
    if (!rst_n) begin
      WH_addr_reg <= 0;
    end else begin
      WH_addr_reg <= WH_addr;
    end
  end
  //* =======================================


  //* ======== pe_valid for SP-PE ===========
  always @(*) begin
    pe_valid = pe_valid_reg;

    if (spmm_valid_q1) begin
      if (data_addr_reg == 1) begin
        pe_valid = 1'b1;
      end else begin
        pe_valid = &pe_ready_o;
      end
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      pe_valid_reg <= 1'b0;
    end else begin
      pe_valid_reg <= pe_valid;
    end
  end

  always @(posedge clk) begin
    spmm_valid_q1 <= spmm_valid_i;
  end
  //* =======================================


  //* ======== Pop data into SP-PE ==========
  assign new_row_enable = ((row_counter_reg == 1 && row_length >= 2) || (row_length == 1)) && spmm_valid_q1;

  assign row_counter    = (((row_counter_reg == row_length - 1 && row_length > 1) || (row_counter_reg == 0 && row_length_nxt == 1)) && spmm_valid_q1) || (row_counter_reg == 0 && row_length == 1 && (spmm_valid_i ^ spmm_valid_q1))
                          ? 0
                          : ((((row_counter_reg < row_length - 1) && (row_length > 1)) || (row_length == 1 && row_length_nxt > 1)) && spmm_valid_i)
                            ? (row_counter_reg + 1)
                            : row_counter_reg;

  assign data_addr      = (spmm_valid_q1 && data_addr_reg < {COL_IDX_ADDR_W{1'b1}})
                          ? (data_addr_reg + 1)
                          : data_addr_reg;

  assign node_info_addr = (((row_counter_reg == 0 && row_length >= 2) || (row_length == 1)) && spmm_valid_q1 && (node_info_addr_reg < {NODE_INFO_ADDR_W{1'b1}}))
                          ? (node_info_addr_reg + 1)
                          : node_info_addr_reg;

  // -- col_idx
  assign col_idx                = H_col_idx_BRAM_dout;
  assign H_col_idx_BRAM_addrb   = data_addr_reg;

  // -- value
  assign value                  = H_value_BRAM_dout;
  assign H_value_BRAM_addrb     = data_addr_reg;

  // -- node_info
  assign { row_length, num_of_nodes, source_node_flag } = H_node_info_BRAM_dout;
  assign H_node_info_BRAM_addrb                         = node_info_addr;

  // -- next data
  assign { row_length_nxt, num_of_nodes_nxt, source_node_flag_nxt } = H_node_info_BRAM_dout_nxt;

  // -- fifo
  assign ff_wr_valid  = new_row_enable;
  assign ff_rd_valid  = (&pe_ready_o || data_addr_reg == 1) && !ff_empty;

  // -- -- data_o
  assign ff_node_info                                             = (ff_rd_valid) ? ff_data_o : ff_node_info_reg;
  assign { ff_row_length, ff_num_of_nodes, ff_source_node_flag }  = ff_node_info;
  assign { ff_row_length_reg, ff_num_of_nodes_reg, ff_source_node_flag_reg } = ff_node_info_reg;

  always @(posedge clk) begin
    if (!rst_n) begin
      row_counter_reg     <= 0;
      data_addr_reg       <= 0;
      node_info_addr_reg  <= 0;
      ff_node_info_reg    <= 0;
    end else begin
      row_counter_reg     <= row_counter;
      data_addr_reg       <= data_addr;
      node_info_addr_reg  <= node_info_addr;
      ff_node_info_reg    <= ff_node_info;
    end
  end
  //* =======================================
endmodule