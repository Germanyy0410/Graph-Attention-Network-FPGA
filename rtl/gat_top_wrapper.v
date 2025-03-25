// ==================================================================
// File name  : gat_top_wrapper.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   : Wrapper module to generate Block Design
// Author     : @Germanyy0410
// ==================================================================

module gat_top_wrapper #(
  //* ====================== parameter ======================
  parameter TOP_WIDTH             = 32,
  parameter DATA_WIDTH            = 8,
  parameter WH_DATA_WIDTH         = 12,
  parameter DMVM_DATA_WIDTH       = 20,
  parameter SM_DATA_WIDTH         = 103,
  parameter SM_SUM_DATA_WIDTH     = 103,
  parameter ALPHA_DATA_WIDTH      = 32,
  parameter NEW_FEATURE_WIDTH     = 32,

  parameter H_NUM_SPARSE_DATA     = 242101,
  parameter TOTAL_NODES           = 13264,
  parameter NUM_FEATURE_IN        = 1433,
  parameter NUM_FEATURE_OUT       = 16,
  parameter NUM_SUBGRAPHS         = 2708,
  parameter MAX_NODES             = 168,

  parameter COEF_DEPTH            = 200,
  parameter ALPHA_DEPTH           = 200,
  parameter DIVIDEND_DEPTH        = 200,
  parameter DIVISOR_DEPTH         = 200,
  //* ==========================================================

  //* ======================= localparam =======================
  // -- [BRAM]
  parameter H_DATA_DEPTH          = H_NUM_SPARSE_DATA,
  parameter NODE_INFO_DEPTH       = TOTAL_NODES,
  parameter WEIGHT_DEPTH          = NUM_FEATURE_OUT * NUM_FEATURE_IN,
  parameter WH_DEPTH              = TOTAL_NODES,
  parameter A_DEPTH               = NUM_FEATURE_OUT * 2,
  parameter NUM_NODES_DEPTH       = NUM_SUBGRAPHS,
  parameter NEW_FEATURE_DEPTH     = NUM_SUBGRAPHS * NUM_FEATURE_OUT,

  // -- [H]
  parameter H_NUM_OF_ROWS         = TOTAL_NODES,
  parameter H_NUM_OF_COLS         = NUM_FEATURE_IN,

  // -- [H] data
  parameter COL_IDX_WIDTH         = $clog2(H_NUM_OF_COLS),
  parameter H_DATA_WIDTH          = DATA_WIDTH + COL_IDX_WIDTH,
  parameter H_DATA_ADDR_W         = $clog2(H_DATA_DEPTH),

  // -- [H] node_info
  parameter ROW_LEN_WIDTH         = $clog2(H_NUM_OF_COLS),
  parameter NUM_NODE_WIDTH        = $clog2(MAX_NODES),
  parameter FLAG_WIDTH            = 1,
  parameter NODE_INFO_WIDTH       = ROW_LEN_WIDTH + NUM_NODE_WIDTH + FLAG_WIDTH,
  parameter NODE_INFO_ADDR_W      = $clog2(NODE_INFO_DEPTH),

  // -- [W]
  parameter W_NUM_OF_ROWS         = NUM_FEATURE_IN,
  parameter W_NUM_OF_COLS         = NUM_FEATURE_OUT,
  parameter W_ROW_WIDTH           = $clog2(W_NUM_OF_ROWS),
  parameter W_COL_WIDTH           = $clog2(W_NUM_OF_COLS),
  parameter WEIGHT_ADDR_W         = $clog2(WEIGHT_DEPTH),
  parameter MULT_WEIGHT_ADDR_W    = $clog2(W_NUM_OF_ROWS),

  // -- [WH]
  parameter DOT_PRODUCT_SIZE      = H_NUM_OF_COLS,
  parameter WH_ADDR_W             = $clog2(WH_DEPTH),
  parameter WH_RESULT_WIDTH       = WH_DATA_WIDTH * W_NUM_OF_COLS,
  parameter WH_WIDTH              = WH_DATA_WIDTH * W_NUM_OF_COLS + NUM_NODE_WIDTH + FLAG_WIDTH,

  // -- [A]
  parameter A_ADDR_W              = $clog2(A_DEPTH),
  parameter HALF_A_SIZE           = A_DEPTH / 2,
  parameter A_INDEX_WIDTH         = $clog2(A_DEPTH),

  // -- [DMVM]
  parameter DMVM_PRODUCT_WIDTH    = $clog2(HALF_A_SIZE),
  parameter COEF_W                = DATA_WIDTH * MAX_NODES,
  parameter ALPHA_W               = ALPHA_DATA_WIDTH * MAX_NODES,
  parameter NUM_NODE_ADDR_W       = $clog2(NUM_NODES_DEPTH),
  parameter NUM_STAGES            = $clog2(NUM_FEATURE_OUT) + 1,
  parameter COEF_DELAY_LENGTH     = NUM_STAGES + 1,

  // -- [SOFTMAX]
  parameter SOFTMAX_WIDTH         = MAX_NODES * DATA_WIDTH + NUM_NODE_WIDTH,
  parameter SOFTMAX_DEPTH         = NUM_SUBGRAPHS,
  parameter SOFTMAX_ADDR_W        = $clog2(SOFTMAX_DEPTH),
  parameter WOI                   = 1,
  parameter WOF                   = ALPHA_DATA_WIDTH - WOI,
  parameter DL_DATA_WIDTH         = $clog2(WOI + WOF + 3) + 1,
  parameter DIVISOR_FF_WIDTH      = NUM_NODE_WIDTH + SM_SUM_DATA_WIDTH,

  // -- [AGGREGATOR]
  parameter AGGR_WIDTH            = MAX_NODES * ALPHA_DATA_WIDTH + NUM_NODE_WIDTH,
  parameter AGGR_DEPTH            = NUM_SUBGRAPHS,
  parameter AGGR_ADDR_W           = $clog2(AGGR_DEPTH),
  parameter AGGR_MULT_W           = WH_DATA_WIDTH + 32,

  // -- [NEW FEATURE]
  parameter NEW_FEATURE_ADDR_W    = $clog2(NEW_FEATURE_DEPTH)
  //* ==========================================================
)(
  input                             clk                         ,
  input                             rst_n                       ,


  //* ===================== Register Bank ======================
  input                             gat_layer                   ,
  output                            gat_ready                   ,
  output  [TOP_WIDTH-1:0]           gat_debug_1                 ,
  output  [TOP_WIDTH-1:0]           gat_debug_2                 ,
  output  [TOP_WIDTH-1:0]           gat_debug_3                 ,
  input                             h_data_bram_load_done       ,
  input                             h_node_info_bram_load_done  ,
  input                             wgt_bram_load_done          ,
  //* ==========================================================


  //* ===================== BRAM Interface =====================
  input   [TOP_WIDTH-1:0]           h_data_bram_din             ,
  input                             h_data_bram_ena             ,
  input                             h_data_bram_wea             ,
  input   [H_DATA_ADDR_W+1:0]       h_data_bram_addra           ,

  input   [TOP_WIDTH-1:0]           h_node_info_bram_din        ,
  input                             h_node_info_bram_ena        ,
  input                             h_node_info_bram_wea        ,
  input   [NODE_INFO_ADDR_W+1:0]    h_node_info_bram_addra      ,

  input   [TOP_WIDTH-1:0]           wgt_bram_din                ,
  input                             wgt_bram_ena                ,
  input                             wgt_bram_wea                ,
  input   [WEIGHT_ADDR_W+1:0]       wgt_bram_addra              ,

  input   [NEW_FEATURE_ADDR_W+1:0]  feat_bram_addrb             ,
  output  [NEW_FEATURE_WIDTH-1:0]   feat_bram_dout
  //* ==========================================================
);

  gat_top #(
    .DATA_WIDTH         (DATA_WIDTH         ),

    .SM_DATA_WIDTH      (SM_DATA_WIDTH      ),
    .SM_SUM_DATA_WIDTH  (SM_SUM_DATA_WIDTH  ),
    .ALPHA_DATA_WIDTH   (ALPHA_DATA_WIDTH   ),
    .NEW_FEATURE_WIDTH  (NEW_FEATURE_WIDTH  ),

    .H_NUM_SPARSE_DATA  (H_NUM_SPARSE_DATA  ),
    .TOTAL_NODES        (TOTAL_NODES        ),
    .NUM_FEATURE_IN     (NUM_FEATURE_IN     ),
    .NUM_FEATURE_OUT    (NUM_FEATURE_OUT    ),
    .NUM_SUBGRAPHS      (NUM_SUBGRAPHS      ),
    .MAX_NODES          (MAX_NODES          ),

    .COEF_DEPTH         (COEF_DEPTH         ),
    .ALPHA_DEPTH        (ALPHA_DEPTH        ),
    .DIVIDEND_DEPTH     (DIVIDEND_DEPTH     ),
    .DIVISOR_DEPTH      (DIVISOR_DEPTH      )
  ) u_gat_top (
    .clk                          (clk                                            ),
    .rst_n                        (rst_n                                          ),

    .gat_layer                    (gat_layer                                      ),
    .gat_ready                    (gat_ready                                      ),
    .gat_debug_1                  (gat_debug_1                                    ),
    .gat_debug_2                  (gat_debug_2                                    ),
    .gat_debug_3                  (gat_debug_3                                    ),
    .h_data_bram_load_done        (h_data_bram_load_done                          ),
    .h_node_info_bram_load_done   (h_node_info_bram_load_done                     ),
    .wgt_bram_load_done           (wgt_bram_load_done                             ),

    .h_data_bram_din              (h_data_bram_din[H_DATA_WIDTH-1:0]              ),
    .h_data_bram_ena              (h_data_bram_ena                                ),
    .h_data_bram_wea              (h_data_bram_wea                                ),
    .h_data_bram_addra            (h_data_bram_addra[H_DATA_ADDR_W+1:2]           ),

    .h_node_info_bram_din         (h_node_info_bram_din[NODE_INFO_WIDTH-1:0]      ),
    .h_node_info_bram_ena         (h_node_info_bram_ena                           ),
    .h_node_info_bram_wea         (h_node_info_bram_wea                           ),
    .h_node_info_bram_addra       (h_node_info_bram_addra[NODE_INFO_ADDR_W+1:2]   ),

    .wgt_bram_din                 (wgt_bram_din[DATA_WIDTH-1:0]                   ),
    .wgt_bram_ena                 (wgt_bram_ena                                   ),
    .wgt_bram_wea                 (wgt_bram_wea                                   ),
    .wgt_bram_addra               (wgt_bram_addra[WEIGHT_ADDR_W+1:2]              ),

    .feat_bram_addrb              (feat_bram_addrb[NEW_FEATURE_ADDR_W+1:2]        ),
    .feat_bram_dout               (feat_bram_dout                                 )
  );

  wire [31:0] current_time;
  assign current_time = 15302503;

endmodule
