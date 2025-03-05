// ==================================================================
// File name  : SPMM.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   :
// -- Calculate the multiplication of Feature & Weight: Wh = H x W
// -- Pipeline stage = 1
// -- Initialize multiple Processing Element for parallel computation
// -- Store the result in BRAM
// Author     : @Germanyy0410
// ==================================================================

module SPMM #(
  //* ======================= parameter ========================
  parameter DATA_WIDTH            = 8,
  parameter WH_DATA_WIDTH         = 12,
  parameter DMVM_DATA_WIDTH       = 19,
  parameter SM_DATA_WIDTH         = 108,
  parameter SM_SUM_DATA_WIDTH     = 108,
  parameter ALPHA_DATA_WIDTH      = 32,
  parameter NEW_FEATURE_WIDTH     = WH_DATA_WIDTH + 32,

  parameter H_NUM_SPARSE_DATA     = 242101,
  parameter TOTAL_NODES           = 13264,
  parameter NUM_FEATURE_IN        = 1433,
  parameter NUM_FEATURE_OUT       = 16,
  parameter NUM_SUBGRAPHS         = 2708,
  parameter MAX_NODES             = 168,

  parameter COEF_DEPTH            = 500,
  parameter ALPHA_DEPTH           = 500,
  parameter DIVIDEND_DEPTH        = 500,
  parameter DIVISOR_DEPTH         = 500,
  //* ==========================================================

  //* ======================= localparams ======================
  // -- [brams] Depth
  localparam H_DATA_DEPTH         = H_NUM_SPARSE_DATA,
  localparam NODE_INFO_DEPTH      = TOTAL_NODES,
  localparam WEIGHT_DEPTH         = NUM_FEATURE_OUT * NUM_FEATURE_IN + NUM_FEATURE_OUT * 2,
  localparam WH_DEPTH             = TOTAL_NODES,
  localparam A_DEPTH              = NUM_FEATURE_OUT * 2,
  localparam NUM_NODES_DEPTH      = NUM_SUBGRAPHS,
  localparam NEW_FEATURE_DEPTH    = NUM_SUBGRAPHS * NUM_FEATURE_OUT,

  // -- [H]
  localparam H_NUM_OF_ROWS        = TOTAL_NODES,
  localparam H_NUM_OF_COLS        = NUM_FEATURE_IN,

  // -- [H] data
  localparam COL_IDX_WIDTH        = $clog2(H_NUM_OF_COLS),
  localparam H_DATA_WIDTH         = DATA_WIDTH + COL_IDX_WIDTH,
  localparam H_DATA_ADDR_W        = $clog2(H_DATA_DEPTH),

  // -- [H] node_info
  localparam ROW_LEN_WIDTH        = $clog2(H_NUM_OF_COLS),
  localparam NUM_NODE_WIDTH       = $clog2(MAX_NODES),
  localparam FLAG_WIDTH           = 1,
  localparam NODE_INFO_WIDTH      = ROW_LEN_WIDTH + NUM_NODE_WIDTH + FLAG_WIDTH,
  localparam NODE_INFO_ADDR_W     = $clog2(NODE_INFO_DEPTH),

  // -- [W]
  localparam W_NUM_OF_ROWS        = NUM_FEATURE_IN,
  localparam W_NUM_OF_COLS        = NUM_FEATURE_OUT,
  localparam W_ROW_WIDTH          = $clog2(W_NUM_OF_ROWS),
  localparam W_COL_WIDTH          = $clog2(W_NUM_OF_COLS),
  localparam WEIGHT_ADDR_W        = $clog2(WEIGHT_DEPTH),
  localparam MULT_WEIGHT_ADDR_W   = $clog2(W_NUM_OF_ROWS),

  // -- [WH]
  localparam DOT_PRODUCT_SIZE     = H_NUM_OF_COLS,
  localparam WH_ADDR_W            = $clog2(WH_DEPTH),
  localparam WH_RESULT_WIDTH      = WH_DATA_WIDTH * W_NUM_OF_COLS,
  localparam WH_WIDTH             = WH_DATA_WIDTH * W_NUM_OF_COLS + NUM_NODE_WIDTH + FLAG_WIDTH,

  // -- [a]
  localparam A_ADDR_W             = $clog2(A_DEPTH),
  localparam HALF_A_SIZE          = A_DEPTH / 2,
  localparam A_INDEX_WIDTH        = $clog2(A_DEPTH),

  // -- [DMVM]
  localparam DMVM_PRODUCT_WIDTH   = $clog2(HALF_A_SIZE),
  localparam COEF_W               = DATA_WIDTH * MAX_NODES,
  localparam ALPHA_W              = ALPHA_DATA_WIDTH * MAX_NODES,
  localparam NUM_NODE_ADDR_W      = $clog2(NUM_NODES_DEPTH),
  localparam NUM_STAGES           = $clog2(NUM_FEATURE_OUT) + 1,
  localparam COEF_DELAY_LENGTH    = NUM_STAGES + 1,

  // -- [Softmax]
  localparam SOFTMAX_WIDTH        = MAX_NODES * DATA_WIDTH + NUM_NODE_WIDTH,
  localparam SOFTMAX_DEPTH        = NUM_SUBGRAPHS,
  localparam SOFTMAX_ADDR_W       = $clog2(SOFTMAX_DEPTH),
  localparam WOI                  = 1,
  localparam WOF                  = ALPHA_DATA_WIDTH - WOI,
  localparam DL_DATA_WIDTH        = $clog2(WOI + WOF + 3) + 1,
  localparam DIVISOR_FF_WIDTH     = NUM_NODE_WIDTH + SM_SUM_DATA_WIDTH,

  // -- [Aggregator]
  localparam AGGR_WIDTH           = MAX_NODES * ALPHA_DATA_WIDTH + NUM_NODE_WIDTH,
  localparam AGGR_DEPTH           = NUM_SUBGRAPHS,
  localparam AGGR_ADDR_W          = $clog2(AGGR_DEPTH),
  localparam AGGR_MULT_W          = WH_DATA_WIDTH + 32,

  // -- [New Feature]
  localparam NEW_FEATURE_ADDR_W   = $clog2(NEW_FEATURE_DEPTH)
  //* ==========================================================
)(
  input                                                 clk                       ,
  input                                                 rst_n                     ,

  input                                                 spmm_vld_i                ,
  output                                                spmm_rdy_o                ,

  // -- h_data BRAM
  input   [H_DATA_WIDTH-1:0]                            h_data_bram_dout          ,
  output  [H_DATA_ADDR_W-1:0]                           h_data_bram_addrb         ,

  // -- h_node_info BRAM
  input   [NODE_INFO_WIDTH-1:0]                         h_node_info_bram_dout     ,
  input   [NODE_INFO_WIDTH-1:0]                         h_node_info_bram_dout_nxt ,
  output  [NODE_INFO_ADDR_W-1:0]                        h_node_info_bram_addrb    ,

  // -- Weight
  input   [W_NUM_OF_COLS-1:0] [DATA_WIDTH-1:0]          mult_wgt_dout             ,
  output  [W_NUM_OF_COLS-1:0] [MULT_WEIGHT_ADDR_W-1:0]  mult_wgt_addrb            ,

  // -- DMVM
  output  [WH_WIDTH-1:0]                                wh_data_o                 ,

  // -- num_node
  output  [NUM_NODE_WIDTH-1:0]                          num_node_bram_din         ,
  output                                                num_node_bram_ena         ,
  output  [NUM_NODE_ADDR_W-1:0]                         num_node_bram_addra       ,

  output  [WH_WIDTH-1:0]                                wh_bram_din               ,
  output                                                wh_bram_ena               ,
  output  [WH_ADDR_W-1:0]                               wh_bram_addra
);

  //* =================== logic declaration ====================
  logic                                           new_row_en                ;
  logic [ROW_LEN_WIDTH-1:0]                       row_cnt                   ;
  logic [ROW_LEN_WIDTH-1:0]                       row_cnt_reg               ;
  logic                                           sparse_row                ;
  logic                                           sparse_row_nxt            ;
  logic                                           dense_row                 ;
  logic                                           dense_row_nxt             ;


  // -- Address for H_bram
  logic [H_DATA_ADDR_W-1:0]                       data_addr                 ;
  logic [H_DATA_ADDR_W-1:0]                       data_addr_reg             ;
  logic [NODE_INFO_ADDR_W-1:0]                    node_info_addr            ;
  logic [NODE_INFO_ADDR_W-1:0]                    node_info_addr_reg        ;

  // -- current data from bram
  logic [COL_IDX_WIDTH-1:0]                       col_idx                   ;
  logic [DATA_WIDTH-1:0]                          val                       ;
  logic [ROW_LEN_WIDTH-1:0]                       row_len                   ;
  logic                                           src_flag                  ;
  logic [NUM_NODE_WIDTH-1:0]                      num_node                  ;

  // -- next data from bram
  logic [ROW_LEN_WIDTH-1:0]                       row_len_nxt               ;
  logic                                           src_flag_nxt              ;
  logic [NUM_NODE_WIDTH-1:0]                      num_node_nxt              ;

  // -- ff
  logic [NODE_INFO_WIDTH-1:0]                     ff_data_i                 ;
  logic [NODE_INFO_WIDTH-1:0]                     ff_data_o                 ;
  logic                                           ff_empty                  ;
  logic                                           ff_full                   ;
  logic                                           ff_wr_vld                 ;
  logic                                           ff_rd_vld                 ;
  logic [NODE_INFO_WIDTH-1:0]                     ff_node_info              ;
  logic [ROW_LEN_WIDTH-1:0]                       ff_row_len                ;
  logic                                           ff_src_flag               ;
  logic [NUM_NODE_WIDTH-1:0]                      ff_num_node               ;

  logic [NODE_INFO_WIDTH-1:0]                     ff_node_info_reg          ;
  logic [ROW_LEN_WIDTH-1:0]                       ff_row_len_reg            ;
  logic                                           ff_src_flag_reg           ;
  logic [NUM_NODE_WIDTH-1:0]                      ff_num_node_reg           ;

  // -- SP-PE valid signal
  logic                                           pe_vld                    ;
  logic                                           pe_vld_reg                ;
  logic                                           spmm_vld_q1               ;
  logic [W_NUM_OF_COLS-1:0]                       pe_rdy_o                  ;

  // -- SP-PE results
  logic [WH_RESULT_WIDTH-1:0]                     sppe_cat                  ;
  logic [W_NUM_OF_COLS-1:0] [WH_DATA_WIDTH-1:0]   sppe                      ;
  logic [WH_WIDTH-1:0]                            wh_data_i                 ;
  logic [WH_ADDR_W-1:0]                           wh_addr                   ;
  logic [WH_ADDR_W-1:0]                           wh_addr_reg               ;

  // -- output
  logic [WH_WIDTH-1:0]                            wh_data                   ;
  logic [WH_WIDTH-1:0]                            wh_data_reg               ;

  logic [NUM_NODE_WIDTH-1:0]                      num_node_reg              ;
  //* ==========================================================


  genvar i, k;
  integer x, y;


  //* =================== output assignment ====================
  assign spmm_rdy_o = &pe_rdy_o;
  assign wh_data_o  = wh_data;
  //* ==========================================================


  //* ===================== instantiation ======================
  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      SP_PE #(
        .DATA_WIDTH         (DATA_WIDTH         ),
        .WH_DATA_WIDTH      (WH_DATA_WIDTH      ),
        .DMVM_DATA_WIDTH    (DMVM_DATA_WIDTH    ),
        .SM_DATA_WIDTH      (SM_DATA_WIDTH      ),
        .SM_SUM_DATA_WIDTH  (SM_SUM_DATA_WIDTH  ),
        .ALPHA_DATA_WIDTH   (ALPHA_DATA_WIDTH   ),
        .NEW_FEATURE_WIDTH  (NEW_FEATURE_WIDTH  ),

        .H_NUM_SPARSE_DATA  (H_NUM_SPARSE_DATA  ),
        .TOTAL_NODES        (TOTAL_NODES        ),
        .NUM_FEATURE_IN     (NUM_FEATURE_IN     ),
        .NUM_FEATURE_OUT    (NUM_FEATURE_OUT    ),
        .NUM_SUBGRAPHS      (NUM_SUBGRAPHS      ),
        .MAX_NODES          (MAX_NODES          ),

        .COEF_DEPTH         (COEF_DEPTH         ),
        .ALPHA_DEPTH        (ALPHA_DEPTH        ),
        .DIVIDEND_DEPTH     (DIVIDEND_DEPTH     ),
        .DIVISOR_DEPTH      (DIVISOR_DEPTH      )
      ) u_SP_PE (
        .clk          (clk                      ),
        .rst_n        (rst_n                    ),

        .spmm_vld_i   (spmm_vld_q1 && h_data_bram_addrb >= 1  ),
        .pe_vld_i     (pe_vld                   ),
        .pe_rdy_o     (pe_rdy_o[i]              ),

        .col_idx_i    (col_idx                  ),
        .val_i        (val                      ),
        .row_len_i    (ff_row_len               ),

        .wgt_addrb    (mult_wgt_addrb[i]        ),
        .wgt_dout     (mult_wgt_dout[i]         ),
        .res_o        (sppe[i]                  )
      );
    end
  endgenerate

  FIFO #(
    .DATA_WIDTH (NODE_INFO_WIDTH  ),
    .FIFO_DEPTH (100              )
  ) node_info_fifo (
    .clk        (clk              ),
    .rst_n      (rst_n            ),

    .din        (ff_data_i        ),
    .dout       (ff_data_o        ),

    .wr_vld     (ff_wr_vld        ),
    .rd_vld     (ff_rd_vld        ),

    .empty      (ff_empty         ),
    .full       (ff_full          )
  );
  //* ==========================================================


  //* ================ assign SP-PE to WH bram =================
  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      assign sppe_cat[WH_DATA_WIDTH*(i+1)-1-:WH_DATA_WIDTH] = sppe[W_NUM_OF_COLS-1-i];
    end
  endgenerate

  // -- output from SP-PE
  assign wh_data_i  = { sppe_cat, ff_num_node_reg, ff_src_flag_reg };

  // -- WH bram
  assign wh_bram_din    = { sppe_cat, ff_num_node_reg, ff_src_flag_reg };
  assign wh_bram_ena    = (&pe_rdy_o);
  assign wh_bram_addra  = wh_addr_reg;

  // -- WH bram addr
  assign wh_addr = (&pe_rdy_o) ? (wh_addr_reg + 1) : wh_addr_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wh_addr_reg <= 0;
    end else begin
      wh_addr_reg <= wh_addr;
    end
  end
  //* ==========================================================


  //* ======================= WH output ========================
  assign wh_data = (&pe_rdy_o) ? { sppe_cat, ff_num_node_reg, ff_src_flag_reg } : wh_data_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wh_data_reg <= 0;
    end else begin
      wh_data_reg <= wh_data;
    end
  end
  //* ==========================================================


  //* ==================== pe_vld for SP-PE ====================
  always_comb begin
    pe_vld = pe_vld_reg;

    if (spmm_vld_q1) begin
      if (data_addr_reg == 1) begin
        pe_vld = 1'b1;
      end else begin
        pe_vld = &pe_rdy_o;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pe_vld_reg <= 1'b0;
    end else begin
      pe_vld_reg <= pe_vld;
    end
  end

  always_ff @(posedge clk) begin
    spmm_vld_q1 <= spmm_vld_i;
  end
  //* ==========================================================


  //* ================== Pop data into SP-PE ===================
  assign sparse_row     = ~|row_len[ROW_LEN_WIDTH-1:1];
  assign dense_row      =  |row_len[ROW_LEN_WIDTH-1:1];
  assign sparse_row_nxt = ~|row_len_nxt[ROW_LEN_WIDTH-1:1];
  assign dense_row_nxt  =  |row_len_nxt[ROW_LEN_WIDTH-1:1];

  assign new_row_en = ((row_cnt_reg == 1 && dense_row) || sparse_row) && spmm_vld_q1;

  assign row_cnt    = (((row_cnt_reg == row_len - 1 && dense_row) || (row_cnt_reg == 0 && sparse_row_nxt)) && spmm_vld_q1)
                          || (row_cnt_reg == 0 && sparse_row && (spmm_vld_i ^ spmm_vld_q1))
                          ? 0
                          : ((((row_cnt_reg < row_len - 1) && (dense_row)) || (sparse_row && dense_row_nxt)) && spmm_vld_i)
                            ? (row_cnt_reg + 1)
                            : row_cnt_reg;

  assign data_addr = (spmm_vld_q1) ? (data_addr_reg + 1) : data_addr_reg;

  assign node_info_addr = ((((row_cnt_reg == row_len - 1) && dense_row) || (sparse_row_nxt && row_cnt_reg == 0)) && spmm_vld_q1)
                          ? (node_info_addr_reg + 1)
                          : node_info_addr_reg;

  // -- col_idx & val
  assign { col_idx, val }   = h_data_bram_dout;
  assign h_data_bram_addrb  = data_addr_reg;

  // -- node_info
  assign { row_len, num_node, src_flag }  = h_node_info_bram_dout;
  assign h_node_info_bram_addrb           = node_info_addr_reg;

  // -- node_info_next
  assign { row_len_nxt, num_node_nxt, src_flag_nxt } = h_node_info_bram_dout_nxt;

  // -- FF
  assign ff_data_i    = h_node_info_bram_dout;
  assign ff_wr_vld    = new_row_en;

  assign ff_rd_vld    = (&pe_rdy_o || data_addr_reg == 1) && !ff_empty;
  assign ff_node_info = (ff_rd_vld) ? ff_data_o : ff_node_info_reg;

  // -- node_info from FF
  assign { ff_row_len, ff_num_node, ff_src_flag } = ff_node_info;
  assign { ff_row_len_reg, ff_num_node_reg, ff_src_flag_reg } = ff_node_info_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      row_cnt_reg         <= 'b0;
      num_node_reg        <= 'b0;
      data_addr_reg       <= 'b0;
      ff_node_info_reg    <= 'b0;
      node_info_addr_reg  <= 'b0;
    end else begin
      row_cnt_reg         <= row_cnt;
      num_node_reg        <= num_node;
      data_addr_reg       <= data_addr;
      ff_node_info_reg    <= ff_node_info;
      node_info_addr_reg  <= node_info_addr;
    end
  end
  //* ============================================================


  //* ====================== num_node bram =======================
  num_node_controller #(
    .DATA_WIDTH         (DATA_WIDTH         ),
    .WH_DATA_WIDTH      (WH_DATA_WIDTH      ),
    .DMVM_DATA_WIDTH    (DMVM_DATA_WIDTH    ),
    .SM_DATA_WIDTH      (SM_DATA_WIDTH      ),
    .SM_SUM_DATA_WIDTH  (SM_SUM_DATA_WIDTH  ),
    .ALPHA_DATA_WIDTH   (ALPHA_DATA_WIDTH   ),
    .NEW_FEATURE_WIDTH  (NEW_FEATURE_WIDTH  ),

    .H_NUM_SPARSE_DATA  (H_NUM_SPARSE_DATA  ),
    .TOTAL_NODES        (TOTAL_NODES        ),
    .NUM_FEATURE_IN     (NUM_FEATURE_IN     ),
    .NUM_FEATURE_OUT    (NUM_FEATURE_OUT    ),
    .NUM_SUBGRAPHS      (NUM_SUBGRAPHS      ),
    .MAX_NODES          (MAX_NODES          ),

    .COEF_DEPTH         (COEF_DEPTH         ),
    .ALPHA_DEPTH        (ALPHA_DEPTH        ),
    .DIVIDEND_DEPTH     (DIVIDEND_DEPTH     ),
    .DIVISOR_DEPTH      (DIVISOR_DEPTH      )
  ) u_num_node_controller (
    .clk                  (clk                      ),
    .rst_n                (rst_n                    ),

    .spmm_vld_i           (spmm_vld_i               ),

    .src_flag             (src_flag                 ),
    .num_node             (num_node                 ),

    .num_node_bram_din    (num_node_bram_din        ),
    .num_node_bram_ena    (num_node_bram_ena        ),
    .num_node_bram_addra  (num_node_bram_addra      )
  );
  //* ================================================================
endmodule












