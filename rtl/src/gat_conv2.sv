module gat_conv2 #(
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
  input                             clk                         ,
  input                             rst_n                       ,

  input   [H_DATA_WIDTH-1:0]        h_data_bram_dout            ,
  output  [H_DATA_ADDR_W-1:0]       h_data_bram_addrb           ,
  input                             h_data_bram_load_done       ,

  input   [NODE_INFO_WIDTH-1:0]     h_node_info_bram_dout       ,
  input   [NODE_INFO_WIDTH-1:0]     h_node_info_bram_dout_nxt   ,
  output  [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addrb      ,
  input                             h_node_info_bram_load_done  ,

  input   [DATA_WIDTH-1:0]          wgt_bram_dout               ,
  output  [WEIGHT_ADDR_W-1:0]       wgt_bram_addrb              ,
  input                             wgt_bram_load_done          ,

  input   [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addrb             ,
  output  [NEW_FEATURE_WIDTH-1:0]   feat_bram_dout              ,

  output  [WH_WIDTH-1:0]            wh_bram_din                 ,
  output                            wh_bram_ena                 ,
  output  [WH_ADDR_W-1:0]           wh_bram_addra               ,
  output  [WH_ADDR_W-1:0]           wh_bram_addrb               ,
  input   [WH_WIDTH-1:0]            wh_bram_dout                ,

  output  [NUM_NODE_WIDTH-1:0]      num_node_bram_din           ,
  output                            num_node_bram_ena           ,
  output  [NUM_NODE_ADDR_W-1:0]     num_node_bram_addra         ,
  output  [NUM_NODE_ADDR_W-1:0]     num_node_bram_addrb         ,
  input   [NUM_NODE_WIDTH-1:0]      num_node_bram_doutb         ,
  output  [NUM_NODE_ADDR_W-1:0]     num_node_bram_addrc         ,
  input   [NUM_NODE_WIDTH-1:0]      num_node_bram_doutc         ,

  output  [NEW_FEATURE_WIDTH-1:0]   feat_bram_din               ,
  output                            feat_bram_ena               ,
  output  [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addra             ,

  output                            gat_ready
);

  genvar i;

  //* ===================== FIFO Controller ====================
  logic   [DATA_WIDTH-1:0]          coef_ff_din                 ;
  logic                             coef_ff_wr_vld              ;
  logic   [DATA_WIDTH-1:0]          coef_ff_dout                ;
  logic                             coef_ff_rd_vld              ;
  logic                             coef_ff_empty               ;
  logic                             coef_ff_full                ;

  logic   [ALPHA_DATA_WIDTH-1:0]    alpha_ff_din                ;
  logic                             alpha_ff_wr_vld             ;
  logic   [ALPHA_DATA_WIDTH-1:0]    alpha_ff_dout               ;
  logic                             alpha_ff_rd_vld             ;
  logic                             alpha_ff_empty              ;
  logic                             alpha_ff_full               ;

  FIFO #(
    .DATA_WIDTH (DATA_WIDTH         ),
    .FIFO_DEPTH (COEF_DEPTH         )
  ) u_coef_fifo (
    .clk        (clk                ),
    .rst_n      (rst_n              ),
    .din        (coef_ff_din        ),
    .wr_vld     (coef_ff_wr_vld     ),
    .full       (coef_ff_full       ),
    .empty      (coef_ff_empty      ),
    .dout       (coef_ff_dout       ),
    .rd_vld     (coef_ff_rd_vld     )
  );

  FIFO #(
    .DATA_WIDTH (ALPHA_DATA_WIDTH       ),
    .FIFO_DEPTH (ALPHA_DEPTH            )
  ) u_alpha_fifo (
    .clk        (clk                    ),
    .rst_n      (rst_n                  ),
    .din        (alpha_ff_din           ),
    .dout       (alpha_ff_dout          ),
    .wr_vld     (alpha_ff_wr_vld        ),
    .rd_vld     (alpha_ff_rd_vld        ),
    .empty      (alpha_ff_empty         ),
    .full       (alpha_ff_full          )
  );
  //* ==========================================================


  //* ======================= Scheduler ========================
  logic [W_NUM_OF_COLS-1:0] [W_NUM_OF_ROWS-1:0] [DATA_WIDTH-1:0]  wgt     ;
  logic [A_DEPTH-1:0] [DATA_WIDTH-1:0]                            a       ;
  logic                                                           w_rdy   ;

  scheduler_conv2 #(
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
  ) u_scheduler (
    .clk                        (clk                        ),
    .rst_n                      (rst_n                      ),

    .w_vld_i                    (wgt_bram_load_done         ),
    .wgt_bram_dout              (wgt_bram_dout              ),
    .wgt_bram_addrb             (wgt_bram_addrb             ),
    .wgt_bram_load_done         (wgt_bram_load_done         ),

    .wgt_o                      (wgt                        ),
    .a_o                        (a                          ),
    .w_rdy_o                    (w_rdy                      )

  );
  //* ==========================================================


  //* ========================== SPMM ==========================
  logic                       wh_vld    ;
  logic                       wh_rdy    ;
  
  logic [WH_WIDTH-1:0]        wh_data   ;

  assign wh_vld = w_rdy;

  WH #(
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
  ) u_WH (
    .clk                  (clk                    ),
    .rst_n                (rst_n                  ),

    .wh_vld_i             (wh_vld_i               ),
    .wh_rdy_o             (wh_rdy_o               ),

    .num_node_bram_dout   (num_node_bram_dout     ),
    .num_node_bram_addrb  (num_node_bram_addrb    ),

    .h_data_bram_dout     (h_data_bram_dout       ),
    .h_data_bram_addrb    (h_data_bram_addrb      ),

    .wgt                  (wgt                    ),

    .wh_data_o            (wh_data                ),
    .wh_bram_din          (wh_bram_din            ),
    .wh_bram_ena          (wh_bram_ena            ),
    .wh_bram_addra        (wh_bram_addra          )
  );
  //* ==========================================================


  //* ========================== DMVM ==========================
  logic dmvm_rdy;

  DMVM #(
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
  ) u_DMVM (
    .clk                (clk                  ),
    .rst_n              (rst_n                ),

    .dmvm_vld_i         (spmm_rdy             ),
    .dmvm_rdy_o         (dmvm_rdy             ),

    .a_vld_i            (w_rdy                ),
    .a_i                (a                    ),

    .wh_data_i          (wh_data              ),

    .coef_ff_din        (coef_ff_din          ),
    .coef_ff_wr_vld     (coef_ff_wr_vld       ),
    .coef_ff_full       (coef_ff_full         )
  );
  //* ==========================================================


  //* ======================== Softmax =========================
  logic sm_rdy;

  softmax #(
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
  ) u_softmax (
    .clk                  (clk                    ),
    .rst_n                (rst_n                  ),

    .sm_vld_i             (dmvm_rdy               ),
    .sm_rdy_o             (sm_rdy                 ),

    .coef_ff_dout         (coef_ff_dout           ),
    .coef_ff_empty        (coef_ff_empty          ),
    .coef_ff_rd_vld       (coef_ff_rd_vld         ),

    .num_node_bram_dout   (num_node_bram_doutb    ),
    .num_node_bram_addrb  (num_node_bram_addrb    ),

    .alpha_ff_din         (alpha_ff_din           ),
    .alpha_ff_full        (alpha_ff_full          ),
    .alpha_ff_wr_vld      (alpha_ff_wr_vld        )
  );
  //* ==========================================================


  //* ======================= Aggregator =======================
  logic aggr_rdy;
  logic aggr_vld;
  logic aggr_vld_reg;

  assign aggr_vld = (sm_rdy == 1'b1) ? 1'b1 : aggr_vld_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      aggr_vld_reg <= 0;
    end else begin
      aggr_vld_reg <= aggr_vld;
    end
  end

  aggregator #(
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
  ) u_aggregator (
    .clk                  (clk                      ),
    .rst_n                (rst_n                    ),

    .aggr_vld_i           (aggr_vld_reg             ),
    .aggr_rdy_o           (aggr_rdy                 ),

    .wh_bram_dout         (wh_bram_dout             ),
    .wh_bram_addrb        (wh_bram_addrb            ),

    .alpha_ff_dout        (alpha_ff_dout            ),
    .alpha_ff_empty       (alpha_ff_empty           ),
    .alpha_ff_rd_vld      (alpha_ff_rd_vld          ),

    .feat_bram_addra      (feat_bram_addra          ),
    .feat_bram_din        (feat_bram_din            ),
    .feat_bram_ena        (feat_bram_ena            ),

    .gat_ready            (gat_ready                )
  );
  //* ==========================================================
endmodule