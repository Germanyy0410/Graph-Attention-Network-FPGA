`timescale 1ns / 1ps

module WH_tb #(
  //* ======================= parameter ========================
  parameter DATA_WIDTH            = 8,
  parameter WH_DATA_WIDTH         = 12,
  parameter DMVM_DATA_WIDTH       = 19,
  parameter SM_DATA_WIDTH         = 108,
  parameter SM_SUM_DATA_WIDTH     = 108,
  parameter ALPHA_DATA_WIDTH      = 32,
  parameter NEW_FEATURE_WIDTH     = WH_DATA_WIDTH + 32,

  parameter H_NUM_SPARSE_DATA     = 140,
  parameter TOTAL_NODES           = 20,
  parameter NUM_FEATURE_IN        = 16,
  parameter NUM_FEATURE_OUT       = 7,
  parameter NUM_SUBGRAPHS         = 5,
  parameter MAX_NODES             = 9,

  parameter COEF_DEPTH            = 50,
  parameter ALPHA_DEPTH           = 50,
  parameter DIVIDEND_DEPTH        = 50,
  parameter DIVISOR_DEPTH         = 50,
  //* ==========================================================

  //* ======================= localparams ======================
  // -- [brams] Depth
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
);

  logic                                                             clk                       ;
  logic                                                             rst_n                     ;

  logic                                                             spmm_vld_i                ;
  logic                                                             spmm_rdy_o                ;

  // -- Num Node
  logic [NUM_NODE_WIDTH-1:0]                                        num_node_bram_din         ;
  logic [NUM_NODE_ADDR_W-1:0]                                       num_node_bram_addra       ;
  logic                                                             num_node_bram_ena         ;
  logic                                                             num_node_bram_wea         ;
  logic [NUM_NODE_WIDTH-1:0]                                        num_node_bram_dout        ;
  logic [NUM_NODE_ADDR_W-1:0]                                       num_node_bram_addrb       ;

  // -- Feature
  logic [H_DATA_WIDTH-1:0]                                          h_data_bram_din           ;
  logic [H_DATA_ADDR_W-1:0]                                         h_data_bram_addra         ;
  logic                                                             h_data_bram_ena           ;
  logic                                                             h_data_bram_wea           ;
  logic [H_DATA_WIDTH-1:0]                                          h_data_bram_dout          ;
  logic [H_DATA_ADDR_W-1:0]                                         h_data_bram_addrb         ;

  // -- Weight
  logic [W_NUM_OF_COLS-1:0] [W_NUM_OF_ROWS-1:0] [DATA_WIDTH-1:0]    wgt                       ;

  // -- DMVM
  logic [WH_WIDTH-1:0]                                              wh_data_o                 ;

  logic [WH_WIDTH-1:0]                                              wh_bram_din               ;
  logic                                                             wh_bram_ena               ;
  logic [WH_ADDR_W-1:0]                                             wh_bram_addra             ;

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
  ) u_WH (.*);

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

  BRAM #(
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
    .dout         (num_node_bram_dout   )
  );

  always #10 clk = ~clk;
  initial begin
    clk   = 1'b1;
    rst_n = 1'b0;
    #10.01;
    rst_n = 1'b1;
  end

  initial begin
    spmm_vld_i = 1'b0;

    for (int i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      for (int j = 0; j < W_NUM_OF_ROWS; j = j + 1) begin
        wgt[i][j] = j + 1;
      end
    end

    h_data_bram_ena = 1'b1;
    h_data_bram_wea = 1'b1;

    for (int i = 0; i < 20; i = i + 1) begin
      for (int j = 0; j < NUM_FEATURE_IN; j = j + 1) begin
        h_data_bram_din   = j;
        h_data_bram_addra = i*NUM_FEATURE_IN + j;
        #20.01;
      end
    end

    h_data_bram_ena = 1'b0;
    h_data_bram_wea = 1'b0;
    #20.01;

    num_node_bram_ena   = 1'b1;
    num_node_bram_wea   = 1'b1;
    num_node_bram_din   = 3;
    num_node_bram_addra = 0;
    #20.01;
    num_node_bram_din   = 4;
    num_node_bram_addra = 1;
    #20.01;
    num_node_bram_din   = 2;
    num_node_bram_addra = 2;
    #20.01;
    num_node_bram_din   = 9;
    num_node_bram_addra = 3;
    #20.01;
    num_node_bram_din   = 2;
    num_node_bram_addra = 4;
    #20.01;
    num_node_bram_ena   = 1'b0;
    num_node_bram_wea   = 1'b0;

    #20.01;
    spmm_vld_i = 1'b1;
  end
endmodule