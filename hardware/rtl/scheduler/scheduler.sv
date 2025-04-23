// ==================================================================
// File name  : scheduler.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   :
// -- Split each column of Weight into one BRAM
// -- Fetch Attention Weight from BRAM to a register
// Author     : @Germanyy0410
// ==================================================================

module scheduler #(
  //* ======================= parameter ========================
  parameter DATA_WIDTH            = 8,
  parameter WH_DATA_WIDTH         = 12,
  parameter DMVM_DATA_WIDTH       = 19,
  parameter COEF_DATA_WIDTH       = 19,
  parameter SM_DATA_WIDTH         = 108,
  parameter SM_SUM_DATA_WIDTH     = 108,
  parameter ALPHA_DATA_WIDTH      = 32,
  parameter NEW_FEATURE_WIDTH     = 32,

  parameter H_NUM_SPARSE_DATA     = 242101,
  parameter TOTAL_NODES           = 13264,
  parameter NUM_FEATURE_IN        = 1433,
  parameter NUM_FEATURE_OUT       = 16,
  parameter NUM_FEATURE_FINAL     = 7,
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
  localparam WEIGHT_DEPTH         = NUM_FEATURE_OUT * (NUM_FEATURE_IN + 2) + NUM_FEATURE_FINAL * (NUM_FEATURE_OUT + 2),
  localparam WH_DEPTH             = 128,
  localparam A_DEPTH              = NUM_FEATURE_OUT * 2,
  localparam NUM_NODES_DEPTH      = NUM_SUBGRAPHS,
  localparam NEW_FEATURE_DEPTH    = NUM_SUBGRAPHS * NUM_FEATURE_OUT,

  // -- [SUBGRAPH]
  localparam SUBGRAPH_IDX_DEPTH   = TOTAL_NODES,
  localparam SUBGRAPH_IDX_WIDTH   = $clog2(TOTAL_NODES) + 2,
  localparam SUBGRAPH_IDX_ADDR_W  = $clog2(SUBGRAPH_IDX_DEPTH),

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
  localparam ROW_WIDTH            = $clog2(W_NUM_OF_COLS),
  localparam W_COL_WIDTH          = $clog2(NUM_FEATURE_OUT),
  localparam WEIGHT_ADDR_W        = $clog2(WEIGHT_DEPTH),
  localparam MULT_WEIGHT_ADDR_W   = $clog2(NUM_FEATURE_IN),

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
  input                                                                   clk                 ,
  input                                                                   rst_n               ,

  input                                                                   sched_vld_i         ,
  output                                                                  sched_rdy_o         ,

  //* ======================== wgt BRAM =======================
  input   [DATA_WIDTH-1:0]                                                wgt_bram_dout       ,
  output  [WEIGHT_ADDR_W-1:0]                                             wgt_bram_addrb      ,
  //* =========================================================


  //* ========================= Conv1 =========================
  input   [NUM_FEATURE_OUT-1:0] [MULT_WEIGHT_ADDR_W-1:0]                  mult_wgt_addrb      ,
  output  [NUM_FEATURE_OUT-1:0] [DATA_WIDTH-1:0]                          mult_wgt_dout       ,

  output  [NUM_FEATURE_OUT*2-1:0] [DATA_WIDTH-1:0]                        a_conv1_o           ,
  //* =========================================================


  //* ========================= Conv2 =========================
  output  [NUM_FEATURE_FINAL-1:0] [NUM_FEATURE_OUT-1:0] [DATA_WIDTH-1:0]  wgt_o               ,
  output  [NUM_FEATURE_FINAL*2-1:0] [DATA_WIDTH-1:0]                      a_conv2_o
  //* =========================================================
);

  localparam WGT_DEPTH_CONV1    = NUM_FEATURE_IN * NUM_FEATURE_OUT;
  localparam ROW_WIDTH_CONV1    = $clog2(NUM_FEATURE_IN);
  localparam COL_WIDTH_CONV1    = $clog2(NUM_FEATURE_OUT);

  localparam A_DEPTH_CONV1      = NUM_FEATURE_OUT * 2;
  localparam A_IDX_WIDTH_CONV1  = $clog2(A_DEPTH_CONV1);

  localparam WGT_DEPTH_CONV2    = NUM_FEATURE_OUT * NUM_FEATURE_FINAL;
  localparam ROW_WIDTH_CONV2    = $clog2(NUM_FEATURE_OUT);
  localparam COL_WIDTH_CONV2    = $clog2(NUM_FEATURE_FINAL);

  localparam A_DEPTH_CONV2      = NUM_FEATURE_FINAL * 2;
  localparam A_IDX_WIDTH_CONV2  = $clog2(A_DEPTH_CONV2);

  //* =================== Logic Declaration ===================
  logic                                                                 sched_vld_reg       ;
  logic                                                                 sched_vld_reg_q1    ;
  logic                                                                 sched_rdy           ;
  logic                                                                 sched_rdy_reg       ;

  logic [1:0]                                                           wgt_rdy             ;
  logic [1:0]                                                           wgt_rdy_reg         ;
  logic [1:0]                                                           a_rdy               ;
  logic [1:0]                                                           a_rdy_reg           ;

  logic [WEIGHT_ADDR_W-1:0]                                             addr                ;
  logic [WEIGHT_ADDR_W-1:0]                                             addr_reg            ;

  logic [ROW_WIDTH_CONV1-1:0]                                           row_idx_conv1       ;
  logic [ROW_WIDTH_CONV1-1:0]                                           row_idx_conv1_reg   ;
  logic [COL_WIDTH_CONV1-1:0]                                           col_idx_conv1       ;
  logic [COL_WIDTH_CONV1-1:0]                                           col_idx_conv1_reg   ;

  logic [NUM_FEATURE_OUT-1:0] [DATA_WIDTH-1:0]                          mult_wgt_din        ;
  logic [NUM_FEATURE_OUT-1:0] [MULT_WEIGHT_ADDR_W-1:0]                  mult_wgt_addra      ;
  logic [NUM_FEATURE_OUT-1:0]                                           mult_wgt_ena        ;

  logic [A_IDX_WIDTH_CONV1-1:0]                                         a_idx_conv1         ;
  logic [A_IDX_WIDTH_CONV1-1:0]                                         a_idx_conv1_reg     ;
  logic [A_DEPTH_CONV1-1:0] [DATA_WIDTH-1:0]                            a_conv1             ;
  logic [A_DEPTH_CONV1-1:0] [DATA_WIDTH-1:0]                            a_conv1_reg         ;

  logic                                                                 conv2_vld           ;

  logic [ROW_WIDTH_CONV2-1:0]                                           row_idx_conv2       ;
  logic [ROW_WIDTH_CONV2-1:0]                                           row_idx_conv2_reg   ;
  logic [COL_WIDTH_CONV2-1:0]                                           col_idx_conv2       ;
  logic [COL_WIDTH_CONV2-1:0]                                           col_idx_conv2_reg   ;
  logic [NUM_FEATURE_FINAL-1:0] [NUM_FEATURE_OUT-1:0] [DATA_WIDTH-1:0]  wgt                 ;
  logic [NUM_FEATURE_FINAL-1:0] [NUM_FEATURE_OUT-1:0] [DATA_WIDTH-1:0]  wgt_reg             ;

  logic [A_IDX_WIDTH_CONV2-1:0]                                         a_idx_conv2         ;
  logic [A_IDX_WIDTH_CONV2-1:0]                                         a_idx_conv2_reg     ;
  logic [A_DEPTH_CONV2-1:0] [DATA_WIDTH-1:0]                            a_conv2             ;
  logic [A_DEPTH_CONV2-1:0] [DATA_WIDTH-1:0]                            a_conv2_reg         ;
  //* =========================================================

  genvar i, k;

  //* =================== Output Assignment ===================
  assign sched_rdy_o  = sched_rdy_reg;
  assign wgt_o        = wgt_reg;
  assign a_conv1_o    = a_conv1_reg;
  assign a_conv2_o    = a_conv2_reg;
  //* =========================================================


  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sched_vld_reg     <= 'b0;
      sched_vld_reg_q1  <= 'b0;
    end else begin
      sched_vld_reg     <= sched_vld_i;
      sched_vld_reg_q1  <= sched_vld_reg;
    end
  end


  //* ===================== BRAM Instance =====================
  generate
    for (i = 0; i < NUM_FEATURE_OUT; i = i + 1) begin
      BRAM #(
        .DATA_WIDTH   (DATA_WIDTH         ),
        .DEPTH        (NUM_FEATURE_IN     )
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


  assign wgt_bram_addrb = addr_reg;
  assign addr = (sched_vld_i && addr_reg < WEIGHT_DEPTH) ? (addr_reg + 1) : addr_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      addr_reg <= 'b0;
    end else begin
      addr_reg <= addr;
    end
  end


  //* ===================== Ready signal ======================
  assign wgt_rdy[0] = (row_idx_conv1_reg == NUM_FEATURE_IN - 1) && (col_idx_conv1_reg == NUM_FEATURE_OUT - 1) ? 1'b1 : wgt_rdy_reg[0];
  assign wgt_rdy[1] = (row_idx_conv2_reg == NUM_FEATURE_OUT - 1) && (col_idx_conv2_reg == NUM_FEATURE_FINAL - 1) ? 1'b1 : wgt_rdy_reg[1];

  assign a_rdy[0]   = (a_idx_conv1_reg == A_DEPTH_CONV1 - 1) ? 1'b1 : a_rdy_reg[0];
  assign a_rdy[1]   = (a_idx_conv2_reg == A_DEPTH_CONV2 - 1) ? 1'b1 : a_rdy_reg[1];


  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      a_rdy_reg   <= 'b0;
      wgt_rdy_reg <= 'b0;
    end else begin
      a_rdy_reg   <= a_rdy;
      wgt_rdy_reg <= wgt_rdy;
    end
  end
  //* =========================================================


  //* ===================== Mult-wgt BRAM =====================
  always_comb begin
    col_idx_conv1 = col_idx_conv1_reg;
    row_idx_conv1 = row_idx_conv1_reg;

    if (sched_vld_reg) begin
      if (col_idx_conv1_reg == NUM_FEATURE_OUT - 1) begin
        col_idx_conv1 = 0;
      end else begin
        col_idx_conv1 = col_idx_conv1_reg + 1;
      end
    end

    if (sched_vld_reg && col_idx_conv1_reg == NUM_FEATURE_OUT - 1) begin
      if (row_idx_conv1_reg == NUM_FEATURE_IN - 1) begin
        row_idx_conv1 = 0;
      end else begin
        row_idx_conv1 = row_idx_conv1_reg + 1;
      end
    end
  end

  generate
    for (i = 0; i < NUM_FEATURE_OUT; i = i + 1) begin
      assign mult_wgt_addra[i] = row_idx_conv1_reg;
      assign mult_wgt_din[i]   = wgt_bram_dout;
      assign mult_wgt_ena[i]   = ((i == col_idx_conv1_reg) && ~wgt_rdy_reg[0]);
    end
  endgenerate

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      row_idx_conv1_reg <= 'b0;
      col_idx_conv1_reg <= 'b0;
    end else begin
      row_idx_conv1_reg <= row_idx_conv1;
      col_idx_conv1_reg <= col_idx_conv1;
    end
  end
  //* =========================================================


  //* ==================== Attention Conv1 ====================
  assign a_idx_conv1 = ((addr_reg > WGT_DEPTH_CONV1) && (a_idx_conv1_reg < A_DEPTH_CONV1)) ? (a_idx_conv1_reg + 1) : a_idx_conv1_reg;

  generate
    for (i = 0; i < A_DEPTH_CONV1; i = i + 1) begin
      assign a_conv1[i] = (i == a_idx_conv1_reg && addr_reg <= (WGT_DEPTH_CONV1 + A_DEPTH_CONV1)) ? wgt_bram_dout : a_conv1_reg[i];
    end
  endgenerate

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      a_conv1_reg     <= 'b0;
      a_idx_conv1_reg <= 'b0;
    end else begin
      a_conv1_reg     <= a_conv1;
      a_idx_conv1_reg <= a_idx_conv1;
    end
  end
  //* =========================================================


  //* ===================== Weight Conv2 ======================
  assign conv2_vld = (addr_reg > (WGT_DEPTH_CONV1 + A_DEPTH_CONV1)) && ~sched_rdy_o;

  always_comb begin
    col_idx_conv2 = col_idx_conv2_reg;
    row_idx_conv2 = row_idx_conv2_reg;

    if (conv2_vld) begin
      if (col_idx_conv2_reg == NUM_FEATURE_FINAL - 1) begin
        col_idx_conv2 = 0;
      end else begin
        col_idx_conv2 = col_idx_conv2_reg + 1;
      end
    end

    if (conv2_vld && col_idx_conv2_reg == NUM_FEATURE_FINAL - 1) begin
      if (row_idx_conv2_reg == NUM_FEATURE_OUT - 1) begin
        row_idx_conv2 = 0;
      end else begin
        row_idx_conv2 = row_idx_conv2_reg + 1;
      end
    end
  end

  generate
    for (i = 0; i < NUM_FEATURE_FINAL; i = i + 1) begin
      for (k = 0; k < NUM_FEATURE_OUT; k = k + 1) begin
        assign wgt[i][k] = ((row_idx_conv2_reg == k) && (col_idx_conv2_reg == i) && (addr_reg <= WGT_DEPTH_CONV1 + A_DEPTH_CONV1 + WGT_DEPTH_CONV2)) ? wgt_bram_dout : wgt_reg[i][k];
      end
    end
  endgenerate

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wgt_reg           <= 'b0;
      row_idx_conv2_reg <= 'b0;
      col_idx_conv2_reg <= 'b0;
    end else begin
      wgt_reg           <= wgt;
      row_idx_conv2_reg <= row_idx_conv2;
      col_idx_conv2_reg <= col_idx_conv2;
    end
  end
  //* =========================================================


  //* ==================== Attention Conv1 ====================
  assign a_idx_conv2 = ((addr_reg > WGT_DEPTH_CONV1 + A_DEPTH_CONV1 + WGT_DEPTH_CONV2) &&( a_idx_conv2_reg < A_DEPTH_CONV2)) ? (a_idx_conv2_reg + 1) : a_idx_conv2_reg;

  generate
    for (i = 0; i < A_DEPTH_CONV2; i = i + 1) begin
      assign a_conv2[i] = (i == a_idx_conv2_reg) ? wgt_bram_dout : a_conv2_reg[i];
    end
  endgenerate

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      a_conv2_reg     <= 'b0;
      a_idx_conv2_reg <= 'b0;
    end else begin
      a_conv2_reg     <= a_conv2;
      a_idx_conv2_reg <= a_idx_conv2;
    end
  end
  //* =========================================================


  //* ======================= sched_rdy =======================
  assign sched_rdy = (&wgt_rdy_reg) && (&a_rdy_reg);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sched_rdy_reg <= 'b0;
    end else begin
      sched_rdy_reg <= sched_rdy;
    end
  end
  //* =========================================================

endmodule