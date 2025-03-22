// ==================================================================
// File name  : wh.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   :
// -- Calculate the multiplication of Feature & Weight: Wh = H x W
// -- Pipeline stage = 1
// -- Initialize multiple Processing Element for parallel computation
// -- Store the result in BRAM
// Author     : @Germanyy0410
// ==================================================================

module WH #(
  //* ======================= parameter ========================
  parameter DATA_WIDTH            = 8,
  parameter WH_DATA_WIDTH         = 12,
  parameter DMVM_DATA_WIDTH       = 19,
  parameter SM_DATA_WIDTH         = 108,
  parameter SM_SUM_DATA_WIDTH     = 108,
  parameter ALPHA_DATA_WIDTH      = 32,
  parameter NEW_FEATURE_WIDTH     = 32,

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
  // -- [BRAM]
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

  // -- [A]
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

  // -- [SOFTMAX]
  localparam SOFTMAX_WIDTH        = MAX_NODES * DATA_WIDTH + NUM_NODE_WIDTH,
  localparam SOFTMAX_DEPTH        = NUM_SUBGRAPHS,
  localparam SOFTMAX_ADDR_W       = $clog2(SOFTMAX_DEPTH),
  localparam WOI                  = 1,
  localparam WOF                  = ALPHA_DATA_WIDTH - WOI,
  localparam DL_DATA_WIDTH        = $clog2(WOI + WOF + 3) + 1,
  localparam DIVISOR_FF_WIDTH     = NUM_NODE_WIDTH + SM_SUM_DATA_WIDTH,

  // -- [AGGREGATOR]
  localparam AGGR_WIDTH           = MAX_NODES * ALPHA_DATA_WIDTH + NUM_NODE_WIDTH,
  localparam AGGR_DEPTH           = NUM_SUBGRAPHS,
  localparam AGGR_ADDR_W          = $clog2(AGGR_DEPTH),
  localparam AGGR_MULT_W          = WH_DATA_WIDTH + 32,

  // -- [NEW FEATURE]
  localparam NEW_FEATURE_ADDR_W   = $clog2(NEW_FEATURE_DEPTH)
  //* ==========================================================
)(
  input                                                               clk                       ,
  input                                                               rst_n                     ,

  input                                                               wh_vld_i                  ,
  output                                                              wh_rdy_o                  ,

  // -- Num Node
  input   [NUM_NODE_WIDTH-1:0]                                        num_node_bram_dout        ,
  output  [NUM_NODE_ADDR_W-1:0]                                       num_node_bram_addrb       ,

  // -- Feature
  input   [H_DATA_WIDTH-1:0]                                          h_data_bram_dout          ,
  output  [H_DATA_ADDR_W-1:0]                                         h_data_bram_addrb         ,

  // -- Weight
  input   [W_NUM_OF_COLS-1:0] [W_NUM_OF_ROWS-1:0] [DATA_WIDTH-1:0]    wgt                       ,

  // -- DMVM
  output  [WH_WIDTH-1:0]                                              wh_data_o                 ,

  output  [WH_WIDTH-1:0]                                              wh_bram_din               ,
  output                                                              wh_bram_ena               ,
  output  [WH_ADDR_W-1:0]                                             wh_bram_addra
);
  localparam IDX_WIDTH = $clog2(NUM_FEATURE_IN);

  genvar i;

  //* =================== logic declaration ====================
  logic [H_DATA_WIDTH-1:0]                          h_data_bram_dout_reg  ;

  logic                                             new_row               ;
  logic                                             new_row_reg           ;
  logic                                             new_subgraph          ;

  logic [NUM_NODE_ADDR_W-1:0]                       num_node_addr         ;
  logic [NUM_NODE_ADDR_W-1:0]                       num_node_addr_reg     ;

  logic [NUM_NODE_WIDTH-1:0]                        num_node              ;
  logic                                             src_flag              ;
  logic [NUM_NODE_WIDTH-1:0]                        num_node_cnt          ;
  logic [NUM_NODE_WIDTH-1:0]                        num_node_cnt_reg      ;

  logic                                             wh_vld_q1             ;
  logic                                             wh_vld_q2             ;

  logic [H_DATA_ADDR_W-1:0]                         h_addr                ;
  logic [H_DATA_ADDR_W-1:0]                         h_addr_reg            ;

  logic [NUM_FEATURE_OUT-1:0] [WH_DATA_WIDTH-1:0]   prod                  ;
  logic [NUM_FEATURE_OUT-1:0] [WH_DATA_WIDTH-1:0]   res                   ;
  logic [NUM_FEATURE_OUT-1:0] [WH_DATA_WIDTH-1:0]   res_reg               ;
  logic [IDX_WIDTH-1:0]                             idx                   ;
  logic [IDX_WIDTH-1:0]                             idx_reg               ;

  logic [WH_RESULT_WIDTH-1:0]                       wh_cat                ;
  logic [WH_ADDR_W-1:0]                             wh_addr               ;
  logic [WH_ADDR_W-1:0]                             wh_addr_reg           ;
  //* ==========================================================


  //* ==================== capture h_data ======================
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      h_data_bram_dout_reg <= 'b0;
    end else begin
      h_data_bram_dout_reg <= h_data_bram_dout;
    end
  end
  //* ==========================================================


  assign new_row      = (idx_reg == W_NUM_OF_ROWS - 1);
  assign new_subgraph = (num_node_cnt_reg == num_node_bram_dout - 1) && new_row;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      new_row_reg <= '0;
      wh_vld_q1   <= '0;
      wh_vld_q2   <= '0;
    end else begin
      new_row_reg <= new_row;
      wh_vld_q1   <= wh_vld_i;
      wh_vld_q2   <= wh_vld_q1;
    end
  end

  //* ==================== num_node loader =====================
  assign num_node_bram_addrb = num_node_addr_reg;
  assign num_node            = num_node_bram_dout;

  assign src_flag       = (num_node_cnt_reg == 0);
  assign num_node_addr  = (wh_vld_i && new_subgraph) ? (num_node_addr_reg + 1) : num_node_addr_reg;

  always_comb begin
    num_node_cnt = num_node_cnt_reg;

    if (new_row) begin
      if (new_subgraph) begin
        num_node_cnt = 0;
      end else begin
        num_node_cnt = num_node_cnt_reg + 1;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      num_node_addr_reg <= '0;
      num_node_cnt_reg  <= '0;
    end else begin
      num_node_addr_reg <= num_node_addr;
      num_node_cnt_reg  <= num_node_cnt;
    end
  end
  //* ==========================================================


  //* =================== main calculation =====================
  assign h_data_bram_addrb = h_addr_reg;

  assign h_addr = (wh_vld_i && h_addr_reg < {H_DATA_ADDR_W{1'b1}}) ? (h_addr_reg + 1) : h_addr_reg;
  assign idx    = (wh_vld_q2 && h_addr_reg < {H_DATA_ADDR_W{1'b1}}) ? (idx_reg + 1) : idx_reg;

  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      assign prod[i]  = $signed(h_data_bram_dout_reg) * $signed(wgt[i][idx_reg]);
      assign res[i]   = (idx_reg > 0 && wh_vld_q1) ? (prod[i] + res_reg[i]) : prod[i];
    end
  endgenerate

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      idx_reg    <= '0;
      res_reg    <= '0;
      h_addr_reg <= '0;
    end else begin
      idx_reg    <= idx;
      res_reg    <= res;
      h_addr_reg <= h_addr;
    end
  end
  //* ==========================================================


  //* ======================= WH output ========================
  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      assign wh_cat[WH_DATA_WIDTH*(i+1)-1-:WH_DATA_WIDTH] = res_reg[W_NUM_OF_COLS-1-i];
    end
  endgenerate

  // Output
  assign wh_data_o  = { wh_cat, num_node, src_flag };
  assign wh_rdy_o   = new_row_reg;

  // BRAM
  assign wh_bram_din    = { wh_cat, num_node, src_flag };
  assign wh_bram_ena    = new_row_reg;
  assign wh_bram_addra  = wh_addr_reg;

  assign wh_addr = (new_row_reg) ? (wh_addr_reg + 1) : wh_addr_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wh_addr_reg <= '0;
    end else begin
      wh_addr_reg <= wh_addr;
    end
  end
  //* ==========================================================
endmodule