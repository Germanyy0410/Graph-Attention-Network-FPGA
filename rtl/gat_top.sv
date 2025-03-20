// ==================================================================
// File name  : gat_top.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   : Top module of the Acceleration Core
// Author     : @Germanyy0410
// ==================================================================

`include "others/define/gat_define.sv"

module gat_top #(
  //* ======================= parameter ========================
`ifdef TESTBENCH
  parameter H_NUM_SPARSE_DATA       = 555,
  parameter TOTAL_NODES             = 100,
  parameter NUM_FEATURE_IN          = 11,
  parameter NUM_FEATURE_OUT         = 16,
  parameter NUM_FEATURE_FINAL       = 7,
  parameter NUM_SUBGRAPHS           = 25,
  parameter MAX_NODES               = 6,

  parameter WH_DATA_WIDTH_CONV1     = 11,
  parameter WH_DATA_WIDTH_CONV2     = 16,

  parameter DMVM_DATA_WIDTH_CONV1   = 19,
  parameter DMVM_DATA_WIDTH_CONV2   = 24,

`elsif CORA
  parameter H_NUM_SPARSE_DATA       = 242101,
  parameter TOTAL_NODES             = 13264,
  parameter NUM_FEATURE_IN          = 1433,
  parameter NUM_FEATURE_OUT         = 16,
  parameter NUM_FEATURE_FINAL       = 7,
  parameter NUM_SUBGRAPHS           = 2708,
  parameter MAX_NODES               = 169,

  parameter WH_DATA_WIDTH_CONV1     = 12,
  parameter WH_DATA_WIDTH_CONV2     = 16,

  parameter DMVM_DATA_WIDTH_CONV1   = 19,
  parameter DMVM_DATA_WIDTH_CONV2   = 24,

`elsif CITESEER
  parameter H_NUM_SPARSE_DATA       = 399058,
  parameter TOTAL_NODES             = 12383,
  parameter NUM_FEATURE_IN          = 3703,
  parameter NUM_FEATURE_OUT         = 16,
  parameter NUM_FEATURE_FINAL       = 6,
  parameter NUM_SUBGRAPHS           = 3279,
  parameter MAX_NODES               = 100,
  parameter DMVM_DATA_WIDTH         = 20,

  parameter WH_DATA_WIDTH_CONV1     = 10,
  parameter WH_DATA_WIDTH_CONV2     = 16,

  parameter DMVM_DATA_WIDTH_CONV1   = 20,
  parameter DMVM_DATA_WIDTH_CONV2   = 23,

