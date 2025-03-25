module subgraph_handler #(
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

  // -- [Subgraph]
  localparam SUBGRAPH_IDX_DEPTH   = TOTAL_NODES,
  localparam SUBGRAPH_IDX_WIDTH   = $clog2(TOTAL_NODES) + 2,
  localparam SUBGRAPH_IDX_ADDR_W  = $clog2(SUBGRAPH_IDX_DEPTH),

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
  input                                                   clk                 ,
  input                                                   rst_n               ,

  // -- New Feature
  input   [NUM_FEATURE_OUT-1:0] [NEW_FEATURE_WIDTH-1:0]   new_feat            ,
  input                                                   new_feat_vld        ,
  output                                                  new_feat_rdy        ,

  // -- Subgraph Index
  output  [SUBGRAPH_IDX_ADDR_W-1:0]                       subgraph_bram_addrb ,
  input   [SUBGRAPH_IDX_WIDTH-1:0]                        subgraph_bram_dout  ,

  // -- H Data
  output  [H_DATA_ADDR_W-1:0]                             h_data_bram_addra   ,
  output  [H_DATA_WIDTH-1:0]                              h_data_bram_din     ,
  output logic                                            h_data_bram_ena     ,

  output logic                                            gat_ready
);

  localparam CNT_DATA_WIDTH           = $clog2(NUM_FEATURE_OUT);
  localparam SUBGRAPH_IDX_DATA_WIDTH  = $clog2(TOTAL_NODES);

  //* =================== logic declaration ====================
  logic                                                 h_data_rdy            ;
  logic                                                 h_data_rdy_reg        ;

  logic                                                 start_feat            ;
  logic                                                 start_feat_reg        ;
  logic                                                 start_feat_reg_q1     ;

  logic                                                 new_position          ;
  logic                                                 push_feat_en          ;
  logic                                                 push_feat_en_reg      ;

  logic [NUM_FEATURE_OUT-1:0] [NEW_FEATURE_WIDTH-1:0]   feat                  ;
  logic [NUM_FEATURE_OUT-1:0] [NEW_FEATURE_WIDTH-1:0]   feat_reg              ;

  // -- FIFO
  logic [NUM_FEATURE_OUT-1:0] [NEW_FEATURE_WIDTH-1:0]   feat_ff_din           ;
  logic [NUM_FEATURE_OUT-1:0] [NEW_FEATURE_WIDTH-1:0]   feat_ff_dout          ;
  logic                                                 feat_ff_wr_vld        ;
  logic                                                 feat_ff_rd_vld        ;
  logic                                                 feat_ff_empty         ;
  logic                                                 feat_ff_full          ;

  // -- Counter
  logic [CNT_DATA_WIDTH-1:0]                            cnt                   ;
  logic [CNT_DATA_WIDTH-1:0]                            cnt_reg               ;

  // -- Subgraph index
  logic [SUBGRAPH_IDX_WIDTH-1:0]                        subgraph_data         ;
  logic [SUBGRAPH_IDX_WIDTH-1:0]                        subgraph_data_reg     ;
  logic                                                 sog                   ;
  logic                                                 sog_reg               ;
  logic [SUBGRAPH_IDX_DATA_WIDTH-1:0]                   subgraph_idx          ;
  logic [SUBGRAPH_IDX_DATA_WIDTH-1:0]                   subgraph_idx_reg      ;
  logic                                                 eog                   ;
  logic                                                 eog_reg               ;
  logic [SUBGRAPH_IDX_ADDR_W-1:0]                       subgraph_addr         ;
  logic [SUBGRAPH_IDX_ADDR_W-1:0]                       subgraph_addr_reg     ;

  // -- H Data
  logic [H_DATA_ADDR_W-1:0]                             h_data_addr           ;
  logic [H_DATA_ADDR_W-1:0]                             h_data_addr_reg       ;
  logic [CNT_DATA_WIDTH-1:0]                            h_data_addr_cnt       ;
  logic [CNT_DATA_WIDTH-1:0]                            h_data_addr_cnt_reg   ;
  logic                                                 h_data_bram_ena_reg   ;
  //* ==========================================================

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

  assign start_feat = (new_feat_vld) ? 1'b0 : start_feat_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      start_feat_reg    <= 'b1;
      start_feat_reg_q1 <= 'b1;
    end else begin
      start_feat_reg    <= start_feat;
      start_feat_reg_q1 <= start_feat_reg;
    end
  end

  //* ====================== push into FF ======================
  assign feat_ff_wr_vld = new_feat_vld;
  assign feat_ff_din    = new_feat;
  //* ==========================================================


  //* ====================== pop from FF =======================
  assign feat_ff_rd_vld = ((cnt_reg == NUM_FEATURE_OUT - 1) && (!feat_ff_empty) && eog_reg) || start_feat_reg_q1;
  assign feat = feat_ff_rd_vld ? feat_ff_dout : feat_reg;

  assign push_feat_en = ((eog && (!feat_ff_empty)) || (!start_feat_reg && start_feat_reg_q1)) ? 1'b1 : push_feat_en_reg;
  assign cnt = (push_feat_en && !start_feat_reg_q1) ? (cnt_reg + 1) : cnt_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt_reg           <= 'b0;
      feat_reg          <= 'b0;
      push_feat_en_reg  <= 'b0;
    end else begin
      cnt_reg           <= cnt;
      feat_reg          <= feat;
      push_feat_en_reg  <= push_feat_en;
    end
  end
  //* ==========================================================


  //* ==================== Subgraph Index ======================
  assign new_position = (cnt_reg == NUM_FEATURE_OUT - 2) || (new_feat_vld && start_feat_reg);

  // -- Read from BRAM
  assign subgraph_bram_addrb        = subgraph_addr_reg;
  assign subgraph_data              = new_position ? subgraph_bram_dout : subgraph_data_reg;
  assign { sog, subgraph_idx, eog } = subgraph_data_reg;

  assign subgraph_addr = (new_position && subgraph_addr_reg < TOTAL_NODES - 1) ? (subgraph_addr_reg + 1) : subgraph_addr_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      subgraph_addr_reg <= 'b0;
      subgraph_data_reg <= 'b0;
    end else begin
      subgraph_addr_reg <= subgraph_addr;
      subgraph_data_reg <= subgraph_data;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sog_reg <= 'b0;
      eog_reg <= 'b0;
      subgraph_idx_reg <= 'b0;
    end else begin
      sog_reg <= sog;
      eog_reg <= eog;
      subgraph_idx_reg <= subgraph_idx;
    end
  end
  //* ==========================================================


  //* ==================== Push to H DATA ======================
  // -- Write to BRAM
  assign h_data_bram_addra = h_data_addr_reg;
  assign h_data_bram_din   = feat_reg[cnt_reg];

  always_comb begin
    h_data_bram_ena = h_data_bram_ena_reg;
    if (subgraph_addr_reg < TOTAL_NODES - 1) begin
      h_data_bram_ena = push_feat_en_reg;
    end else begin
      if (cnt_reg == NUM_FEATURE_OUT - 1) begin
        h_data_bram_ena = 1'b0;
      end
    end
  end

  assign h_data_addr = (!start_feat && push_feat_en) ? ((subgraph_idx * NUM_FEATURE_OUT) + h_data_addr_cnt_reg) : h_data_addr_reg;

  always_comb begin
    h_data_addr_cnt = h_data_addr_cnt_reg;
    if (!start_feat && push_feat_en) begin
      if (new_position) begin
        h_data_addr_cnt = 0;
      end else begin
        h_data_addr_cnt = h_data_addr_cnt_reg + 1;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      h_data_bram_ena_reg <= 'b0;
      h_data_addr_reg     <= 'b0;
      h_data_addr_cnt_reg <= 'b0;
    end else begin
      h_data_bram_ena_reg <= h_data_bram_ena;
      h_data_addr_reg     <= h_data_addr;
      h_data_addr_cnt_reg <= h_data_addr_cnt;
    end
  end
  //* ==========================================================


  //* ======================= gat ready ========================
  assign gat_ready = h_data_rdy_reg;
  assign h_data_rdy = ((cnt_reg == NUM_FEATURE_OUT - 1) && (subgraph_addr_reg == TOTAL_NODES - 1)) ? 1'b1 : h_data_rdy_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      h_data_rdy_reg <= 'b0;
    end else begin
      h_data_rdy_reg <= h_data_rdy;
    end
  end
  //* ==========================================================

endmodule