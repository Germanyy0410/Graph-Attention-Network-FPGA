// ==================================================================
// File name  : memory_controller.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   :
// -- Main memory between PS and PL
// -- Manage the initialization of FIFO & BRAM
// Author     : @Germanyy0410
// ==================================================================

module memory_controller #(
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
  input                             clk                           ,
  input                             rst_n                         ,
  input                             gat_layer                     ,

  //* =========================== PS ===========================
  input   [H_DATA_WIDTH-1:0]        h_data_bram_din               ,
  input                             h_data_bram_ena               ,
  input                             h_data_bram_wea               ,
  input   [H_DATA_ADDR_W-1:0]       h_data_bram_addra             ,
  input                             h_data_bram_load_done         ,

  input   [NODE_INFO_WIDTH-1:0]     h_node_info_bram_din          ,
  input                             h_node_info_bram_ena          ,
  input                             h_node_info_bram_wea          ,
  input   [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addra        ,
  input                             h_node_info_bram_load_done    ,

  input   [DATA_WIDTH-1:0]          wgt_bram_din                  ,
  input                             wgt_bram_ena                  ,
  input                             wgt_bram_wea                  ,
  input   [WEIGHT_ADDR_W-1:0]       wgt_bram_addra                ,
  input                             wgt_bram_load_done            ,
  input   [WEIGHT_ADDR_W-1:0]       wgt_bram_addrc                ,
  output  [DATA_WIDTH-1:0]          wgt_bram_doutc                ,
  //* ==========================================================


  //* =========================== PL ===========================
  input   [H_DATA_ADDR_W-1:0]       h_data_bram_addrb_conv1       ,
  input   [H_DATA_ADDR_W-1:0]       h_data_bram_addrb_conv2       ,
  output  [H_DATA_WIDTH-1:0]        h_data_bram_dout              ,

  input   [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addrb_conv1  ,
  input   [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addrb_conv2  ,
  output  [NODE_INFO_WIDTH-1:0]     h_node_info_bram_dout         ,

  input   [WEIGHT_ADDR_W-1:0]       wgt_bram_addrb_conv1          ,
  input   [WEIGHT_ADDR_W-1:0]       wgt_bram_addrb_conv2          ,
  output  [DATA_WIDTH-1:0]          wgt_bram_dout                 ,
  //* ==========================================================


  output  [WH_WIDTH-1:0]            wh_bram_dout                  ,
  output  [NUM_NODE_WIDTH-1:0]      num_node_bram_doutb           ,
  output  [NUM_NODE_WIDTH-1:0]      num_node_bram_doutc           ,
  output  [NEW_FEATURE_WIDTH-1:0]   feat_bram_dout                ,


  //* ========================= Conv1 ==========================
  input   [WH_WIDTH-1:0]            wh_bram_din_conv1             ,
  input                             wh_bram_ena_conv1             ,
  input   [WH_ADDR_W-1:0]           wh_bram_addra_conv1           ,
  input   [WH_ADDR_W-1:0]           wh_bram_addrb_conv1           ,

  input   [NUM_NODE_WIDTH-1:0]      num_node_bram_din_conv1       ,
  input                             num_node_bram_ena_conv1       ,
  input   [NUM_NODE_ADDR_W-1:0]     num_node_bram_addra_conv1     ,
  input   [NUM_NODE_ADDR_W-1:0]     num_node_bram_addrb_conv1     ,
  input   [NUM_NODE_ADDR_W-1:0]     num_node_bram_addrc_conv1     ,

  input   [NEW_FEATURE_WIDTH-1:0]   feat_bram_din_conv1           ,
  input                             feat_bram_ena_conv1           ,
  input   [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addra_conv1         ,
  //* ==========================================================


  //* ========================= Conv2 ==========================
  input   [WH_WIDTH-1:0]            wh_bram_din_conv2             ,
  input                             wh_bram_ena_conv2             ,
  input   [WH_ADDR_W-1:0]           wh_bram_addra_conv2           ,
  input   [WH_ADDR_W-1:0]           wh_bram_addrb_conv2           ,

  input   [NUM_NODE_WIDTH-1:0]      num_node_bram_din_conv2       ,
  input                             num_node_bram_ena_conv2       ,
  input   [NUM_NODE_ADDR_W-1:0]     num_node_bram_addra_conv2     ,
  input   [NUM_NODE_ADDR_W-1:0]     num_node_bram_addrb_conv2     ,
  input   [NUM_NODE_ADDR_W-1:0]     num_node_bram_addrc_conv2     ,

  input   [NEW_FEATURE_WIDTH-1:0]   feat_bram_din_conv2           ,
  input                             feat_bram_ena_conv2           ,
  input   [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addra_conv2
  //* ==========================================================
);

  logic [H_DATA_ADDR_W-1:0]       h_data_bram_addrb       ;
  logic [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addrb  ;
  logic [WEIGHT_ADDR_W-1:0]       wgt_bram_addrb          ;

  logic [WH_WIDTH-1:0]            wh_bram_din             ;
  logic                           wh_bram_ena             ;
  logic [WH_ADDR_W-1:0]           wh_bram_addra           ;
  logic [WH_ADDR_W-1:0]           wh_bram_addrb           ;

  logic [NUM_NODE_WIDTH-1:0]      num_node_bram_din       ;
  logic                           num_node_bram_ena       ;
  logic [NUM_NODE_ADDR_W-1:0]     num_node_bram_addra     ;
  logic [NUM_NODE_ADDR_W-1:0]     num_node_bram_addrb     ;
  logic [NUM_NODE_ADDR_W-1:0]     num_node_bram_addrc     ;

  logic [NEW_FEATURE_WIDTH-1:0]   feat_bram_din           ;
  logic                           feat_bram_ena           ;
  logic [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addra         ;
  logic [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addrb         ;

  assign h_data_bram_addrb      = (gat_layer == 0) ? h_data_bram_addrb_conv1      : h_data_bram_addrb_conv2;
  assign h_node_info_bram_addrb = (gat_layer == 0) ? h_node_info_bram_addrb_conv1 : h_node_info_bram_addrb_conv2;
  assign wgt_bram_addrb         = (gat_layer == 0) ? wgt_bram_addrb_conv1         : wgt_bram_addrb_conv2;

  assign wh_bram_din            = (gat_layer == 0) ? wh_bram_din_conv1            : wh_bram_din_conv2;
  assign wh_bram_ena            = (gat_layer == 0) ? wh_bram_ena_conv1            : wh_bram_ena_conv2;
  assign wh_bram_addra          = (gat_layer == 0) ? wh_bram_addra_conv1          : wh_bram_addra_conv2;
  assign wh_bram_addrb          = (gat_layer == 0) ? wh_bram_addrb_conv1          : wh_bram_addrb_conv2;

  assign num_node_bram_din      = (gat_layer == 0) ? num_node_bram_din_conv1      : num_node_bram_din_conv2;
  assign num_node_bram_ena      = (gat_layer == 0) ? num_node_bram_ena_conv1      : num_node_bram_ena_conv2;
  assign num_node_bram_addra    = (gat_layer == 0) ? num_node_bram_addra_conv1    : num_node_bram_addra_conv2;
  assign num_node_bram_addrb    = (gat_layer == 0) ? num_node_bram_addrb_conv1    : num_node_bram_addrb_conv2;
  assign num_node_bram_addrc    = (gat_layer == 0) ? num_node_bram_addrc_conv1    : num_node_bram_addrc_conv2;

  assign feat_bram_din          = (gat_layer == 0) ? feat_bram_din_conv1          : feat_bram_din_conv2;
  assign feat_bram_ena          = (gat_layer == 0) ? feat_bram_ena_conv1          : feat_bram_ena_conv2;
  assign feat_bram_addra        = (gat_layer == 0) ? feat_bram_addra_conv1        : feat_bram_addra_conv2;

  //* ========================= MEMORY =========================
  (* dont_touch = "yes" *)
  BRAM #(
    .DATA_WIDTH   (H_DATA_WIDTH         ),
    .DEPTH        (H_DATA_DEPTH         )
  ) u_h_data_bram (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (h_data_bram_din      ),
    .addra        (h_data_bram_addra    ),
    .ena          (h_data_bram_ena      ),
    .wea          (h_data_bram_wea      ),
    .addrb        (h_data_bram_addrb    ),
    .dout         (h_data_bram_dout     )
  );

  (* dont_touch = "yes" *)
  BRAM #(
    .DATA_WIDTH   (NODE_INFO_WIDTH            ),
    .DEPTH        (NODE_INFO_DEPTH            )
  ) u_h_node_info_bram (
    .clk          (clk                        ),
    .rst_n        (rst_n                      ),
    .din          (h_node_info_bram_din       ),
    .addra        (h_node_info_bram_addra     ),
    .ena          (h_node_info_bram_ena       ),
    .wea          (h_node_info_bram_wea       ),
    .addrb        (h_node_info_bram_addrb     ),
    .dout         (h_node_info_bram_dout      )
  );

  (* dont_touch = "yes" *)
  dual_read_BRAM #(
    .DATA_WIDTH   (DATA_WIDTH           ),
    .DEPTH        (WEIGHT_DEPTH         )
  ) u_wgt_bram (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (wgt_bram_din         ),
    .addra        (wgt_bram_addra       ),
    .ena          (wgt_bram_ena         ),
    .wea          (wgt_bram_wea         ),
    .addrb        (wgt_bram_addrb       ),
    .doutb        (wgt_bram_dout        ),
    .addrc        (wgt_bram_addrc       ),
    .doutc        (wgt_bram_doutc       )
  );

  BRAM #(
    .DATA_WIDTH   (WH_WIDTH             ),
    .DEPTH        (WH_DEPTH             )
  ) u_wh_bram (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (wh_bram_din          ),
    .addra        (wh_bram_addra        ),
    .ena          (wh_bram_ena          ),
    .wea          (wh_bram_ena          ),
    .addrb        (wh_bram_addrb        ),
    .dout         (wh_bram_dout         )
  );

  dual_read_BRAM #(
    .DATA_WIDTH   (NUM_NODE_WIDTH       ),
    .DEPTH        (NUM_NODES_DEPTH      )
  ) u_num_node_bram (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (num_node_bram_din    ),
    .addra        (num_node_bram_addra  ),
    .ena          (num_node_bram_ena    ),
    .wea          (num_node_bram_ena    ),
    .addrb        (num_node_bram_addrb  ),
    .doutb        (num_node_bram_doutb  ),
    .addrc        (num_node_bram_addrc  ),
    .doutc        (num_node_bram_doutc  )
  );

  BRAM #(
    .DATA_WIDTH     (NEW_FEATURE_WIDTH    ),
    .DEPTH          (NEW_FEATURE_DEPTH    )
  ) u_feat_bram (
    .clk            (clk                  ),
    .rst_n          (rst_n                ),
    .din            (feat_bram_din        ),
    .addra          (feat_bram_addra      ),
    .ena            (feat_bram_ena        ),
    .wea            (feat_bram_ena        ),
    .addrb          (feat_bram_addrb      ),
    .dout           (feat_bram_dout       )
  );
  //* ==========================================================
endmodule