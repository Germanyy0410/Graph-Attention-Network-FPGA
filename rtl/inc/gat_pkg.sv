// ==================================================================
// File name  : gat_pkg.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   : Define all parameters & structs in the project
// Author     : @Germanyy0410
// ==================================================================

`include "gat_define.sv"

package gat_pkg;
  //* =============== parameter ===============
`ifdef TESTBENCH
  parameter H_NUM_SPARSE_DATA       = 555;
  parameter TOTAL_NODES             = 100;
  parameter NUM_FEATURE_IN          = 11;
  parameter NUM_FEATURE_OUT         = 16;
  parameter NUM_FEATURE_FINAL       = 7;
  parameter NUM_SUBGRAPHS           = 25;
  parameter MAX_NODES               = 6;

  parameter WH_DATA_WIDTH_CONV1     = 11;
  parameter WH_DATA_WIDTH_CONV2     = 16;

  parameter DMVM_DATA_WIDTH_CONV1   = 19;
  parameter DMVM_DATA_WIDTH_CONV2   = 24;

`elsif CORA
  parameter H_NUM_SPARSE_DATA       = 242101;
  parameter TOTAL_NODES             = 13264;
  parameter NUM_FEATURE_IN          = 1433;
  parameter NUM_FEATURE_OUT         = 16;
  parameter NUM_FEATURE_FINAL       = 7;
  parameter NUM_SUBGRAPHS           = 2708;
  parameter MAX_NODES               = 169;

  parameter WH_DATA_WIDTH_CONV1     = 12;
  parameter WH_DATA_WIDTH_CONV2     = 16;

  parameter DMVM_DATA_WIDTH_CONV1   = 19;
  parameter DMVM_DATA_WIDTH_CONV2   = 24;

`elsif CITESEER
  parameter H_NUM_SPARSE_DATA       = 399058;
  parameter TOTAL_NODES             = 12383;
  parameter NUM_FEATURE_IN          = 3703;
  parameter NUM_FEATURE_OUT         = 16;
  parameter NUM_FEATURE_FINAL       = 6;
  parameter NUM_SUBGRAPHS           = 3327;
  parameter MAX_NODES               = 100;
  parameter DMVM_DATA_WIDTH         = 20;

  parameter WH_DATA_WIDTH_CONV1     = 10;
  parameter WH_DATA_WIDTH_CONV2     = 16;

  parameter DMVM_DATA_WIDTH_CONV1   = 20;
  parameter DMVM_DATA_WIDTH_CONV2   = 23;

`elsif PUBMED
  parameter H_NUM_SPARSE_DATA       = 557;
  parameter TOTAL_NODES             = 100;
  parameter NUM_FEATURE_IN          = 11;
  parameter NUM_FEATURE_OUT         = 16;
  parameter NUM_FEATURE_FINAL       = 3;
  parameter NUM_SUBGRAPHS           = 26;
  parameter MAX_NODES               = 6;
  parameter DMVM_DATA_WIDTH         = 20;

  parameter WH_DATA_WIDTH_CONV1     = 10;
  parameter WH_DATA_WIDTH_CONV2     = 16;

  parameter DMVM_DATA_WIDTH_CONV1   = 20;
  parameter DMVM_DATA_WIDTH_CONV2   = 23;
`endif

  parameter DATA_WIDTH              = 8;
  parameter WH_DATA_WIDTH           = 12;
  parameter DMVM_DATA_WIDTH         = 19;
  parameter SM_DATA_WIDTH           = 108;
  parameter SM_SUM_DATA_WIDTH       = 108;
  parameter ALPHA_DATA_WIDTH        = 32;
  parameter NEW_FEATURE_WIDTH       = 32;

  parameter COEF_DEPTH              = 500;
  parameter ALPHA_DEPTH             = 500;
  parameter DIVIDEND_DEPTH          = 500;
  parameter DIVISOR_DEPTH           = 500;
  //* =========================================


  //* ============== localparams ==============
  parameter signed ZERO           = {DMVM_DATA_WIDTH{1'b0}};

  // -- [BRAM]
  parameter H_DATA_DEPTH          = H_NUM_SPARSE_DATA;
  parameter NODE_INFO_DEPTH       = TOTAL_NODES;
  parameter WEIGHT_DEPTH          = NUM_FEATURE_OUT * NUM_FEATURE_IN + NUM_FEATURE_OUT * 2;
  parameter WH_DEPTH              = TOTAL_NODES;
  parameter A_DEPTH               = NUM_FEATURE_OUT * 2;
  parameter NUM_NODES_DEPTH       = NUM_SUBGRAPHS;
  parameter NEW_FEATURE_DEPTH     = NUM_SUBGRAPHS * NUM_FEATURE_OUT;

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

  // -- [A]
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

  // -- [SOFTMAX]
  parameter SOFTMAX_WIDTH         = MAX_NODES * DATA_WIDTH + NUM_NODE_WIDTH;
  parameter SOFTMAX_DEPTH         = NUM_SUBGRAPHS;
  parameter SOFTMAX_ADDR_W        = $clog2(SOFTMAX_DEPTH);
  parameter WOI                   = 1;
  parameter WOF                   = ALPHA_DATA_WIDTH - WOI;
  parameter DL_DATA_WIDTH         = $clog2(WOI + WOF + 3) + 1;
  parameter DIVISOR_FF_WIDTH      = NUM_NODE_WIDTH + SM_SUM_DATA_WIDTH;

  // -- [AGGREGATOR]
  parameter AGGR_WIDTH            = MAX_NODES * ALPHA_DATA_WIDTH + NUM_NODE_WIDTH;
  parameter AGGR_DEPTH            = NUM_SUBGRAPHS;
  parameter AGGR_ADDR_W           = $clog2(AGGR_DEPTH);
  parameter AGGR_MULT_W           = WH_DATA_WIDTH + 32;

  // -- [NEW FEATURE]
  parameter NEW_FEATURE_ADDR_W    = $clog2(NEW_FEATURE_DEPTH);

  parameter IDLE                  = 2'b00;
  parameter RUN                   = 2'b01;
  parameter DONE                  = 2'b10;
  parameter DUMP                  = 2'b11;
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
  } wh_t;

  typedef struct packed {
    logic [NUM_FEATURE_OUT-1:0] [DATA_WIDTH-1:0]      coef;
    logic [NUM_NODE_WIDTH-1:0]                        num_of_nodes;
  } coef_t;

  typedef struct packed {
    bit [NUM_NODE_WIDTH-1:0]      num_of_nodes;
    bit [SM_SUM_DATA_WIDTH-1:0]   divisor;
  } dvsr_t;

endpackage
