// ==================================================================
// File name  : feature_controller.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   :
// -- Buffer each Feature vector in FIFO
// -- Fetch and store each value in a Feature vector in BRAM
// Author     : @Germanyy0410
// ==================================================================

module feature_controller #(
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
  localparam WH_DEPTH             = 128,
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
  input                                                 clk                 ,
  input                                                 rst_n               ,

  input [NUM_FEATURE_OUT-1:0] [NEW_FEATURE_WIDTH-1:0]   new_feat            ,
  input                                                 new_feat_vld        ,
  output logic                                          new_feat_rdy        ,

  // -- new features
  output logic [NEW_FEATURE_ADDR_W-1:0]                 feat_bram_addra     ,
  output logic [NEW_FEATURE_WIDTH-1:0]                  feat_bram_din       ,
  output logic                                          feat_bram_ena       ,

  output logic                                          gat_ready
);

  localparam CNT_DATA_WIDTH = $clog2(NUM_FEATURE_OUT);

  logic [NUM_FEATURE_OUT-1:0] [NEW_FEATURE_WIDTH-1:0]   feat_ff_din         ;
  logic [NUM_FEATURE_OUT-1:0] [NEW_FEATURE_WIDTH-1:0]   feat_ff_dout        ;
  logic                                                 feat_ff_wr_vld      ;
  logic                                                 feat_ff_rd_vld      ;
  logic                                                 feat_ff_empty       ;
  logic                                                 feat_ff_full        ;

  logic [NUM_FEATURE_OUT-1:0] [NEW_FEATURE_WIDTH-1:0]   feat                ;
  logic [NUM_FEATURE_OUT-1:0] [NEW_FEATURE_WIDTH-1:0]   feat_reg            ;
  logic [CNT_DATA_WIDTH-1:0]                            cnt                 ;
  logic [CNT_DATA_WIDTH-1:0]                            cnt_reg             ;

  logic [NEW_FEATURE_ADDR_W-1:0]                        feat_addr           ;
  logic [NEW_FEATURE_ADDR_W-1:0]                        feat_addr_reg       ;

  logic                                                 push_feat_ena       ;

  FIFO #(
    .DATA_WIDTH (NUM_FEATURE_OUT*NEW_FEATURE_WIDTH  ),
    .FIFO_DEPTH (NUM_FEATURE_OUT                    )
  ) u_new_feat_fifo (
    .clk        (clk                    ),
    .rst_n      (rst_n                  ),
    .din        (feat_ff_din            ),
    .dout       (feat_ff_dout           ),
    .wr_vld     (feat_ff_wr_vld         ),
    .rd_vld     (feat_ff_rd_vld         ),
    .empty      (feat_ff_empty          ),
    .full       (feat_ff_full           )
  );

  //* =================== push into ff ===================
  assign feat_ff_wr_vld = new_feat_vld;
  assign feat_ff_din    = new_feat;
  //* ====================================================

  //* =================== pop from ff ====================
  assign feat_ff_rd_vld = (cnt_reg == 0) && (!feat_ff_empty);
  assign feat           = feat_ff_rd_vld ? feat_ff_dout : feat_reg;
  //* ====================================================

  assign push_feat_ena  = feat_ff_rd_vld || ((cnt_reg > 0) && (cnt_reg < NUM_FEATURE_OUT));
  assign feat_addr      = push_feat_ena ? (feat_addr_reg + 1) : feat_addr_reg;

  always_comb begin
    cnt = cnt_reg;
    if (push_feat_ena) begin
      if (cnt_reg == NUM_FEATURE_OUT - 1) begin
        cnt = 'b0;
      end else begin
        cnt = cnt_reg + 1;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      feat_reg          <= 'b0;
      cnt_reg           <= 'b0;
      feat_addr_reg     <= 'b0;
    end else begin
      feat_reg          <= feat;
      cnt_reg           <= cnt;
      feat_addr_reg     <= feat_addr;
    end
  end

  //* ================== push into bram ==================
  // assign feat_bram_din   = feat[NUM_FEATURE_OUT - 1 - cnt_reg];
  // assign feat_bram_addra = feat_addr_reg;
  // assign feat_bram_ena   = push_feat_ena;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      feat_bram_din   <= 'b0;
      feat_bram_addra <= 'b0;
      feat_bram_ena   <= 'b0;
    end else begin
      feat_bram_din   <= feat[NUM_FEATURE_OUT - 1 - cnt_reg];
      feat_bram_addra <= feat_addr_reg;
      feat_bram_ena   <= push_feat_ena;
    end
  end
  //* ====================================================

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      new_feat_rdy <= 'b0;
    end else begin
      new_feat_rdy <= (cnt_reg == NUM_FEATURE_OUT - 1);
    end
  end

  //* ================== complete conv ===================
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      gat_ready <= '0;
    end else begin
      gat_ready <= (feat_bram_addra >= (NUM_SUBGRAPHS * NUM_FEATURE_OUT - 1));
    end
  end
  //* ====================================================
endmodule