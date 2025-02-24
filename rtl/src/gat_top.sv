// ==================================================================
// File name  : gat_top.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   : Top module of the Acceleration Core
// Author     : @Germanyy0410
// ==================================================================

`include "../inc/gat_define.sv"

module gat_top #(
  //* ======================= parameter ========================
  parameter DATA_WIDTH            = 8,
  parameter WH_DATA_WIDTH         = 12,
  parameter DMVM_DATA_WIDTH       = 20,
  parameter SM_DATA_WIDTH         = 108,
  parameter SM_SUM_DATA_WIDTH     = 108,
  parameter ALPHA_DATA_WIDTH      = 32,
  parameter NEW_FEATURE_WIDTH     = WH_DATA_WIDTH + 32,

`ifdef TESTBENCH
  parameter H_NUM_SPARSE_DATA     = 557,
  parameter TOTAL_NODES           = 100,
  parameter NUM_FEATURE_IN        = 11,
  parameter NUM_FEATURE_OUT       = 16,
  parameter NUM_FEATURE_FINAL     = 7,
  parameter NUM_SUBGRAPHS         = 26,
  parameter MAX_NODES             = 6,

`elsif CORA
  parameter H_NUM_SPARSE_DATA     = 242101,
  parameter TOTAL_NODES           = 13264,
  parameter NUM_FEATURE_IN        = 1433,
  parameter NUM_FEATURE_OUT       = 16,
  parameter NUM_FEATURE_FINAL     = 7,
  parameter NUM_SUBGRAPHS         = 2708,
  parameter MAX_NODES             = 169,

`elsif CITESEER
  parameter H_NUM_SPARSE_DATA     = 399058,
  parameter TOTAL_NODES           = 12383,
  parameter NUM_FEATURE_IN        = 3703,
  parameter NUM_FEATURE_OUT       = 16,
  parameter NUM_FEATURE_FINAL     = 6,
  parameter NUM_SUBGRAPHS         = 3327,
  parameter MAX_NODES             = 100,

