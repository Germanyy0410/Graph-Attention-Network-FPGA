package params_pkg;
  //* =============== parameter ================
  // -- [DATA WIDTH]
  parameter DATA_WIDTH            = 8;
  parameter WH_DATA_WIDTH         = 12;
  parameter DMVM_DATA_WIDTH       = 20;
  parameter SM_DATA_WIDTH         = 103;
  parameter SM_SUM_DATA_WIDTH     = 103;
  parameter ALPHA_DATA_WIDTH      = 32;

  parameter H_NUM_SPARSE_DATA     = 242101;
  parameter TOTAL_NODES           = 13264;
  parameter NUM_FEATURE_IN        = 1433;
  parameter NUM_FEATURE_OUT       = 16;
  parameter NUM_SUBGRAPHS         = 2708;
  parameter MAX_NODES             = 168;

  // -- [H]
  parameter H_NUM_OF_ROWS         = TOTAL_NODES;
  parameter H_NUM_OF_COLS         = NUM_FEATURE_IN;

  // -- [W]
  parameter W_NUM_OF_ROWS         = NUM_FEATURE_IN;
  parameter W_NUM_OF_COLS         = NUM_FEATURE_OUT;

  // -- [BRAM]
  parameter COL_IDX_DEPTH         = H_NUM_SPARSE_DATA;
  parameter VALUE_DEPTH           = H_NUM_SPARSE_DATA;
  parameter NODE_INFO_DEPTH       = TOTAL_NODES;
  parameter WEIGHT_DEPTH          = W_NUM_OF_COLS * W_NUM_OF_ROWS;
  parameter WH_1_DEPTH            = 120;
  parameter WH_2_DEPTH            = TOTAL_NODES;
  parameter A_DEPTH               = W_NUM_OF_COLS * 2;

  // -- [MAX_NODES]

  parameter signed ZERO           = 20'b0000_0000_0000_0000_0000;

  //* ============== localparams ===============
  // -- [H] col_idx
  localparam COL_IDX_WIDTH        = $clog2(H_NUM_OF_COLS);
  localparam COL_IDX_ADDR_W       = $clog2(COL_IDX_DEPTH);
  // -- [H] value
  localparam VALUE_WIDTH          = DATA_WIDTH;
  localparam VALUE_ADDR_W         = $clog2(VALUE_DEPTH);
  // -- [H] node_info = [row_length - num_of_nodes - source_node_flag]
  localparam ROW_LEN_WIDTH        = $clog2(H_NUM_OF_COLS);
  localparam NUM_NODE_WIDTH       = $clog2(MAX_NODES);
  localparam NODE_INFO_WIDTH      = ROW_LEN_WIDTH + NUM_NODE_WIDTH + 1;
  localparam NODE_INFO_ADDR_W     = $clog2(NODE_INFO_DEPTH);

  // -- [W]
  localparam W_ROW_WIDTH          = $clog2(W_NUM_OF_ROWS);
  localparam W_COL_WIDTH          = $clog2(W_NUM_OF_COLS);
  localparam WEIGHT_ADDR_W        = $clog2(WEIGHT_DEPTH);
  localparam MULT_WEIGHT_ADDR_W   = $clog2(W_NUM_OF_ROWS);

  // -- [WH]
  parameter DOT_PRODUCT_SIZE      = H_NUM_OF_COLS;
  localparam WH_1_ADDR_W          = $clog2(WH_1_DEPTH);
  localparam WH_2_ADDR_W          = $clog2(WH_2_DEPTH);
  localparam WH_RESULT_WIDTH      = WH_DATA_WIDTH * W_NUM_OF_COLS;
  localparam WH_WIDTH             = WH_DATA_WIDTH * W_NUM_OF_COLS + NUM_NODE_WIDTH + 1;

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