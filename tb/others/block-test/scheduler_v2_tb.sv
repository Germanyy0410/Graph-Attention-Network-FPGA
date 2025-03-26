`timescale 1ns / 1ps

`include "../../../rtl/others/define/gat_define.sv"

module scheduler_v2_tb #(
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
)();

  logic                                                                 clk                 ;
  logic                                                                 rst_n               ;

  logic                                                                 sched_vld_i         ;
  logic                                                                 sched_rdy_o         ;

  //* ======================== wgt BRAM =======================
  logic [WEIGHT_ADDR_W-1:0]                                             wgt_bram_addra      ;
  logic [DATA_WIDTH-1:0]                                                wgt_bram_din        ;
  logic                                                                 wgt_bram_ena        ;
  logic [DATA_WIDTH-1:0]                                                wgt_bram_dout       ;
  logic [WEIGHT_ADDR_W-1:0]                                             wgt_bram_addrb      ;
  //* =========================================================


  //* ========================= Conv1 =========================
  logic [W_NUM_OF_COLS*MULT_WEIGHT_ADDR_W-1:0]                          mult_wgt_addrb      ;
  logic [W_NUM_OF_COLS*DATA_WIDTH-1:0]                                  mult_wgt_dout       ;

  logic [NUM_FEATURE_OUT*2-1:0] [DATA_WIDTH-1:0]                        a_conv1_o           ;
  //* =========================================================


  //* ========================= Conv2 =========================
  logic [NUM_FEATURE_FINAL-1:0] [NUM_FEATURE_OUT-1:0] [DATA_WIDTH-1:0]  wgt_o               ;
  logic [NUM_FEATURE_FINAL*2-1:0] [DATA_WIDTH-1:0]                      a_conv2_o           ;
  //* =========================================================

  scheduler_v2 dut (.*);

  BRAM #(
    .DATA_WIDTH (DATA_WIDTH     ),
    .DEPTH      (WEIGHT_DEPTH   )
  ) u_wgt_bram (
    .clk        (clk            ),
    .rst_n      (rst_n          ),
    .addra      (wgt_bram_addra ),
    .din        (wgt_bram_din   ),
    .ena        (wgt_bram_ena   ),
    .wea        (wgt_bram_ena   ),
    .dout       (wgt_bram_dout  ),
    .addrb      (wgt_bram_addrb )
  );

  always #5 clk = ~clk;
  initial begin
    clk       = 1'b1;
    rst_n     = 1'b0;
    #15.01;
    rst_n     = 1'b1;
  end

  integer weight_file;
  integer w_r;
  string  file_path;

  initial begin
    sched_vld_i  = 1'b0;
    wgt_bram_ena = 1'b1;

    file_path   = "D:/VLSI/Capstone/data/cora/layer_1/input/weight_demo.txt";
    weight_file = $fopen(file_path, "r");

    for (int i = 0; i < WEIGHT_DEPTH; i++) begin
      w_r = $fscanf(weight_file, "%b\n", wgt_bram_din);
      wgt_bram_addra = i;
      #10.01;
    end

    $display("WEIGHT FINISH");

    wgt_bram_ena = 1'b0;

    $fclose(weight_file);

    #40.01;
    sched_vld_i = 1'b1;
    #400000;
    $finish();
  end


endmodule