`elsif PUBMED
  parameter H_NUM_SPARSE_DATA     = 557,
  parameter TOTAL_NODES           = 100,
  parameter NUM_FEATURE_IN        = 11,
  parameter NUM_FEATURE_OUT       = 16,
  parameter NUM_FEATURE_FINAL     = 3,
  parameter NUM_SUBGRAPHS         = 26,
  parameter MAX_NODES             = 6,
`endif

  parameter COEF_DEPTH            = 500,
  parameter ALPHA_DEPTH           = 500,
  parameter DIVIDEND_DEPTH        = 500,
  parameter DIVISOR_DEPTH         = 500,
  //* ==========================================================

  //* ======================= localparams ======================
  // -- [brams] Depth
  localparam H_DATA_DEPTH         = H_NUM_SPARSE_DATA,
  localparam NODE_INFO_DEPTH      = TOTAL_NODES,
  localparam WEIGHT_DEPTH         = NUM_FEATURE_OUT * NUM_FEATURE_IN,
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
  localparam WH_RESULT_WIDTH      = WH_DATA_WIDTH * W_NUM_OF_COLS,
  localparam WH_WIDTH             = WH_DATA_WIDTH * W_NUM_OF_COLS + NUM_NODE_WIDTH + FLAG_WIDTH,

  // -- [a]
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

  // -- [Softmax]
  localparam SOFTMAX_WIDTH        = MAX_NODES * DATA_WIDTH + NUM_NODE_WIDTH,
  localparam SOFTMAX_DEPTH        = NUM_SUBGRAPHS,
  localparam SOFTMAX_ADDR_W       = $clog2(SOFTMAX_DEPTH),
  localparam WOI                  = 1,
  localparam WOF                  = ALPHA_DATA_WIDTH - WOI,
  localparam DL_DATA_WIDTH        = $clog2(WOI + WOF + 3) + 1,
  localparam DIVISOR_FF_WIDTH     = NUM_NODE_WIDTH + SM_SUM_DATA_WIDTH,

  // -- [Aggregator]
  localparam AGGR_WIDTH           = MAX_NODES * ALPHA_DATA_WIDTH + NUM_NODE_WIDTH,
  localparam AGGR_DEPTH           = NUM_SUBGRAPHS,
  localparam AGGR_ADDR_W          = $clog2(AGGR_DEPTH),
  localparam AGGR_MULT_W          = WH_DATA_WIDTH + 32,

  // -- [New Feature]
  localparam NEW_FEATURE_ADDR_W   = $clog2(NEW_FEATURE_DEPTH)
  //* ==========================================================
)(
  input                             clk                         ,
  input                             rst_n                       ,

  input                             gat_layer                   ,
  output                            gat_ready                   ,
  input                             h_data_bram_load_done       ,
  input                             h_node_info_bram_load_done  ,
  input                             a_bram_load_done            ,
  input                             wgt_bram_load_done          ,

  input   [H_DATA_WIDTH-1:0]        h_data_bram_din             ,
  input                             h_data_bram_ena             ,
  input   [H_DATA_ADDR_W-1:0]       h_data_bram_addra           ,

  input   [NODE_INFO_WIDTH-1:0]     h_node_info_bram_din        ,
  input                             h_node_info_bram_ena        ,
  input   [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addra      ,

  input   [DATA_WIDTH-1:0]          wgt_bram_din                ,
  input                             wgt_bram_ena                ,
  input   [WEIGHT_ADDR_W-1:0]       wgt_bram_addra              ,

  input   [DATA_WIDTH-1:0]          a_bram_din                  ,
  input                             a_bram_ena                  ,
  input   [A_ADDR_W-1:0]            a_bram_addra                ,

  input   [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addrb             ,
  output  [NEW_FEATURE_WIDTH-1:0]   feat_bram_dout
);

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
  logic [NODE_INFO_WIDTH-1:0]     h_node_info_bram_dout_nxt     ;

  logic [WEIGHT_ADDR_W-1:0]       wgt_bram_addrb                ;
  logic [WEIGHT_ADDR_W-1:0]       wgt_bram_addrb_conv1          ;
  logic [WEIGHT_ADDR_W-1:0]       wgt_bram_addrb_conv2          ;
  logic [DATA_WIDTH-1:0]          wgt_bram_dout                 ;

  logic [A_ADDR_W-1:0]            a_bram_addrb                  ;
  logic [A_ADDR_W-1:0]            a_bram_addrb_conv1            ;
  logic [A_ADDR_W-1:0]            a_bram_addrb_conv2            ;
  logic [DATA_WIDTH-1:0]          a_bram_dout                   ;

  // -- Output
  logic [WH_WIDTH-1:0]            wh_bram_dout                  ;
  logic [NUM_NODE_WIDTH-1:0]      num_node_bram_doutb           ;
  logic [NUM_NODE_WIDTH-1:0]      num_node_bram_doutc           ;
  logic [DATA_WIDTH-1:0]          feat_bram_dout                ;

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

  logic [DATA_WIDTH-1:0]          feat_bram_din_conv1           ;
  logic                           feat_bram_ena_conv1           ;
  logic [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addra_conv1         ;
  logic [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addrb_conv1         ;

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

  logic [DATA_WIDTH-1:0]          feat_bram_din_conv2           ;
  logic                           feat_bram_ena_conv2           ;
  logic [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addra_conv2         ;
  logic [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addrb_conv2         ;
  //* ==========================================================


  //* ==================== Memory Controller ===================
  memory_controller #(
    .DATA_WIDTH         (DATA_WIDTH         ),
    .WH_DATA_WIDTH      (WH_DATA_WIDTH      ),
    .DMVM_DATA_WIDTH    (DMVM_DATA_WIDTH    ),
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
  ) u_memory_controller (.*);
  //* ==========================================================


  //* ======================== Layer 1 =========================
  gat_conv1 #(
    .DATA_WIDTH         (DATA_WIDTH         ),
    .WH_DATA_WIDTH      (WH_DATA_WIDTH      ),
    .DMVM_DATA_WIDTH    (DMVM_DATA_WIDTH    ),
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
  ) u_gat_conv1 (
    .clk                        (clk                              ),
    .rst_n                      (rst_n                            ),

    .h_data_bram_dout           (h_data_bram_dout                 ),
    .h_data_bram_addrb          (h_data_bram_addrb_conv1          ),
    .h_data_bram_load_done      (h_data_bram_load_done            ),

    .h_node_info_bram_dout      (h_node_info_bram_dout            ),
    .h_node_info_bram_dout_nxt  (h_node_info_bram_dout_nxt        ),
    .h_node_info_bram_addrb     (h_node_info_bram_addrb_conv1     ),
    .h_node_info_bram_load_done (h_node_info_bram_load_done       ),

    .wgt_bram_dout              (wgt_bram_dout                    ),
    .wgt_bram_addrb             (wgt_bram_addrb_conv1             ),
    .wgt_bram_load_done         (wgt_bram_load_done               ),

    .a_bram_dout                (a_bram_dout                      ),
    .a_bram_addrb               (a_bram_addrb_conv1               ),
    .a_bram_load_done           (a_bram_load_done                 ),

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
    .feat_bram_addrb            (feat_bram_addrb_conv1            ),
    .feat_bram_dout             (feat_bram_dout                   )
  );
  //* ==========================================================


  //* ======================== Layer 2 =========================
  gat_conv2 #(
    .DATA_WIDTH         (DATA_WIDTH         ),
    .WH_DATA_WIDTH      (WH_DATA_WIDTH      ),
    .DMVM_DATA_WIDTH    (DMVM_DATA_WIDTH    ),
    .SM_DATA_WIDTH      (SM_DATA_WIDTH      ),
    .SM_SUM_DATA_WIDTH  (SM_SUM_DATA_WIDTH  ),
    .ALPHA_DATA_WIDTH   (ALPHA_DATA_WIDTH   ),
    .NEW_FEATURE_WIDTH  (NEW_FEATURE_WIDTH  ),

    .H_NUM_SPARSE_DATA  (H_NUM_SPARSE_DATA  ),
    .TOTAL_NODES        (TOTAL_NODES        ),
    .NUM_FEATURE_IN     (NUM_FEATURE_OUT    ),
    .NUM_FEATURE_OUT    (NUM_FEATURE_FINAL  ),
    .NUM_SUBGRAPHS      (NUM_SUBGRAPHS      ),
    .MAX_NODES          (MAX_NODES          ),

    .COEF_DEPTH         (COEF_DEPTH         ),
    .ALPHA_DEPTH        (ALPHA_DEPTH        ),
    .DIVIDEND_DEPTH     (DIVIDEND_DEPTH     ),
    .DIVISOR_DEPTH      (DIVISOR_DEPTH      )
  ) u_gat_conv2 (
    .clk                        (clk                              ),
    .rst_n                      (rst_n                            ),

    .h_data_bram_dout           (h_data_bram_dout                 ),
    .h_data_bram_addrb          (h_data_bram_addrb_conv2          ),
    .h_data_bram_load_done      (h_data_bram_load_done            ),

    .h_node_info_bram_dout      (h_node_info_bram_dout            ),
    .h_node_info_bram_dout_nxt  (h_node_info_bram_dout_nxt        ),
    .h_node_info_bram_addrb     (h_node_info_bram_addrb_conv2     ),
    .h_node_info_bram_load_done (h_node_info_bram_load_done       ),

    .wgt_bram_dout              (wgt_bram_dout                    ),
    .wgt_bram_addrb             (wgt_bram_addrb_conv2             ),
    .wgt_bram_load_done         (wgt_bram_load_done               ),
    .a_bram_dout                (a_bram_dout                      ),
    .a_bram_addrb               (a_bram_addrb_conv2               ),
    .a_bram_load_done           (a_bram_load_done                 ),

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
    .feat_bram_addrb            (feat_bram_addrb_conv2            ),
    .feat_bram_dout             (feat_bram_dout                   )
  );
  //* ==========================================================
endmodule