// =============================================================
// File name  : softmax.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   :
// -- Calculate softmax algorithm: alpha = 2^e / sum(2^e)
// -- Pipeline stage = WOI + WOF + 3
// -- Fetch the attention coefficients from BRAM
// -- Store the normalized coefficients in BRAM
// Author     : @Germanyy0410
// =============================================================

module softmax #(
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
  localparam ZERO                 = 0,

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
  input                               clk                 ,
  input                               rst_n               ,

  input                               sm_vld_i            ,
  output                              sm_rdy_o            ,

  input   [DATA_WIDTH-1:0]            coef_ff_dout        ,
  input                               coef_ff_empty       ,
  output                              coef_ff_rd_vld      ,

  input   [NUM_NODE_WIDTH-1:0]        num_node_bram_dout  ,
  output  [NUM_NODE_ADDR_W-1:0]       num_node_bram_addrb ,

  output  [ALPHA_DATA_WIDTH-1:0]      alpha_ff_din        ,
  input                               alpha_ff_full       ,
  output                              alpha_ff_wr_vld
);

  logic                         sub_grph_done         ;
  logic                         div_sub_grph_done     ;
  logic                         coef_ff_empty_reg     ;
  logic                         sub_grph_div_ena      ;

  // -- handshake
  logic                         div_vld               ;
  logic                         div_rdy               ;

  // -- addr
  logic [NUM_NODE_ADDR_W-1:0]   addr                  ;
  logic [NUM_NODE_ADDR_W-1:0]   addr_reg              ;

  // -- sum
  logic [SM_DATA_WIDTH-1:0]     exp                   ;
  logic [SM_DATA_WIDTH-1:0]     exp_reg               ;
  logic [SM_SUM_DATA_WIDTH-1:0] sum                   ;
  logic [SM_SUM_DATA_WIDTH-1:0] sum_reg               ;
  logic [NUM_NODE_WIDTH-1:0]    node_cnt              ;
  logic [NUM_NODE_WIDTH-1:0]    node_cnt_reg          ;
  logic [NUM_NODE_WIDTH-1:0]    num_node              ;
  logic [NUM_NODE_WIDTH-1:0]    num_node_reg          ;

  // -- div
  logic [NUM_NODE_WIDTH-1:0]    div_node_cnt          ;
  logic [NUM_NODE_WIDTH-1:0]    div_node_cnt_reg      ;
  logic [NUM_NODE_WIDTH-1:0]    div_num_node          ;
  logic [NUM_NODE_WIDTH-1:0]    div_num_node_reg      ;


  logic [SM_DATA_WIDTH-1:0]     divd_ff_din           ;
  logic                         divd_ff_wr_vld        ;
  logic                         divd_ff_full          ;
  logic                         divd_ff_empty         ;
  logic [SM_DATA_WIDTH-1:0]     divd_ff_dout          ;
  logic                         divd_ff_rd_vld        ;
  logic [SM_DATA_WIDTH-1:0]     divd                  ;

  logic [DIVISOR_FF_WIDTH-1:0]  dvsr_ff_din           ;
  logic                         dvsr_ff_wr_vld        ;
  logic                         dvsr_ff_full          ;
  logic                         dvsr_ff_empty         ;
  logic [DIVISOR_FF_WIDTH-1:0]  dvsr_ff_dout          ;
  logic                         dvsr_ff_rd_vld        ;
  logic [SM_SUM_DATA_WIDTH-1:0] dvsr                  ;
  logic [SM_SUM_DATA_WIDTH-1:0] dvsr_reg              ;

  logic [ALPHA_DATA_WIDTH-1:0]  out                   ;

  FIFO #(
    .DATA_WIDTH (SM_DATA_WIDTH        ),
    .FIFO_DEPTH (DIVIDEND_DEPTH       )
  ) u_divd_fifo (
    .clk        (clk                  ),
    .rst_n      (rst_n                ),
    .din        (divd_ff_din          ),
    .wr_vld     (divd_ff_wr_vld       ),
    .full       (divd_ff_full         ),
    .empty      (divd_ff_empty        ),
    .dout       (divd_ff_dout         ),
    .rd_vld     (divd_ff_rd_vld       )
  );

  FIFO #(
    .DATA_WIDTH (DIVISOR_FF_WIDTH     ),
    .FIFO_DEPTH (DIVISOR_DEPTH        )
  ) u_dvsr_fifo (
    .clk        (clk                  ),
    .rst_n      (rst_n                ),
    .din        (dvsr_ff_din          ),
    .wr_vld     (dvsr_ff_wr_vld       ),
    .full       (dvsr_ff_full         ),
    .empty      (dvsr_ff_empty        ),
    .dout       (dvsr_ff_dout         ),
    .rd_vld     (dvsr_ff_rd_vld       )
  );

  always @(posedge clk) begin
    coef_ff_empty_reg <= coef_ff_empty;
  end

  assign sub_grph_done        = (node_cnt_reg == 0);
  assign div_sub_grph_done    = (div_node_cnt_reg == 0);
  assign sub_grph_div_ena     = (!divd_ff_empty) && ((!dvsr_ff_empty) && (div_node_cnt_reg == 0) || div_node_cnt_reg != 0);

  //* ======================== exp & sum ==========================
  // -- coef from ff
  assign coef_ff_rd_vld   = (!coef_ff_empty) && sm_vld_i;

  // -- num_node from bram
  assign num_node_bram_addrb  = addr_reg;
  assign num_node             = sub_grph_done ? num_node_bram_dout : num_node_reg;

  assign addr = (sub_grph_done && sm_vld_i && coef_ff_rd_vld) ? (addr_reg + 1) : addr_reg;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      addr_reg <= 'b0;
    end else begin
      addr_reg <= addr;
    end
  end

  // -- compute 2^x
  assign exp = (coef_ff_dout == ZERO) ? 1 : (1 << coef_ff_dout);

  always @(*) begin
    sum       = sum_reg;
    node_cnt  = node_cnt_reg;

    if (coef_ff_rd_vld) begin
      if (node_cnt_reg == num_node_reg - 1) begin
        node_cnt  = '0;
      end else begin
        node_cnt  = node_cnt_reg + 1;
      end

      if (node_cnt_reg == 0) begin
        sum = exp;
      end else begin
        sum = sum_reg + exp;
      end
    end else begin
      if (node_cnt_reg == 0) begin
        sum = '0;
      end
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      exp_reg       <= 'b0;
      sum_reg       <= 'b0;
      num_node_reg  <= 'b0;
      node_cnt_reg  <= 'b0;
    end else begin
      exp_reg       <= exp;
      sum_reg       <= sum;
      num_node_reg  <= num_node;
      node_cnt_reg  <= node_cnt;
    end
  end
  //* ==============================================================


  //* ====================== push data to ff =======================
  // -- divd
  assign divd_ff_din    = exp;
  assign divd_ff_wr_vld = coef_ff_rd_vld && (!divd_ff_full);

  // -- dvsr
  assign dvsr_ff_din     = { num_node_reg, sum_reg };
  assign dvsr_ff_wr_vld  = sub_grph_done && (!dvsr_ff_full) && (sum_reg != 0) && (!coef_ff_empty_reg);
  //* ==============================================================


  //* ====================== get data from ff ======================
  // -- divd
  assign divd_ff_rd_vld   = sub_grph_div_ena && (!divd_ff_empty);
  assign divd             = divd_ff_dout;

  // -- dvsr
  assign dvsr_ff_rd_vld           = div_sub_grph_done && (!dvsr_ff_empty);
  assign { div_num_node, dvsr }   = dvsr_ff_rd_vld ? dvsr_ff_dout : { div_num_node_reg, dvsr_reg };

  // -- vld signal
  assign div_vld = sub_grph_div_ena;

