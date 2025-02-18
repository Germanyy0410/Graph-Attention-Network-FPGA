module bram_controller #(
  //* ======================= parameter ========================
  parameter DATA_WIDTH            = 8,
  parameter WH_DATA_WIDTH         = 12,
  parameter DMVM_DATA_WIDTH       = 19,
  parameter SM_DATA_WIDTH         = 108,
  parameter SM_SUM_DATA_WIDTH     = 108,
  parameter ALPHA_DATA_WIDTH      = 32,
  parameter NEW_FEATURE_WIDTH     = WH_DATA_WIDTH + 32,

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

  input   [H_DATA_WIDTH-1:0]        h_data_bram_din             ,
  input                             h_data_bram_ena             ,
  input   [H_DATA_ADDR_W-1:0]       h_data_bram_addra           ,
  input   [H_DATA_ADDR_W-1:0]       h_data_bram_addrb           ,
  output  [H_DATA_WIDTH-1:0]        h_data_bram_dout            ,
  input                             h_data_bram_load_done       ,

  input   [NODE_INFO_WIDTH-1:0]     h_node_info_bram_din        ,
  input                             h_node_info_bram_ena        ,
  input   [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addra      ,
  input   [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addrb      ,
  output  [NODE_INFO_WIDTH-1:0]     h_node_info_bram_dout       ,
  output  [NODE_INFO_WIDTH-1:0]     h_node_info_bram_dout_nxt   ,
  input                             h_node_info_bram_load_done  ,

  input   [DATA_WIDTH-1:0]          wgt_bram_din                ,
  input                             wgt_bram_ena                ,
  input   [WEIGHT_ADDR_W-1:0]       wgt_bram_addra              ,
  input   [WEIGHT_ADDR_W-1:0]       wgt_bram_addrb              ,
  output  [DATA_WIDTH-1:0]          wgt_bram_dout               ,
  input                             wgt_bram_load_done          ,

  input   [DATA_WIDTH-1:0]          a_bram_din                  ,
  input                             a_bram_ena                  ,
  input   [A_ADDR_W-1:0]            a_bram_addra                ,
  input   [A_ADDR_W-1:0]            a_bram_addrb                ,
  output  [DATA_WIDTH-1:0]          a_bram_dout                 ,
  input                             a_bram_load_done            ,

  input   [WH_WIDTH-1:0]            wh_bram_din                 ,
  input                             wh_bram_ena                 ,
  input   [WH_ADDR_W-1:0]           wh_bram_addra               ,
  output  [WH_WIDTH-1:0]            wh_bram_dout                ,
  input   [WH_ADDR_W-1:0]           wh_bram_addrb               ,

  input   [NUM_NODE_WIDTH-1:0]      num_node_bram_din           ,
  input                             num_node_bram_ena           ,
  input   [NUM_NODE_ADDR_W-1:0]     num_node_bram_addra         ,
  input   [NUM_NODE_ADDR_W-1:0]     num_node_bram_addrb         ,
  output  [NUM_NODE_WIDTH-1:0]      num_node_bram_doutb         ,
  input   [NUM_NODE_ADDR_W-1:0]     num_node_bram_addrc         ,
  output  [NUM_NODE_WIDTH-1:0]      num_node_bram_doutc         ,

  input   [DATA_WIDTH-1:0]          feat_bram_din               ,
  input                             feat_bram_ena               ,
  input   [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addra             ,
  output  [DATA_WIDTH-1:0]          feat_bram_dout              ,
  input   [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addrb
);

  //* ========================= MEMORY =========================
  BRAM #(
    .DATA_WIDTH   (H_DATA_WIDTH         ),
    .DEPTH        (H_DATA_DEPTH         )
  ) u_h_data_bram (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (h_data_bram_din      ),
    .addra        (h_data_bram_addra    ),
    .ena          (h_data_bram_ena      ),
    .addrb        (h_data_bram_addrb    ),
    .dout         (h_data_bram_dout     )
  );

  modified_BRAM #(
    .DATA_WIDTH   (NODE_INFO_WIDTH            ),
    .DEPTH        (NODE_INFO_DEPTH            )
  ) u_h_node_info_bram (
    .clk          (clk                        ),
    .rst_n        (rst_n                      ),
    .din          (h_node_info_bram_din       ),
    .addra        (h_node_info_bram_addra     ),
    .ena          (h_node_info_bram_ena       ),
    .addrb        (h_node_info_bram_addrb     ),
    .dout         (h_node_info_bram_dout      ),
    .dout_nxt     (h_node_info_bram_dout_nxt  )
  );

  BRAM #(
    .DATA_WIDTH   (DATA_WIDTH           ),
    .DEPTH        (WEIGHT_DEPTH         )
  ) u_wgt_bram (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (wgt_bram_din         ),
    .addra        (wgt_bram_addra       ),
    .ena          (wgt_bram_ena         ),
    .addrb        (wgt_bram_addrb       ),
    .dout         (wgt_bram_dout        )
  );

  (* dont_touch = "true" *)
  BRAM #(
    .DATA_WIDTH   (WH_WIDTH             ),
    .DEPTH        (WH_DEPTH             )
  ) u_wh_bram (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (wh_bram_din          ),
    .addra        (wh_bram_addra        ),
    .ena          (wh_bram_ena          ),
    .addrb        (wh_bram_addrb        ),
    .dout         (wh_bram_dout         )
  );

  BRAM #(
    .DATA_WIDTH   (DATA_WIDTH           ),
    .DEPTH        (A_DEPTH              )
  ) u_a_bram (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (a_bram_din           ),
    .addra        (a_bram_addra         ),
    .ena          (a_bram_ena           ),
    .addrb        (a_bram_addrb         ),
    .dout         (a_bram_dout          )
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
    .addrb        (num_node_bram_addrb  ),
    .doutb        (num_node_bram_doutb  ),
    .addrc        (num_node_bram_addrc  ),
    .doutc        (num_node_bram_doutc  )
  );

  (* dont_touch = "true" *)
  BRAM #(
    .DATA_WIDTH     (NEW_FEATURE_WIDTH    ),
    .DEPTH          (NEW_FEATURE_DEPTH    )
  ) u_feat_bram (
    .clk            (clk                  ),
    .rst_n          (rst_n                ),
    .din            (feat_bram_din        ),
    .addra          (feat_bram_addra      ),
    .ena            (feat_bram_ena        ),
    .addrb          (feat_bram_addrb      ),
    .dout           (feat_bram_dout       )
  );
  //* ==========================================================
endmodule