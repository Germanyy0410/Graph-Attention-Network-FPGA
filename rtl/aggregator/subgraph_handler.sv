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
  parameter NUM_FEATURE_FINAL     = 7,
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
  localparam WEIGHT_DEPTH         = NUM_FEATURE_OUT * (NUM_FEATURE_IN + 2) + NUM_FEATURE_FINAL * (NUM_FEATURE_OUT + 2),
  localparam WH_DEPTH             = 128,
  localparam A_DEPTH              = NUM_FEATURE_OUT * 2,
  localparam NUM_NODES_DEPTH      = NUM_SUBGRAPHS,
  localparam NEW_FEATURE_DEPTH    = NUM_SUBGRAPHS * NUM_FEATURE_OUT,

  // -- [SUBGRAPH]
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
  localparam MULT_WEIGHT_ADDR_W   = $clog2(NUM_FEATURE_IN),

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

  input                                                   subgraph_vld_i      ,
  output                                                  subgraph_rdy_o      ,

  // -- New Feature
  output  [NEW_FEATURE_ADDR_W-1:0]                        feat_bram_addrb     ,
  input   [NEW_FEATURE_WIDTH-1:0]                         feat_bram_dout      ,

  // -- Subgraph Index
  output  [SUBGRAPH_IDX_ADDR_W-1:0]                       subgraph_bram_addrb ,
  input   [SUBGRAPH_IDX_WIDTH-1:0]                        subgraph_bram_dout  ,

  // -- H Data
  output  [H_DATA_ADDR_W-1:0]                             h_data_bram_addra   ,
  output  [H_DATA_WIDTH-1:0]                              h_data_bram_din     ,
  output logic                                            h_data_bram_ena     ,
  output logic                                            h_data_bram_wea
);

  localparam CNT_DATA_WIDTH           = $clog2(NUM_FEATURE_OUT);
  localparam SUBGRAPH_IDX_DATA_WIDTH  = $clog2(TOTAL_NODES);

  //* =================== logic declaration ====================
  logic                                                 subgraph_rdy          ;
  logic [31:0]                                          subgraph_rdy_reg      ;

  logic [31:0]                                          h_data_rdy            ;
  logic [31:0]                                          h_data_rdy_reg        ;

  logic                                                 subgraph_vld_reg      ;

  logic                                                 new_feat_request      ;
  logic                                                 new_feat_request_reg  ;
  logic                                                 new_feat_response     ;
  logic                                                 new_feat_response_reg ;

  // -- BRAM
  logic [CNT_DATA_WIDTH-1:0]                            feat_bram_idx         ;
  logic [CNT_DATA_WIDTH-1:0]                            feat_bram_idx_reg     ;
  logic [NEW_FEATURE_ADDR_W-1:0]                        feat_bram_addr        ;
  logic [NEW_FEATURE_ADDR_W-1:0]                        feat_bram_addr_reg    ;

  logic                                                 new_position          ;
  logic                                                 new_position_reg      ;
  logic                                                 new_position_reg_q1   ;
  logic                                                 start_handle          ;
  logic                                                 start_handle_reg      ;

  logic [NUM_FEATURE_OUT-1:0] [NEW_FEATURE_WIDTH-1:0]   feat                  ;
  logic [NUM_FEATURE_OUT-1:0] [NEW_FEATURE_WIDTH-1:0]   feat_reg              ;

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

  genvar i;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      subgraph_vld_reg <= 'b0;
    end else begin
      subgraph_vld_reg <= subgraph_vld_i;
    end
  end

  //* ================== Read Feature Status ===================
  // -- Request
  always_comb begin
    new_feat_request = new_feat_request_reg;
    if (feat_bram_idx_reg == NUM_FEATURE_OUT - 1) begin
      new_feat_request = 1'b0;
    end else if (eog) begin
      new_feat_request = 1'b1;
    end
  end

  // -- Response
  always_comb begin
    new_feat_response = new_feat_response_reg;
    // TODO
    if (eog && feat_bram_idx_reg < NUM_FEATURE_OUT - 1) begin
      new_feat_response = 1'b0;
    end else if (feat_bram_idx_reg == NUM_FEATURE_OUT - 1) begin
      new_feat_response = 1'b1;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      new_feat_request_reg  <= 'b1;
      new_feat_response_reg <= 'b0;
    end else begin
      new_feat_request_reg  <= new_feat_request;
      new_feat_response_reg <= new_feat_response;
    end
  end
  //* ==========================================================


  //* ================ Read Feature from BRAM ==================
  assign feat_bram_addrb = feat_bram_addr_reg;
  // assign feat[feat_bram_idx_reg]  = (subgraph_vld_i && new_feat_request_reg) ? feat_bram_dout : feat_reg[feat_bram_idx_reg];

  generate
    for (i = 0; i < NUM_FEATURE_OUT; i = i + 1) begin
      assign feat[i] = (i == feat_bram_idx_reg && subgraph_vld_i && new_feat_request_reg) ? feat_bram_dout : feat_reg[i];
    end
  endgenerate

  // -- Addr
  assign feat_bram_addr = (subgraph_vld_i && new_feat_request && !new_feat_response) ? (feat_bram_addr_reg + 1) : feat_bram_addr_reg;

  // -- Feature Index
  assign feat_bram_idx  = (subgraph_vld_reg && new_feat_request_reg) ? (feat_bram_idx_reg + 1) : feat_bram_idx_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      feat_reg           <= 'b0;
      feat_bram_idx_reg  <= 'b0;
      feat_bram_addr_reg <= 'b0;
    end else begin
      feat_reg           <= feat;
      feat_bram_idx_reg  <= feat_bram_idx;
      feat_bram_addr_reg <= feat_bram_addr;
    end
  end
  //* ==========================================================


  assign start_handle = new_feat_response_reg ? 1'b1 : start_handle_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      start_handle_reg <= 'b0;
    end else begin
      start_handle_reg <= start_handle;
    end
  end


  //* ==================== Subgraph Index ======================
  assign new_position = (cnt_reg == NUM_FEATURE_OUT - 4);

  // -- Addr
  assign subgraph_bram_addrb  = subgraph_addr_reg;
  assign subgraph_addr        = (new_position && (subgraph_addr_reg < TOTAL_NODES - 1)) ? (subgraph_addr_reg + 1) : subgraph_addr_reg;

  // -- Data
  assign subgraph_data              = (new_position_reg_q1 || subgraph_bram_addrb == 0) ? subgraph_bram_dout : subgraph_data_reg;
  assign { sog, subgraph_idx, eog } = subgraph_data_reg;

  // -- Data count
  assign cnt = (subgraph_vld_i && start_handle_reg) ? (cnt_reg + 1) :cnt_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt_reg             <= 'b0;
      sog_reg             <= 'b0;
      eog_reg             <= 'b0;
      new_position_reg    <= 'b0;
      new_position_reg_q1 <= 'b0;
      subgraph_idx_reg    <= 'b0;
      subgraph_addr_reg   <= 'b0;
      subgraph_data_reg   <= 'b0;
    end else begin
      cnt_reg             <= cnt;
      sog_reg             <= sog;
      eog_reg             <= eog;
      new_position_reg    <= new_position;
      new_position_reg_q1 <= new_position_reg;
      subgraph_idx_reg    <= subgraph_idx;
      subgraph_addr_reg   <= subgraph_addr;
      subgraph_data_reg   <= subgraph_data;
    end
  end
  //* ==========================================================


  //* ================ Push to Feature Layer 2 =================
  // -- Addr
  assign h_data_bram_addra  = h_data_addr_reg;
  assign h_data_addr        = (!subgraph_rdy_o && start_handle) ? ((subgraph_idx * NUM_FEATURE_OUT) + h_data_addr_cnt_reg) : h_data_addr_reg;

  // -- Addr count
  assign h_data_addr_cnt = (subgraph_vld_i && start_handle) ? (h_data_addr_cnt_reg + 1) : h_data_addr_cnt_reg;

  // -- Data
  assign h_data_bram_din = feat_reg[cnt_reg][31:16] >> 2;

  // -- Ena
  assign h_data_bram_ena = (subgraph_vld_i && start_handle_reg && !subgraph_rdy_o) ? 1'b1 : (cnt_reg == NUM_FEATURE_OUT - 1) ? 1'b0 : h_data_bram_ena_reg;
  assign h_data_bram_wea = h_data_bram_ena;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      h_data_addr_reg     <= 'b0;
      h_data_bram_ena_reg <= 'b0;
      h_data_addr_cnt_reg <= 'b0;
    end else begin
      h_data_addr_reg     <= h_data_addr;
      h_data_bram_ena_reg <= h_data_bram_ena;
      h_data_addr_cnt_reg <= h_data_addr_cnt;
    end
  end
  //* ==========================================================


  //* ======================= gat ready ========================
  assign subgraph_rdy_o = subgraph_rdy_reg[31];
  assign subgraph_rdy = ((cnt_reg == NUM_FEATURE_OUT - 1) && (subgraph_addr_reg == TOTAL_NODES - 1));

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      subgraph_rdy_reg <= 'b0;
    end else begin
      subgraph_rdy_reg <= { subgraph_rdy_reg[30:0], subgraph_rdy };
    end
  end
  //* ==========================================================
endmodule