// -- node counter
  always @(*) begin
    div_node_cnt = div_node_cnt_reg;
    if (sub_grph_div_ena) begin
      if (div_node_cnt_reg == div_num_node_reg - 1) begin
        div_node_cnt = '0;
      end else begin
        div_node_cnt = div_node_cnt_reg + 1;
      end
    end else begin
      div_node_cnt = '0;
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      div_node_cnt_reg  <= 'b0;
      div_num_node_reg  <= 'b0;
      dvsr_reg          <= 'b0;
    end else begin
      div_node_cnt_reg  <= div_node_cnt;
      div_num_node_reg  <= div_num_node;
      dvsr_reg          <= dvsr;
    end
  end

  fxp_div_pipe #(
    .WIIA     (SM_DATA_WIDTH      ),
    .WIFA     (0                  ),
    .WIIB     (SM_SUM_DATA_WIDTH  ),
    .WIFB     (0                  ),
    .WOI      (WOI                ),
    .WOF      (WOF                ),
    .ROUND    (0                  )
  ) u_fxp_div_pipe (
    .clk      (clk                ),
    .rstn     (rst_n              ),
    .vld      (div_vld            ),
    .dividend (divd               ),
    .divisor  (dvsr               ),
    .rdy      (div_rdy            ),
    .out      (out                )
  );
  //* ==============================================================

  assign alpha_ff_din     = out;
  assign alpha_ff_wr_vld  = div_rdy && (!alpha_ff_full);
  assign sm_rdy_o         = div_rdy && (!alpha_ff_full);
endmodule