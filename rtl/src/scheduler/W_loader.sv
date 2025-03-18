//==================================================================
// File name  : W_loader.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   : Split each column of Weight into one BRAM
// Author     : @Germanyy0410
//==================================================================

module W_loader #(
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
  localparam WEIGHT_ADDR_W        = $clog2(WEIGHT_DEPTH) + $clog2(A_DEPTH),
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
  input                                                 clk                     ,
  input                                                 rst_n                   ,

  input                                                 w_vld_i                 ,
  output                                                w_rdy_o                 ,

  input   [DATA_WIDTH-1:0]                              wgt_bram_dout           ,
  output  [WEIGHT_ADDR_W-1:0]                           wgt_bram_addrb          ,

  output  [W_NUM_OF_COLS*DATA_WIDTH-1:0]                mult_wgt_dout_flat      ,
  input   [W_NUM_OF_COLS*MULT_WEIGHT_ADDR_W-1:0]        mult_wgt_addrb_flat     ,
  output  [A_DEPTH-1:0] [DATA_WIDTH-1:0]                a_o
);

  logic                                               w_rdy               ;
  logic                                               w_rdy_reg           ;

  logic [WEIGHT_ADDR_W:0]                             addr                ;

  logic [W_NUM_OF_COLS-1:0] [DATA_WIDTH-1:0]          mult_wgt_din        ;
  logic [W_NUM_OF_COLS-1:0] [MULT_WEIGHT_ADDR_W-1:0]  mult_wgt_addra      ;
  logic [W_NUM_OF_COLS-1:0]                           mult_wgt_ena        ;

  logic [WEIGHT_ADDR_W-1:0]                           addr_reg            ;
  logic [W_ROW_WIDTH-1:0]                             row_idx             ;
  logic [W_ROW_WIDTH-1:0]                             row_idx_reg         ;
  logic [W_COL_WIDTH-1:0]                             col_idx             ;
  logic [W_COL_WIDTH-1:0]                             col_idx_reg         ;
  logic                                               w_vld_q1            ;
  logic                                               w_vld_q2            ;

  logic [W_NUM_OF_COLS-1:0] [DATA_WIDTH-1:0]          mult_wgt_dout       ;
  logic [W_NUM_OF_COLS-1:0] [MULT_WEIGHT_ADDR_W-1:0]  mult_wgt_addrb      ;

  logic [A_INDEX_WIDTH:0]                             a_idx               ;
  logic [A_INDEX_WIDTH:0]                             a_idx_reg           ;
  logic [A_DEPTH-1:0] [DATA_WIDTH-1:0]                a                   ;
  logic [A_DEPTH-1:0] [DATA_WIDTH-1:0]                a_reg               ;
  logic                                               a_rdy               ;
  logic                                               a_rdy_reg           ;


  assign mult_wgt_dout_flat  = mult_wgt_dout;
  assign mult_wgt_addrb      = mult_wgt_addrb_flat;


  //* ================= internal declaration ==================
  genvar i, k;
  //* =========================================================


  //* ===================== bram instance =====================
  (* dont_touch = "yes" *)
  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      BRAM #(
        .DATA_WIDTH   (DATA_WIDTH         ),
        .DEPTH        (W_NUM_OF_ROWS      )
      ) u_mult_wgt_bram (
        .clk          (clk               ),
        .rst_n        (rst_n             ),
        .din          (mult_wgt_din[i]   ),
        .addra        (mult_wgt_addra[i] ),
        .ena          (mult_wgt_ena[i]   ),
        .wea          (mult_wgt_ena[i]   ),
        .addrb        (mult_wgt_addrb[i] ),
        .dout         (mult_wgt_dout[i]  )
      );
    end
  endgenerate
  //* =========================================================


  //* =================== output assignment ===================
  assign wgt_bram_addrb = addr_reg;
  assign w_rdy_o        = a_rdy_reg;
  assign a_o            = a_reg;
  //* =========================================================


  //* =============== 2 cycles delay from bram ================
  always @(posedge clk) begin
    w_vld_q1 <= w_vld_i;
    w_vld_q2 <= w_vld_q1;
  end
  //* =========================================================


  //* =============== Generate mul-weight bram ================
  always @(*) begin
    addr    = addr_reg;
    col_idx = col_idx_reg;
    row_idx = row_idx_reg;

    if (w_vld_i && addr_reg < W_NUM_OF_COLS * W_NUM_OF_ROWS + A_DEPTH) begin
      addr = addr_reg + 1;
    end

    if (w_vld_q1) begin
      if ((col_idx_reg == W_NUM_OF_COLS - 1)) begin
        col_idx = 0;
      end else begin
        col_idx = col_idx_reg + 1;
      end
    end

    if (w_vld_q1 && col_idx_reg == W_NUM_OF_COLS - 1) begin
      if (row_idx_reg == W_NUM_OF_ROWS - 1) begin
        row_idx = 0;
      end else begin
        row_idx = row_idx_reg + 1;
      end
    end
  end

  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      assign mult_wgt_addra[i] = row_idx_reg;
      assign mult_wgt_din[i]   = wgt_bram_dout;
      assign mult_wgt_ena[i]   = (i == col_idx_reg && ~w_rdy_reg) ? 1'b1 : 1'b0;
    end
  endgenerate

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      addr_reg    <= 'b0;
      row_idx_reg <= 'b0;
      col_idx_reg <= 'b0;
    end else begin
      addr_reg    <= addr;
      row_idx_reg <= row_idx;
      col_idx_reg <= col_idx;
    end
  end
  //* =========================================================


  //* ======================= [w_rdy] =========================
  assign w_rdy = (row_idx_reg == W_NUM_OF_ROWS - 1) && (col_idx_reg == W_NUM_OF_COLS - 1) ? 1'b1 : w_rdy_reg;

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      w_rdy_reg <= 'b0;
    end else begin
      w_rdy_reg <= w_rdy;
    end
  end
  //* =========================================================


  //* ========================= [a] ===========================
  assign a_idx = ((addr_reg > W_NUM_OF_COLS * W_NUM_OF_ROWS) && (a_idx_reg < A_DEPTH)) ? (a_idx_reg + 1) : a_idx_reg;
  assign a_rdy = ((a_idx_reg == A_DEPTH) && w_rdy_reg) ? 1'b1: a_rdy_reg;

  generate
    for (i = 0; i < A_DEPTH; i = i + 1) begin
      assign a[i] = (i == a_idx_reg) ? wgt_bram_dout : a_reg[i];
    end
  endgenerate

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      a_idx_reg <= 'b0;
      a_reg   <= 'b0;
      a_rdy_reg <= 'b0;
    end else begin
      a_idx_reg <= a_idx;
      a_reg   <= a;
      a_rdy_reg <= a_rdy;
    end
  end
  //* =========================================================

endmodule