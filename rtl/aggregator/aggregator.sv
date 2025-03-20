// ====================================================================
// File name  : aggregator.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   :
// -- Compute the new Feature vector: H = ReLU[sum(alpha x Wh)]
// -- Pipeline stage = 2
// -- Fetch Wh vectors and coefficients from BRAM
// -- Store new Feature vector in BRAM
// Author     : @Germanyy0410
// ====================================================================

module aggregator #(
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
  input                                               clk                 ,
  input                                               rst_n               ,

  input                                               aggr_vld_i          ,
  output                                              aggr_rdy_o          ,

  // -- WH
  input   [WH_WIDTH-1:0]                              wh_bram_dout        ,
  output  [WH_ADDR_W-1:0]                             wh_bram_addrb       ,

  // -- alpha
  input   [ALPHA_DATA_WIDTH-1:0]                      alpha_ff_dout       ,
  input                                               alpha_ff_empty      ,
  output                                              alpha_ff_rd_vld     ,

  // -- new features
  output logic [NEW_FEATURE_ADDR_W-1:0]               feat_bram_addra     ,
  output logic [NEW_FEATURE_WIDTH-1:0]                feat_bram_din       ,
  output logic                                        feat_bram_ena       ,

  output                                              gat_ready
);


  //* ============== logic declaration ==============
  logic [ALPHA_DATA_WIDTH-1:0]                        alpha               ;
  logic [ALPHA_DATA_WIDTH-1:0]                        alpha_reg           ;

  logic [WH_ADDR_W-1:0]                               wh_addr             ;
  logic [WH_ADDR_W-1:0]                               wh_addr_reg         ;
  logic [NUM_FEATURE_OUT-1:0] [WH_DATA_WIDTH-1:0]     wh_dout             ;
  logic [NUM_FEATURE_OUT-1:0] [WH_DATA_WIDTH-1:0]     wh_dout_reg         ;
  logic [NUM_NODE_WIDTH-1:0]                          wh_num_node         ;
  logic                                               src_flag            ;

  logic [NUM_NODE_WIDTH-1:0]                          num_node            ;
  logic [NUM_NODE_WIDTH-1:0]                          num_node_reg        ;
  logic [NUM_NODE_WIDTH-1:0]                          cnt                 ;
  logic [NUM_NODE_WIDTH-1:0]                          cnt_reg             ;

  logic                                               mul_vld             ;
  logic                                               mul_vld_reg         ;
  logic [NUM_FEATURE_OUT-1:0]                         mul_rdy             ;
  logic [NUM_FEATURE_OUT-1:0] [NEW_FEATURE_WIDTH:0]   prod                ;
  logic [NUM_FEATURE_OUT-1:0] [NEW_FEATURE_WIDTH:0]   res                 ;
  logic [NUM_FEATURE_OUT-1:0] [NEW_FEATURE_WIDTH:0]   res_reg             ;

  logic [NUM_FEATURE_OUT-1:0] [NEW_FEATURE_WIDTH-1:0] new_feat            ;
  logic [NUM_NODE_WIDTH-1:0]                          num_node_out        ;
  logic [NUM_NODE_WIDTH-1:0]                          num_node_out_reg    ;

  logic                                               new_feat_ena        ;
  //* ===============================================

  genvar i;

  //* =========== read data from WH bram ============
  assign wh_bram_addrb                      = wh_addr_reg;
  assign { wh_dout, wh_num_node, src_flag } = wh_bram_dout;

  assign wh_addr  = (alpha_ff_rd_vld) ? (wh_addr_reg + 1'b1) : wh_addr_reg;
  assign num_node = (src_flag) ? wh_num_node : num_node_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wh_addr_reg   <= 'b0;
      wh_dout_reg   <= 'b0;
      num_node_reg  <= 'b0;
    end else begin
      wh_addr_reg   <= wh_addr;
      wh_dout_reg   <= wh_dout;
      num_node_reg  <= num_node;
    end
  end
  //* ==============================================


  //* ========= read data from Alpha ff ==========
  assign alpha_ff_rd_vld = (!alpha_ff_empty);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      alpha     <= 'b0;
      alpha_reg <= 'b0;
    end else begin
      alpha     <= alpha_ff_dout;
      alpha_reg <= alpha;
    end
  end
  //* ==============================================


  //* ============= main calculation ===============
  always_comb begin
    cnt = cnt_reg;
    if (&mul_rdy) begin
      if (cnt_reg < num_node_out_reg - 1) begin
        cnt = cnt_reg + 1;
      end else begin
        cnt = '0;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mul_vld     <= 'b0;
      mul_vld_reg <= 'b0;
    end else begin
      mul_vld     <= alpha_ff_rd_vld;
      mul_vld_reg <= mul_vld;
    end
  end

  // -- Multiplication
  generate
    for (i = 0; i < NUM_FEATURE_OUT; i = i + 1) begin
      fxp_mul_pipe #(
        .WIIA   (WH_DATA_WIDTH    ),
        .WIFA   (0                ),
        .WIIB   (WOI              ),
        .WIFB   (WOF              ),
        .WOI    (17               ),
        .WOF    (16               ),
        .ROUND  (1                )
      ) u_mul_pipe (
        .clk    (clk              ),
        .rstn   (rst_n            ),
        .vld    (mul_vld_reg      ),
        .rdy    (mul_rdy[i]       ),
        .ina    (wh_dout_reg[i]   ),
        .inb    (alpha_reg        ),
        .out    (prod[i]          )
      );
    end
  endgenerate

  // -- Addition
  generate
    for (i = 0; i < NUM_FEATURE_OUT; i = i + 1) begin
      assign res[i] = (cnt_reg == 0) ? prod[i] : (prod[i] + res_reg[i]);
    end
  endgenerate

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      res_reg <= 'b0;
      cnt_reg <= 'b0;
    end else begin
      res_reg <= res;
      cnt_reg <= cnt;
    end
  end
  //* ==============================================


  //* ========== push data to feature bram =========
  generate
    for (i = 0; i < NUM_FEATURE_OUT; i = i + 1) begin
      assign new_feat[i] = (res_reg[i][NEW_FEATURE_WIDTH] == 1'b0) ? res_reg[i][NEW_FEATURE_WIDTH-1:0] : '0;
    end
  endgenerate

  assign num_node_out = ((cnt_reg == num_node_out_reg - 1) || (wh_bram_addrb == 1)) ? num_node_reg : num_node_out_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      num_node_out_reg <= 'b0;
      new_feat_ena     <= 'b0;
    end else begin
      num_node_out_reg <= num_node_out;
      new_feat_ena     <= (cnt_reg == num_node_out_reg - 1);
    end
  end

  feature_controller #(
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
  ) u_feature_controller (
    .clk                (clk                ),
    .rst_n              (rst_n              ),

    .new_feat           (new_feat           ),
    .new_feat_vld       (new_feat_ena       ),
    .new_feat_rdy       (aggr_rdy_o         ),

    .feat_bram_addra    (feat_bram_addra    ),
    .feat_bram_din      (feat_bram_din      ),
    .feat_bram_ena      (feat_bram_ena      ),

    .gat_ready          (gat_ready          )
  );
  //* ==============================================
endmodule

