// ======================================================================
// File name  : DMVM.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   :
// -- Compute attention coefficients: a = ReLU[e x (Wh1 || Wh2)]
// -- Pipeline stage = $clog2(NUM_FEATURE_OUT) + 1
// -- Fetch WH vector and Attention Weight vector from BRAM
// -- Store the coefficients in BRAM
// Author     : @Germanyy0410
// ======================================================================

`include "./../../inc/gat_define.sv"

module DMVM #(
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
)(
  input                                         clk                 ,
  input                                         rst_n               ,

  input                                         dmvm_vld_i          ,
  output                                        dmvm_rdy_o          ,

  // -- a
  input                                         a_vld_i             ,
  input   [A_DEPTH-1:0] [DATA_WIDTH-1:0]        a_i                 ,

  // -- WH bram
  input   [WH_WIDTH-1:0]                        wh_data_i           ,

  // -- output
  output  [DATA_WIDTH-1:0]                      coef_ff_din         ,
  input                                         coef_ff_full        ,
  output                                        coef_ff_wr_vld
);


  //* ========== logic declaration ===========
  // -- Weight vector
  logic [HALF_A_SIZE-1:0] [DATA_WIDTH-1:0]                        a_src               ;
  logic [HALF_A_SIZE-1:0] [DATA_WIDTH-1:0]                        a_nbr               ;

  // -- capture [dout]
  logic                                                           wh_rd_dly           ;
  logic [WH_WIDTH-1:0]                                            wh_data             ;
  logic [WH_WIDTH-1:0]                                            wh_data_reg         ;

  // -- WH data
  logic [HALF_A_SIZE-1:0] [WH_DATA_WIDTH-1:0]                     wh_arr              ;
  logic                                                           src_flag            ;

  logic [NUM_NODE_WIDTH-1:0]                                      num_node            ;

  // -- pipeline 5 stages
  logic [NUM_STAGES-1:0]                                          pipe_src_flag       ;
  logic [NUM_STAGES:0]                                            pipe_src_flag_reg   ;

  logic [NUM_STAGES-1:0] [HALF_A_SIZE-1:0] [DMVM_DATA_WIDTH-1:0]  pipe_src            ;
  logic [NUM_STAGES-1:0] [HALF_A_SIZE-1:0] [DMVM_DATA_WIDTH-1:0]  pipe_nbr            ;
  logic [NUM_STAGES:0] [HALF_A_SIZE-1:0] [DMVM_DATA_WIDTH-1:0]    pipe_src_reg        ;
  logic [NUM_STAGES:0] [HALF_A_SIZE-1:0] [DMVM_DATA_WIDTH-1:0]    pipe_nbr_reg        ;

  logic [DMVM_DATA_WIDTH-1:0]                                     src_dmvm            ;
  logic [DMVM_DATA_WIDTH-1:0]                                     nbr_dmvm            ;
  logic [DMVM_DATA_WIDTH-1:0]                                     src_dmvm_reg        ;
  logic [DMVM_DATA_WIDTH-1:0]                                     nbr_dmvm_reg        ;

  logic [DATA_WIDTH-1:0]                                          pipe_coef           ;
  logic [DATA_WIDTH-1:0]                                          pipe_coef_reg       ;

  // -- output
  logic [COEF_DELAY_LENGTH-1:0]                                   vld_shft_reg        ;
  logic                                                           dmvm_rdy_reg        ;

  //* =======================================

  genvar i, k;
  integer x;

  //* ========== output assignment ==========
  assign dmvm_rdy_o = dmvm_rdy_reg;
  //* =======================================


  //* ========== split vector [a] ===========
  generate
    for (i = 0; i < HALF_A_SIZE; i = i + 1) begin
      assign a_src[HALF_A_SIZE-1-i] = a_i[i];
    end

    for (i = 0; i < HALF_A_SIZE; i = i + 1) begin
      assign a_nbr[HALF_A_SIZE-1-i] = a_i[i + HALF_A_SIZE];
    end
  endgenerate
  //* =======================================


  //* ============== wh_data ================
  assign wh_data = dmvm_vld_i ? wh_data_i : wh_data_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wh_data_reg  <= 'b0;
    end else begin
      wh_data_reg  <= wh_data;
    end
  end
  //* =======================================


  //* ======= get WH data from bram =========
  assign src_flag = wh_data_reg[0];
  assign num_node = wh_data_reg[NUM_NODE_WIDTH:1];

  generate
    for (i = 0; i < HALF_A_SIZE; i = i + 1) begin
      assign wh_arr[HALF_A_SIZE-1-i] = wh_data_reg[WH_WIDTH-1-i*WH_DATA_WIDTH : WH_WIDTH-(i+1)*WH_DATA_WIDTH];
    end
  endgenerate
  //* =======================================


  //* ======== Pipeline calculation =========
  assign src_dmvm   = (pipe_src_flag_reg[NUM_STAGES] == 1'b1) ? pipe_src_reg[NUM_STAGES][0] : src_dmvm_reg;
  assign nbr_dmvm   = pipe_nbr_reg[NUM_STAGES][0];
  assign pipe_coef  = (src_dmvm + nbr_dmvm) >> (DMVM_DATA_WIDTH - DATA_WIDTH);

  // -- src_flag
  generate
    for (i = 0; i < NUM_STAGES; i = i + 1) begin
      assign pipe_src_flag[i] = (i == 0) ? src_flag : pipe_src_flag_reg[i];
    end
  endgenerate

  // -- calculation
  generate
    for (i = 0; i < NUM_STAGES; i = i + 1) begin
      if (i == 0) begin
        for (k = 0; k < HALF_A_SIZE; k = k + 1) begin
          assign pipe_src[i][k] = $signed(a_src[k]) * $signed(wh_arr[k]);
          assign pipe_nbr[i][k] = $signed(a_nbr[k]) * $signed(wh_arr[k]);
        end
      end else begin
        for (k = 0; k < HALF_A_SIZE / (1 << i); k = k + 1) begin
          assign pipe_src[i][k] = $signed(pipe_src_reg[i][2*k]) + $signed(pipe_src_reg[i][2*k+1]);
          assign pipe_nbr[i][k] = $signed(pipe_nbr_reg[i][2*k]) + $signed(pipe_nbr_reg[i][2*k+1]);
        end
      end
    end
  endgenerate

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      src_dmvm_reg <= 'b0;
      nbr_dmvm_reg <= 'b0;
    end else begin
      src_dmvm_reg <= src_dmvm;
      nbr_dmvm_reg <= nbr_dmvm;
    end
  end

  generate
    for (i = 0; i < NUM_STAGES; i = i + 1) begin
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          pipe_src_reg[i+1]       <= 'b0;
          pipe_nbr_reg[i+1]       <= 'b0;
          pipe_src_flag_reg[i+1]  <= 'b0;
        end else begin
          pipe_src_reg[i+1]       <= pipe_src[i];
          pipe_nbr_reg[i+1]       <= pipe_nbr[i];
          pipe_src_flag_reg[i+1]  <= pipe_src_flag[i];
        end
      end
    end
  endgenerate
  //* =======================================


  //* ========== Write [e] to ff ==========
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pipe_coef_reg <= 'b0;
    end else begin
      pipe_coef_reg <= pipe_coef;
    end
  end

  assign coef_ff_din      = (pipe_coef_reg[DATA_WIDTH-1] == 1'b0) ? pipe_coef_reg : 'b0;
  assign coef_ff_wr_vld   = dmvm_rdy_reg && !coef_ff_full;
  //* =======================================


  //* ============ dmvm_ready ===============
  always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			vld_shft_reg  <= 'b0;
			dmvm_rdy_reg  <= 'b0;
		end else begin
			vld_shft_reg  <= { vld_shft_reg[COEF_DELAY_LENGTH-2:0], dmvm_vld_i };
			dmvm_rdy_reg  <= vld_shft_reg[COEF_DELAY_LENGTH-1];
		end
	end
  //* =======================================

`ifdef SIMULATION
  logic [DMVM_DATA_WIDTH-1:0] dut_dmvm_output;
  logic                       dut_dmvm_ready;

  always_comb begin
    if (pipe_src_flag_reg[NUM_STAGES]) begin
      if (vld_shft_reg[COEF_DELAY_LENGTH-1]) begin
        dut_dmvm_output = src_dmvm;
      end else if (dmvm_rdy_o) begin
        dut_dmvm_output = nbr_dmvm_reg;
      end else begin
        dut_dmvm_output = nbr_dmvm;
      end
    end else begin
      dut_dmvm_output = nbr_dmvm;
    end
  end

  assign dut_dmvm_ready = (vld_shft_reg[COEF_DELAY_LENGTH-1]) || (!vld_shft_reg[COEF_DELAY_LENGTH-1] && dmvm_rdy_reg && pipe_src_flag_reg[NUM_STAGES]);
`endif

endmodule