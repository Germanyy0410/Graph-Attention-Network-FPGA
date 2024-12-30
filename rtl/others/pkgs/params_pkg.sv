`define SIMULATION            1

// `define VIVADO                1

// `define PASSED                1
`define FAILED                1

package params_pkg;
  //* =============== parameter ===============
  // -- [Configurable] Data Width
  parameter DATA_WIDTH            = 8;
  parameter WH_DATA_WIDTH         = 12;
  parameter DMVM_DATA_WIDTH       = 20;
  parameter SM_DATA_WIDTH         = 103;
  parameter SM_SUM_DATA_WIDTH     = 103;
  parameter ALPHA_DATA_WIDTH      = 32;

`ifdef SIMULATION
  parameter H_NUM_SPARSE_DATA     = 2105;
  parameter TOTAL_NODES           = 200;
  parameter NUM_FEATURE_IN        = 21;
  parameter NUM_FEATURE_OUT       = 16;
  parameter NUM_SUBGRAPHS         = 21;
  parameter MAX_NODES             = 18;

  parameter COEF_DEPTH            = 30;
  parameter ALPHA_DEPTH           = 30;
  parameter DIVIDEND_DEPTH        = 30;
  parameter DIVISOR_DEPTH         = 30;
`else
  parameter H_NUM_SPARSE_DATA     = 242101;
  parameter TOTAL_NODES           = 13264;
  parameter NUM_FEATURE_IN        = 1433;
  parameter NUM_FEATURE_OUT       = 16;
  parameter NUM_SUBGRAPHS         = 2708;
  parameter MAX_NODES             = 168;

  parameter COEF_DEPTH            = 200;
  parameter ALPHA_DEPTH           = 200;
  parameter DIVIDEND_DEPTH        = 200;
  parameter DIVISOR_DEPTH         = 200;
`endif
  //* =========================================


  //* ============== localparams ==============
  parameter signed ZERO           = {DMVM_DATA_WIDTH{1'b0}};

  // -- [BRAMs] Depth
  parameter H_DATA_DEPTH          = H_NUM_SPARSE_DATA;
  parameter NODE_INFO_DEPTH       = TOTAL_NODES;
  parameter WEIGHT_DEPTH          = NUM_FEATURE_OUT * NUM_FEATURE_IN;
  parameter WH_DEPTH              = 1000;
  parameter A_DEPTH               = NUM_FEATURE_OUT * 2;
  parameter NUM_NODES_DEPTH       = NUM_SUBGRAPHS;

  // -- [H]
  parameter H_NUM_OF_ROWS         = TOTAL_NODES;
  parameter H_NUM_OF_COLS         = NUM_FEATURE_IN;

  // -- [H] data
  parameter COL_IDX_WIDTH         = $clog2(H_NUM_OF_COLS);
  parameter H_DATA_WIDTH          = DATA_WIDTH + COL_IDX_WIDTH;
  parameter H_DATA_ADDR_W         = $clog2(H_DATA_DEPTH);

  // -- [H] node_info
  parameter ROW_LEN_WIDTH         = $clog2(H_NUM_OF_COLS);
  parameter NUM_NODE_WIDTH        = $clog2(MAX_NODES);
  parameter FLAG_WIDTH            = 1;
  parameter NODE_INFO_WIDTH       = ROW_LEN_WIDTH + NUM_NODE_WIDTH + FLAG_WIDTH;
  parameter NODE_INFO_ADDR_W      = $clog2(NODE_INFO_DEPTH);

  // -- [W]
  parameter W_NUM_OF_ROWS         = NUM_FEATURE_IN;
  parameter W_NUM_OF_COLS         = NUM_FEATURE_OUT;
  parameter W_ROW_WIDTH           = $clog2(W_NUM_OF_ROWS);
  parameter W_COL_WIDTH           = $clog2(W_NUM_OF_COLS);
  parameter WEIGHT_ADDR_W         = $clog2(WEIGHT_DEPTH);
  parameter MULT_WEIGHT_ADDR_W    = $clog2(W_NUM_OF_ROWS);

  // -- [WH]
  parameter DOT_PRODUCT_SIZE      = H_NUM_OF_COLS;
  parameter WH_ADDR_W             = $clog2(WH_DEPTH);
  parameter WH_RESULT_WIDTH       = WH_DATA_WIDTH * W_NUM_OF_COLS;
  parameter WH_WIDTH              = WH_DATA_WIDTH * W_NUM_OF_COLS + NUM_NODE_WIDTH + FLAG_WIDTH;

  // -- [a]
  parameter A_ADDR_W              = $clog2(A_DEPTH);
  parameter HALF_A_SIZE           = A_DEPTH / 2;
  parameter A_INDEX_WIDTH         = $clog2(A_DEPTH);

  // -- [DMVM]
  parameter DMVM_PRODUCT_WIDTH    = $clog2(HALF_A_SIZE);
  parameter COEF_W                = DATA_WIDTH * MAX_NODES;
  parameter ALPHA_W               = ALPHA_DATA_WIDTH * MAX_NODES;
  parameter NUM_NODE_ADDR_W       = $clog2(NUM_NODES_DEPTH);
  parameter NUM_STAGES            = $clog2(NUM_FEATURE_OUT) + 1;
  parameter COEF_DELAY_LENGTH     = NUM_STAGES + 1;

  // -- [Softmax]
  parameter SOFTMAX_WIDTH         = MAX_NODES * DATA_WIDTH + NUM_NODE_WIDTH;
  parameter SOFTMAX_DEPTH         = NUM_SUBGRAPHS;
  parameter SOFTMAX_ADDR_W        = $clog2(SOFTMAX_DEPTH);
  parameter WOI                   = 1;
  parameter WOF                   = ALPHA_DATA_WIDTH - WOI;
  parameter DL_DATA_WIDTH         = $clog2(WOI + WOF + 3) + 1;
  parameter DIVISOR_FF_WIDTH      = NUM_NODE_WIDTH + SM_SUM_DATA_WIDTH;

  // -- [Aggregator]
  parameter AGGR_WIDTH            = MAX_NODES * ALPHA_DATA_WIDTH + NUM_NODE_WIDTH;
  parameter AGGR_DEPTH            = NUM_SUBGRAPHS;
  parameter AGGR_ADDR_W           = $clog2(AGGR_DEPTH);

  // -- [New Feature]
  parameter NEW_FEATURE_WIDTH     = DATA_WIDTH * NUM_FEATURE_OUT;
  parameter NEW_FEATURE_DEPTH     = TOTAL_NODES;
  parameter NEW_FEATURE_ADDR_W    = $clog2(NEW_FEATURE_DEPTH);
  //* =========================================

  typedef struct packed {
    bit [ROW_LEN_WIDTH-1:0]     row_length;
    bit [NUM_NODE_WIDTH-1:0]    num_of_nodes;
    bit                         source_node_flag;
  } node_info_t;

  typedef struct packed {
    logic [NUM_FEATURE_OUT-1:0] [WH_DATA_WIDTH-1:0]   Wh;
    logic [NUM_NODE_WIDTH-1:0]                        num_of_nodes;
    logic                                             source_node_flag;
  } WH_t;

  typedef struct packed {
    logic [NUM_FEATURE_OUT-1:0] [DATA_WIDTH-1:0]      coef;
    logic [NUM_NODE_WIDTH-1:0]                        num_of_nodes;
  } coef_t;

  typedef struct packed {
    bit [NUM_NODE_WIDTH-1:0]    num_of_nodes;
    bit [SM_SUM_DATA_WIDTH-1:0] divisor;
  } divisor_t;
endpackage