`elsif PUBMED
  parameter H_NUM_SPARSE_DATA       = 557,
  parameter TOTAL_NODES             = 100,
  parameter NUM_FEATURE_IN          = 11,
  parameter NUM_FEATURE_OUT         = 16,
  parameter NUM_FEATURE_FINAL       = 3,
  parameter NUM_SUBGRAPHS           = 26,
  parameter MAX_NODES               = 6,
  parameter DMVM_DATA_WIDTH         = 20,

  parameter WH_DATA_WIDTH_CONV1     = 10,
  parameter WH_DATA_WIDTH_CONV2     = 16,

  parameter DMVM_DATA_WIDTH_CONV1   = 20,
  parameter DMVM_DATA_WIDTH_CONV2   = 23,
`endif

  parameter DATA_WIDTH              = 8,
  parameter SM_DATA_WIDTH           = 108,
  parameter SM_SUM_DATA_WIDTH       = 108,
  parameter ALPHA_DATA_WIDTH        = 32,
  parameter NEW_FEATURE_WIDTH       = 32,

  parameter COEF_DEPTH              = 500,
  parameter ALPHA_DEPTH             = 500,
  parameter DIVIDEND_DEPTH          = 500,
  parameter DIVISOR_DEPTH           = 500,
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
  localparam WH_WIDTH             = WH_DATA_WIDTH_CONV1 * W_NUM_OF_COLS + NUM_NODE_WIDTH + FLAG_WIDTH,

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

  // -- [NEW FEATURE]
  localparam NEW_FEATURE_ADDR_W   = $clog2(NEW_FEATURE_DEPTH)
  //* ==========================================================
)(
  input                             clk                         ,
  input                             rst_n                       ,

  //* ===================== Register Bank ======================
  input                             gat_layer                   ,
  output                            gat_ready                   ,
  output  [31:0]                    gat_debug_1                 ,
  output  [31:0]                    gat_debug_2                 ,
  output  [31:0]                    gat_debug_3                 ,
  input                             h_data_bram_load_done       ,
  input                             h_node_info_bram_load_done  ,
  input                             wgt_bram_load_done          ,
  //* ==========================================================


  //* ===================== BRAM Interface =====================
  input   [H_DATA_WIDTH-1:0]        h_data_bram_din             ,
  input                             h_data_bram_ena             ,
  input                             h_data_bram_wea             ,
  input   [H_DATA_ADDR_W-1:0]       h_data_bram_addra           ,

  input   [NODE_INFO_WIDTH-1:0]     h_node_info_bram_din        ,
  input                             h_node_info_bram_ena        ,
  input                             h_node_info_bram_wea        ,
  input   [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addra      ,

  input   [DATA_WIDTH-1:0]          wgt_bram_din                ,
  input                             wgt_bram_ena                ,
  input                             wgt_bram_wea                ,
  input   [WEIGHT_ADDR_W-1:0]       wgt_bram_addra              ,

  input   [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addrb             ,
  output  [NEW_FEATURE_WIDTH-1:0]   feat_bram_dout
  //* ==========================================================
);

  localparam WGT_ADDR_W_CONV1 = $clog2(NUM_FEATURE_OUT * NUM_FEATURE_IN + NUM_FEATURE_OUT * 2);
  localparam WGT_ADDR_W_CONV2 = $clog2(NUM_FEATURE_OUT * NUM_FEATURE_FINAL + NUM_FEATURE_FINAL * 2);
  localparam WGT_ADDR_W_DIFF  = WGT_ADDR_W_CONV1 - WGT_ADDR_W_CONV2;

  localparam FEAT_ADDR_W_CONV1 = $clog2(NUM_SUBGRAPHS*NUM_FEATURE_OUT);
  localparam FEAT_ADDR_W_CONV2 = $clog2(NUM_SUBGRAPHS*NUM_FEATURE_FINAL);
  localparam FEAT_ADDR_W_DIFF  = FEAT_ADDR_W_CONV1 - FEAT_ADDR_W_CONV2;

  //* ====================== Memory Logic ======================
  // -- PL
  logic [H_DATA_ADDR_W-1:0]       h_data_bram_addrb             ;
  logic [H_DATA_ADDR_W-1:0]       h_data_bram_addrb_conv1       ;
  logic [H_DATA_ADDR_W-1:0]       h_data_bram_addrb_conv2       ;
  logic [H_DATA_WIDTH-1:0]        h_data_bram_dout              ;

  logic [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addrb        ;
  logic [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addrb_conv1  ;
  logic [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addrb_conv2  ;
  logic [NODE_INFO_WIDTH-1:0]     h_node_info_bram_dout         ;

  logic [WEIGHT_ADDR_W-1:0]       wgt_bram_addrb                ;
  logic [WEIGHT_ADDR_W-1:0]       wgt_bram_addrb_conv1          ;
  logic [WEIGHT_ADDR_W-1:0]       wgt_bram_addrb_conv2          ;
  logic [WGT_ADDR_W_CONV2-1:0]    wgt_bram_addrb_conv2_raw      ;
  logic [DATA_WIDTH-1:0]          wgt_bram_dout                 ;

  // -- Output
  logic [WH_WIDTH-1:0]            wh_bram_dout                  ;
  logic [NUM_NODE_WIDTH-1:0]      num_node_bram_doutb           ;
  logic [NUM_NODE_WIDTH-1:0]      num_node_bram_doutc           ;

  // -- Conv1
  logic [WH_WIDTH-1:0]            wh_bram_din_conv1             ;
  logic                           wh_bram_ena_conv1             ;
  logic [WH_ADDR_W-1:0]           wh_bram_addra_conv1           ;
  logic [WH_ADDR_W-1:0]           wh_bram_addrb_conv1           ;

  logic [NUM_NODE_WIDTH-1:0]      num_node_bram_din_conv1       ;
  logic                           num_node_bram_ena_conv1       ;
  logic [NUM_NODE_ADDR_W-1:0]     num_node_bram_addra_conv1     ;
  logic [NUM_NODE_ADDR_W-1:0]     num_node_bram_addrb_conv1     ;
  logic [NUM_NODE_ADDR_W-1:0]     num_node_bram_addrc_conv1     ;

  logic [NEW_FEATURE_WIDTH-1:0]   feat_bram_din_conv1           ;
  logic                           feat_bram_ena_conv1           ;
  logic [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addra_conv1         ;

  logic                           gat_ready_conv1               ;

  // -- Conv2
  logic [WH_WIDTH-1:0]            wh_bram_din_conv2             ;
  logic                           wh_bram_ena_conv2             ;
  logic [WH_ADDR_W-1:0]           wh_bram_addra_conv2           ;
  logic [WH_ADDR_W-1:0]           wh_bram_addrb_conv2           ;

  logic [NUM_NODE_WIDTH-1:0]      num_node_bram_din_conv2       ;
  logic                           num_node_bram_ena_conv2       ;
  logic [NUM_NODE_ADDR_W-1:0]     num_node_bram_addra_conv2     ;
  logic [NUM_NODE_ADDR_W-1:0]     num_node_bram_addrb_conv2     ;
  logic [NUM_NODE_ADDR_W-1:0]     num_node_bram_addrc_conv2     ;

  logic [NEW_FEATURE_WIDTH-1:0]   feat_bram_din_conv2           ;
  logic                           feat_bram_ena_conv2           ;
  logic [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addra_conv2         ;
  logic [FEAT_ADDR_W_CONV2-1:0]   feat_bram_addra_conv2_raw     ;

  logic                           gat_ready_conv2               ;
  //* ==========================================================


  assign gat_ready = (gat_layer == 1'b0) ? gat_ready_conv1 : gat_ready_conv2;
  assign wgt_bram_addrb_conv2  = { {WGT_ADDR_W_DIFF{1'b0}}, wgt_bram_addrb_conv2_raw };
  assign feat_bram_addra_conv2 = { {FEAT_ADDR_W_DIFF{1'b0}}, feat_bram_addra_conv2_raw };


  //* ==================== Memory Controller ===================
  memory_controller #(
    .DATA_WIDTH         (DATA_WIDTH             ),
    .SM_DATA_WIDTH      (SM_DATA_WIDTH          ),
    .SM_SUM_DATA_WIDTH  (SM_SUM_DATA_WIDTH      ),
    .ALPHA_DATA_WIDTH   (ALPHA_DATA_WIDTH       ),
    .NEW_FEATURE_WIDTH  (NEW_FEATURE_WIDTH      ),

    .WH_DATA_WIDTH      (WH_DATA_WIDTH_CONV1    ),
    .DMVM_DATA_WIDTH    (DMVM_DATA_WIDTH_CONV1  ),

    .H_NUM_SPARSE_DATA  (H_NUM_SPARSE_DATA      ),
    .TOTAL_NODES        (TOTAL_NODES            ),
    .NUM_FEATURE_IN     (NUM_FEATURE_IN         ),
    .NUM_FEATURE_OUT    (NUM_FEATURE_OUT        ),
    .NUM_SUBGRAPHS      (NUM_SUBGRAPHS          ),
    .MAX_NODES          (MAX_NODES              ),

    .COEF_DEPTH         (COEF_DEPTH             ),
    .ALPHA_DEPTH        (ALPHA_DEPTH            ),
    .DIVIDEND_DEPTH     (DIVIDEND_DEPTH         ),
    .DIVISOR_DEPTH      (DIVISOR_DEPTH          )
  ) u_memory_controller (.*);
  //* ==========================================================


  //* ======================== Layer 1 =========================
  gat_conv1 #(
    .DATA_WIDTH         (DATA_WIDTH             ),
    .SM_DATA_WIDTH      (SM_DATA_WIDTH          ),
    .SM_SUM_DATA_WIDTH  (SM_SUM_DATA_WIDTH      ),
    .ALPHA_DATA_WIDTH   (ALPHA_DATA_WIDTH       ),
    .NEW_FEATURE_WIDTH  (NEW_FEATURE_WIDTH      ),

    .WH_DATA_WIDTH      (WH_DATA_WIDTH_CONV1    ),
    .DMVM_DATA_WIDTH    (DMVM_DATA_WIDTH_CONV1  ),

    .H_NUM_SPARSE_DATA  (H_NUM_SPARSE_DATA      ),
    .TOTAL_NODES        (TOTAL_NODES            ),
    .NUM_FEATURE_IN     (NUM_FEATURE_IN         ),
    .NUM_FEATURE_OUT    (NUM_FEATURE_OUT        ),
    .NUM_SUBGRAPHS      (NUM_SUBGRAPHS          ),
    .MAX_NODES          (MAX_NODES              ),

    .COEF_DEPTH         (COEF_DEPTH             ),
    .ALPHA_DEPTH        (ALPHA_DEPTH            ),
    .DIVIDEND_DEPTH     (DIVIDEND_DEPTH         ),
    .DIVISOR_DEPTH      (DIVISOR_DEPTH          )
  ) u_gat_conv1 (
    .clk                        (clk                              ),
    .rst_n                      (rst_n                            ),

    .gat_layer                  (gat_layer                        ),
    .gat_debug_1                (gat_debug_1                      ),
    .gat_debug_2                (gat_debug_2                      ),
    .gat_debug_3                (gat_debug_3                      ),

    .h_data_bram_dout           (h_data_bram_dout                 ),
    .h_data_bram_addrb          (h_data_bram_addrb_conv1          ),
    .h_data_bram_load_done      (h_data_bram_load_done            ),

    .h_node_info_bram_dout      (h_node_info_bram_dout            ),
    .h_node_info_bram_addrb     (h_node_info_bram_addrb_conv1     ),
    .h_node_info_bram_load_done (h_node_info_bram_load_done       ),

    .wgt_bram_dout              (wgt_bram_dout                    ),
    .wgt_bram_addrb             (wgt_bram_addrb_conv1             ),
    .wgt_bram_load_done         (wgt_bram_load_done               ),

    .wh_bram_din                (wh_bram_din_conv1                ),
    .wh_bram_ena                (wh_bram_ena_conv1                ),
    .wh_bram_addra              (wh_bram_addra_conv1              ),
    .wh_bram_addrb              (wh_bram_addrb_conv1              ),
    .wh_bram_dout               (wh_bram_dout                     ),

    .num_node_bram_din          (num_node_bram_din_conv1          ),
    .num_node_bram_ena          (num_node_bram_ena_conv1          ),
    .num_node_bram_addra        (num_node_bram_addra_conv1        ),
    .num_node_bram_addrb        (num_node_bram_addrb_conv1        ),
    .num_node_bram_doutb        (num_node_bram_doutb              ),
    .num_node_bram_addrc        (num_node_bram_addrc_conv1        ),
    .num_node_bram_doutc        (num_node_bram_doutc              ),

    .feat_bram_din              (feat_bram_din_conv1              ),
    .feat_bram_ena              (feat_bram_ena_conv1              ),
    .feat_bram_addra            (feat_bram_addra_conv1            ),

    .gat_ready                  (gat_ready_conv1                  )
  );
  //* ==========================================================


  //* ======================== Layer 2 =========================
  gat_conv2 #(
    .DATA_WIDTH         (DATA_WIDTH             ),
    .SM_DATA_WIDTH      (SM_DATA_WIDTH          ),
    .SM_SUM_DATA_WIDTH  (SM_SUM_DATA_WIDTH      ),
    .ALPHA_DATA_WIDTH   (ALPHA_DATA_WIDTH       ),
    .NEW_FEATURE_WIDTH  (NEW_FEATURE_WIDTH      ),

    .WH_DATA_WIDTH      (WH_DATA_WIDTH_CONV2    ),
    .DMVM_DATA_WIDTH    (DMVM_DATA_WIDTH_CONV2  ),

    .H_NUM_SPARSE_DATA  (H_NUM_SPARSE_DATA      ),
    .TOTAL_NODES        (TOTAL_NODES            ),
    .NUM_FEATURE_IN     (NUM_FEATURE_OUT        ),
    .NUM_FEATURE_OUT    (NUM_FEATURE_FINAL      ),
    .NUM_SUBGRAPHS      (NUM_SUBGRAPHS          ),
    .MAX_NODES          (MAX_NODES              ),

    .COEF_DEPTH         (COEF_DEPTH             ),
    .ALPHA_DEPTH        (ALPHA_DEPTH            ),
    .DIVIDEND_DEPTH     (DIVIDEND_DEPTH         ),
    .DIVISOR_DEPTH      (DIVISOR_DEPTH          )
  ) u_gat_conv2 (
    .clk                        (clk                              ),
    .rst_n                      (rst_n                            ),

    .gat_layer                  (gat_layer                        ),

    .h_data_bram_dout           (h_data_bram_dout                 ),
    .h_data_bram_addrb          (h_data_bram_addrb_conv2          ),
    .h_data_bram_load_done      (h_data_bram_load_done            ),

    .h_node_info_bram_dout      (h_node_info_bram_dout            ),
    .h_node_info_bram_addrb     (h_node_info_bram_addrb_conv2     ),
    .h_node_info_bram_load_done (h_node_info_bram_load_done       ),

    .wgt_bram_dout              (wgt_bram_dout                    ),
    .wgt_bram_addrb             (wgt_bram_addrb_conv2_raw         ),
    .wgt_bram_load_done         (wgt_bram_load_done               ),

    .wh_bram_din                (wh_bram_din_conv2                ),
    .wh_bram_ena                (wh_bram_ena_conv2                ),
    .wh_bram_addra              (wh_bram_addra_conv2              ),
    .wh_bram_addrb              (wh_bram_addrb_conv2              ),
    .wh_bram_dout               (wh_bram_dout                     ),

    .num_node_bram_din          (num_node_bram_din_conv2          ),
    .num_node_bram_ena          (num_node_bram_ena_conv2          ),
    .num_node_bram_addra        (num_node_bram_addra_conv2        ),
    .num_node_bram_addrb        (num_node_bram_addrb_conv2        ),
    .num_node_bram_doutb        (num_node_bram_doutb              ),
    .num_node_bram_addrc        (num_node_bram_addrc_conv2        ),
    .num_node_bram_doutc        (num_node_bram_doutc              ),

    .feat_bram_din              (feat_bram_din_conv2              ),
    .feat_bram_ena              (feat_bram_ena_conv2              ),
    .feat_bram_addra            (feat_bram_addra_conv2            ),

    .gat_ready                  (gat_ready_conv2                  )
  );
  //* ==========================================================
endmodule