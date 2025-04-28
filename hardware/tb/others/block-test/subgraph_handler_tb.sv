`timescale 1ns / 1ps

module subgraph_handler_tb #(
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
)();

  logic                                                 clk                 ;
  logic                                                 rst_n               ;

  logic                                                 subgraph_vld_i      ;
  logic                                                 subgraph_rdy_o      ;
  logic                                                 gat_ready           ;

  // -- New Feature
  logic [NEW_FEATURE_ADDR_W-1:0]                        feat_bram_addra     ;
  logic [NEW_FEATURE_WIDTH-1:0]                         feat_bram_din       ;
  logic                                                 feat_bram_ena       ;
  logic [NEW_FEATURE_ADDR_W-1:0]                        feat_bram_addrb     ;
  logic [NEW_FEATURE_WIDTH-1:0]                         feat_bram_dout      ;

  // -- Subgraph Index
  logic [SUBGRAPH_IDX_ADDR_W-1:0]                       subgraph_bram_addra ;
  logic [SUBGRAPH_IDX_WIDTH-1:0]                        subgraph_bram_din   ;
  logic                                                 subgraph_bram_ena   ;
  logic [SUBGRAPH_IDX_ADDR_W-1:0]                       subgraph_bram_addrb ;
  logic [SUBGRAPH_IDX_WIDTH-1:0]                        subgraph_bram_dout  ;

  // -- H Data
  logic [H_DATA_ADDR_W-1:0]                             h_data_bram_addra   ;
  logic [H_DATA_WIDTH-1:0]                              h_data_bram_din     ;
  logic                                                 h_data_bram_ena     ;
  logic                                                 h_data_bram_wea     ;
  logic [H_DATA_ADDR_W-1:0]                             h_data_bram_addrb   ;
  logic [H_DATA_WIDTH-1:0]                              h_data_bram_dout    ;

  subgraph_handler dut (.*);

  always #5 clk = ~clk;
  initial begin
    clk       = 1'b1;
    rst_n     = 1'b0;
    #15.01;
    rst_n     = 1'b1;
  end

  BRAM #(
    .DATA_WIDTH   (SUBGRAPH_IDX_WIDTH     ),
    .DEPTH        (SUBGRAPH_IDX_DEPTH     )
  ) u_subgraph_bram (
    .clk          (clk                    ),
    .rst_n        (rst_n                  ),
    .din          (subgraph_bram_din      ),
    .addra        (subgraph_bram_addra    ),
    .ena          (subgraph_bram_ena      ),
    .wea          (subgraph_bram_ena      ),
    .addrb        (subgraph_bram_addrb    ),
    .dout         (subgraph_bram_dout     )
  );

  BRAM #(
    .DATA_WIDTH   (NEW_FEATURE_WIDTH      ),
    .DEPTH        (160                    )
  ) u_feat_bram (
    .clk          (clk                    ),
    .rst_n        (rst_n                  ),
    .din          (feat_bram_din          ),
    .addra        (feat_bram_addra        ),
    .ena          (feat_bram_ena          ),
    .wea          (feat_bram_ena          ),
    .addrb        (feat_bram_addrb        ),
    .dout         (feat_bram_dout         )
  );

  BRAM #(
    .DATA_WIDTH   (H_DATA_WIDTH           ),
    .DEPTH        (230                    )
  ) u_h_data_bram (
    .clk          (clk                    ),
    .rst_n        (rst_n                  ),
    .din          (h_data_bram_din        ),
    .addra        (h_data_bram_addra      ),
    .ena          (h_data_bram_ena        ),
    .wea          (h_data_bram_wea        ),
    .addrb        (h_data_bram_addrb      ),
    .dout         (h_data_bram_dout       )
  );

  initial begin
    subgraph_vld_i = 1'b0;

    //* ================= Feature ==================
    feat_bram_ena = 1'b1;
    for (int i = 0; i < NUM_FEATURE_OUT*5; i = i + 1) begin
      feat_bram_din   = i + 1;
      feat_bram_addra = i;
      #10.01;
    end
    feat_bram_ena = 1'b0;
    //* ============================================

    #20.01;
    subgraph_bram_ena = 1'b1;
    //* ================== Node 0 ==================
    subgraph_bram_addra = 0;
    subgraph_bram_din   = { 1'b1, 14'd2, 1'b0 };
    #10.01;
    subgraph_bram_addra = 1;
    subgraph_bram_din   = { 1'b0, 14'd6, 1'b0 };
    #10.01;
    subgraph_bram_addra = 2;
    subgraph_bram_din   = { 1'b0, 14'd8, 1'b0 };
    #10.01;
    subgraph_bram_addra = 3;
    subgraph_bram_din   = { 1'b0, 14'd10, 1'b1 };
    //* ============================================


    //* ================== Node 1 ==================
    #10.01;
    subgraph_bram_addra = 4;
    subgraph_bram_din   = { 1'b1, 14'd0, 1'b0 };
    #10.01;
    subgraph_bram_addra = 5;
    subgraph_bram_din   = { 1'b0, 14'd4, 1'b1 };
    //* ============================================


    //* ================== Node 2 ==================
    #10.01;
    subgraph_bram_addra = 6;
    subgraph_bram_din   = { 1'b1, 14'd1, 1'b0 };
    #10.01;
    subgraph_bram_addra = 7;
    subgraph_bram_din   = { 1'b0, 14'd3, 1'b0 };
    #10.01;
    subgraph_bram_addra = 8;
    subgraph_bram_din   = { 1'b0, 14'd5, 1'b0 };
    #10.01;
    subgraph_bram_addra = 9;
    subgraph_bram_din   = { 1'b0, 14'd7, 1'b1 };
    //* ============================================

    #10.01;
    subgraph_bram_ena = 1'b0;


    #20.01;
    subgraph_vld_i = 1'b1;

    #2000;
    $finish();
  end
endmodule