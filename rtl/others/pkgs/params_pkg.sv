package params_pkg;
  //* =============== parameter ===============
  parameter DATA_WIDTH            = 8;
  parameter WH_DATA_WIDTH         = 12;
  parameter DMVM_DATA_WIDTH       = 20;
  parameter SM_DATA_WIDTH         = 103;
  parameter SM_SUM_DATA_WIDTH     = 103;
  parameter ALPHA_DATA_WIDTH      = 32;

  parameter H_NUM_SPARSE_DATA     = 256;
  parameter TOTAL_NODES           = 100;
  parameter NUM_FEATURE_IN        = 5;
  parameter NUM_FEATURE_OUT       = 6;
  parameter NUM_SUBGRAPHS         = 100;
  parameter MAX_NODES             = 6;
  //* =========================================


  //* ============== localparams ==============
  localparam signed ZERO          = 20'b0000_0000_0000_0000_0000;

  // -- [DEPTH]
  localparam H_DATA_DEPTH         = H_NUM_SPARSE_DATA;
  localparam NODE_INFO_DEPTH      = TOTAL_NODES;
  localparam WEIGHT_DEPTH         = NUM_FEATURE_OUT * NUM_FEATURE_IN;
  localparam WH_1_DEPTH           = 120;
  localparam WH_2_DEPTH           = TOTAL_NODES;
  localparam A_DEPTH              = NUM_FEATURE_OUT * 2;
  // -- [H]
  localparam H_NUM_OF_ROWS        = TOTAL_NODES;
  localparam H_NUM_OF_COLS        = NUM_FEATURE_IN;
  // -- [H] value
  localparam COL_IDX_WIDTH        = $clog2(H_NUM_OF_COLS);
  localparam H_DATA_WIDTH         = DATA_WIDTH + COL_IDX_WIDTH;
  localparam H_DATA_ADDR_W        = $clog2(H_DATA_DEPTH);
  // -- [H] node_info
  localparam ROW_LEN_WIDTH        = $clog2(H_NUM_OF_COLS);
  localparam NUM_NODE_WIDTH       = $clog2(MAX_NODES);
  localparam FLAG_WIDTH           = 1;
  localparam NODE_INFO_WIDTH      = ROW_LEN_WIDTH + NUM_NODE_WIDTH + FLAG_WIDTH;
  localparam NODE_INFO_ADDR_W     = $clog2(NODE_INFO_DEPTH);

  // -- [W]
  localparam W_NUM_OF_ROWS        = NUM_FEATURE_IN;
  localparam W_NUM_OF_COLS        = NUM_FEATURE_OUT;
  localparam W_ROW_WIDTH          = $clog2(W_NUM_OF_ROWS);
  localparam W_COL_WIDTH          = $clog2(W_NUM_OF_COLS);
  localparam WEIGHT_ADDR_W        = $clog2(WEIGHT_DEPTH);
  localparam MULT_WEIGHT_ADDR_W   = $clog2(W_NUM_OF_ROWS);

  // -- [WH]
  localparam DOT_PRODUCT_SIZE     = H_NUM_OF_COLS;
  localparam WH_1_ADDR_W          = $clog2(WH_1_DEPTH);
  localparam WH_2_ADDR_W          = $clog2(WH_2_DEPTH);
  localparam WH_RESULT_WIDTH      = WH_DATA_WIDTH * W_NUM_OF_COLS;
  localparam WH_WIDTH             = WH_DATA_WIDTH * W_NUM_OF_COLS + NUM_NODE_WIDTH + FLAG_WIDTH;

  // -- [a]
  localparam A_ADDR_W             = $clog2(A_DEPTH);
  localparam HALF_A_SIZE          = A_DEPTH / 2;
  localparam A_INDEX_WIDTH        = $clog2(A_DEPTH);

  // -- [DMVM]
  localparam DMVM_PRODUCT_WIDTH   = $clog2(HALF_A_SIZE);
  localparam COEF_W               = DATA_WIDTH * MAX_NODES;
  localparam ALPHA_W              = ALPHA_DATA_WIDTH * MAX_NODES;

  // -- [Softmax]
  localparam SOFTMAX_WIDTH        = MAX_NODES * DATA_WIDTH + NUM_NODE_WIDTH;
  localparam SOFTMAX_DEPTH        = NUM_SUBGRAPHS;
  localparam SOFTMAX_ADDR_W       = $clog2(SOFTMAX_DEPTH);
  localparam WOI                  = 1;
  localparam WOF                  = ALPHA_DATA_WIDTH - WOI;
  localparam DL_DATA_WIDTH        = $clog2(WOI + WOF + 3) + 1;

  // -- [Aggregator]
  localparam AGGR_WIDTH           = MAX_NODES * ALPHA_DATA_WIDTH + NUM_NODE_WIDTH;
  localparam AGGR_DEPTH           = NUM_SUBGRAPHS;
  localparam AGGR_ADDR_W          = $clog2(AGGR_DEPTH);
  //* =========================================

  typedef struct packed {
    bit [DATA_WIDTH-1:0]      coef_1;
    bit [DATA_WIDTH-1:0]      coef_2;
    bit [DATA_WIDTH-1:0]      coef_3;
    bit [DATA_WIDTH-1:0]      coef_4;
    bit [DATA_WIDTH-1:0]      coef_5;
    bit [DATA_WIDTH-1:0]      coef_6;
    bit [NUM_NODE_WIDTH-1:0]  num_of_nodes;
  } coef_t;

  typedef struct packed {
    bit [ALPHA_DATA_WIDTH-1:0]   aggr_1;
    bit [ALPHA_DATA_WIDTH-1:0]   aggr_2;
    bit [ALPHA_DATA_WIDTH-1:0]   aggr_3;
    bit [ALPHA_DATA_WIDTH-1:0]   aggr_4;
    bit [ALPHA_DATA_WIDTH-1:0]   aggr_5;
    bit [ALPHA_DATA_WIDTH-1:0]   aggr_6;
    bit [NUM_NODE_WIDTH-1:0]     num_of_nodes;
  } aggr_t;

  typedef struct packed {
    bit [ROW_LEN_WIDTH-1:0]   row_length;
    bit [NUM_NODE_WIDTH-1:0]  num_of_nodes;
    bit                       source_node_flag;
  } node_info_t;

  typedef struct packed {
    bit [WH_DATA_WIDTH-1:0]   Wh_1;
    bit [WH_DATA_WIDTH-1:0]   Wh_2;
    bit [WH_DATA_WIDTH-1:0]   Wh_3;
    bit [WH_DATA_WIDTH-1:0]   Wh_4;
    bit [WH_DATA_WIDTH-1:0]   Wh_5;
    bit [WH_DATA_WIDTH-1:0]   Wh_6;
    bit [NUM_NODE_WIDTH-1:0]  num_of_nodes;
    bit                       source_node_flag;
  } WH_t;
endpackage