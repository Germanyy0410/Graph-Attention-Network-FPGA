`ifndef _parameters_vh_
`define _parameters_vh_
  //* =============== parameter ===============

`ifdef CORA_DATASET_EN
  parameter H_NUM_SPARSE_DATA     = 242101;
  parameter TOTAL_NODES           = 13264;
  parameter NUM_FEATURE_IN        = 1433;
  parameter NUM_FEATURE_OUT       = 16;
  parameter NUM_SUBGRAPHS         = 2708;
  parameter MAX_NODES             = 168;
`endif

`ifdef SIMULATION
  parameter H_NUM_SPARSE_DATA     = 500;
  parameter TOTAL_NODES           = 100;
  parameter NUM_FEATURE_IN        = 10;
  parameter NUM_FEATURE_OUT       = 16;
  parameter NUM_SUBGRAPHS         = 26;
  parameter MAX_NODES             = 6;
`endif

  // -- Configurable data width
  parameter DATA_WIDTH            = 8;
  parameter WH_DATA_WIDTH         = 12;
  parameter DMVM_DATA_WIDTH       = 20;
  parameter SM_DATA_WIDTH         = 103;
  parameter SM_SUM_DATA_WIDTH     = 103;
  parameter ALPHA_DATA_WIDTH      = 32;
  //* =========================================


  //* ============== localparams ==============
  parameter signed ZERO          = 20'b0000_0000_0000_0000_0000;

  // -- [DEPTH]
  parameter H_DATA_DEPTH         = H_NUM_SPARSE_DATA;
  parameter NODE_INFO_DEPTH      = TOTAL_NODES;
  parameter WEIGHT_DEPTH         = NUM_FEATURE_OUT * NUM_FEATURE_IN;
  parameter WH_1_DEPTH           = TOTAL_NODES;
  parameter WH_2_DEPTH           = TOTAL_NODES;
  parameter A_DEPTH              = NUM_FEATURE_OUT * 2;
  parameter NUM_NODES_DEPTH      = NUM_SUBGRAPHS;
  // -- [H]
  parameter H_NUM_OF_ROWS        = TOTAL_NODES;
  parameter H_NUM_OF_COLS        = NUM_FEATURE_IN;
  // -- [H] value
  parameter COL_IDX_WIDTH        = $clog2(H_NUM_OF_COLS);
  parameter H_DATA_WIDTH         = DATA_WIDTH + COL_IDX_WIDTH;
  parameter H_DATA_ADDR_W        = $clog2(H_DATA_DEPTH);
  // -- [H] node_info
  parameter ROW_LEN_WIDTH        = $clog2(H_NUM_OF_COLS);
  parameter NUM_NODE_WIDTH       = $clog2(MAX_NODES);
  parameter FLAG_WIDTH           = 1;
  parameter NODE_INFO_WIDTH      = ROW_LEN_WIDTH + NUM_NODE_WIDTH + FLAG_WIDTH;
  parameter NODE_INFO_ADDR_W     = $clog2(NODE_INFO_DEPTH);

  // -- [W]
  parameter W_NUM_OF_ROWS        = NUM_FEATURE_IN;
  parameter W_NUM_OF_COLS        = NUM_FEATURE_OUT;
  parameter W_ROW_WIDTH          = $clog2(W_NUM_OF_ROWS);
  parameter W_COL_WIDTH          = $clog2(W_NUM_OF_COLS);
  parameter WEIGHT_ADDR_W        = $clog2(WEIGHT_DEPTH);
  parameter MULT_WEIGHT_ADDR_W   = $clog2(W_NUM_OF_ROWS);

  // -- [WH]
  parameter DOT_PRODUCT_SIZE     = H_NUM_OF_COLS;
  parameter WH_1_ADDR_W          = $clog2(WH_1_DEPTH);
  parameter WH_2_ADDR_W          = $clog2(WH_2_DEPTH);
  parameter WH_RESULT_WIDTH      = WH_DATA_WIDTH * W_NUM_OF_COLS;
  parameter WH_WIDTH             = WH_DATA_WIDTH * W_NUM_OF_COLS + NUM_NODE_WIDTH + FLAG_WIDTH;

  // -- [a]
  parameter A_ADDR_W             = $clog2(A_DEPTH);
  parameter HALF_A_SIZE          = A_DEPTH / 2;
  parameter A_INDEX_WIDTH        = $clog2(A_DEPTH);

  // -- [DMVM]
  parameter DMVM_PRODUCT_WIDTH   = $clog2(HALF_A_SIZE);
  parameter COEF_W               = DATA_WIDTH * MAX_NODES;
  parameter ALPHA_W              = ALPHA_DATA_WIDTH * MAX_NODES;
  parameter NUM_NODE_ADDR_W      = $clog2(NUM_NODES_DEPTH);

  // -- [Softmax]
  parameter SOFTMAX_WIDTH        = MAX_NODES * DATA_WIDTH + NUM_NODE_WIDTH;
  parameter SOFTMAX_DEPTH        = NUM_SUBGRAPHS;
  parameter SOFTMAX_ADDR_W       = $clog2(SOFTMAX_DEPTH);
  parameter WOI                  = 1;
  parameter WOF                  = ALPHA_DATA_WIDTH - WOI;
  parameter DL_DATA_WIDTH        = $clog2(WOI + WOF + 3) + 1;
  parameter DIVISOR_FF_WIDTH     = NUM_NODE_WIDTH + SM_SUM_DATA_WIDTH;

  // -- [Aggregator]
  parameter AGGR_WIDTH           = MAX_NODES * ALPHA_DATA_WIDTH + NUM_NODE_WIDTH;
  parameter AGGR_DEPTH           = NUM_SUBGRAPHS;
  parameter AGGR_ADDR_W          = $clog2(AGGR_DEPTH);
  //* =========================================

`endif
