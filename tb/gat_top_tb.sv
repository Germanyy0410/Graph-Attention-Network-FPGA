`timescale 1ns / 1ps

`include "../rtl/inc/gat_define.sv"

`ifdef CORA
	localparam string ROOT_PATH = "D:/VLSI/Capstone/data/cora";
`elsif CITESEER
	localparam string ROOT_PATH = "D:/VLSI/Capstone/data/citeseer";
`elsif PUBMED
	localparam string ROOT_PATH = "D:/VLSI/Capstone/data/pubmed";
`else
	localparam string ROOT_PATH = "D:/VLSI/Capstone/tb";
`endif

string LOG_PATH;

module gat_top_tb #(
  //* ======================= parameter ========================
`ifdef TESTBENCH
  parameter H_NUM_SPARSE_DATA       = 555,
  parameter TOTAL_NODES             = 100,
  parameter NUM_FEATURE_IN          = 11,
  parameter NUM_FEATURE_OUT         = 16,
  parameter NUM_FEATURE_FINAL       = 7,
  parameter NUM_SUBGRAPHS           = 25,
  parameter MAX_NODES               = 6,

  parameter WH_DATA_WIDTH_CONV1     = 11,
  parameter WH_DATA_WIDTH_CONV2     = 16,

  parameter DMVM_DATA_WIDTH_CONV1   = 19,
  parameter DMVM_DATA_WIDTH_CONV2   = 24,

`elsif CORA
  parameter H_NUM_SPARSE_DATA       = 242101,
  parameter TOTAL_NODES             = 13264,
  parameter NUM_FEATURE_IN          = 1433,
  parameter NUM_FEATURE_OUT         = 16,
  parameter NUM_FEATURE_FINAL       = 7,
  parameter NUM_SUBGRAPHS           = 2708,
  parameter MAX_NODES               = 169,

  parameter WH_DATA_WIDTH_CONV1     = 12,
  parameter WH_DATA_WIDTH_CONV2     = 16,

  parameter DMVM_DATA_WIDTH_CONV1   = 19,
  parameter DMVM_DATA_WIDTH_CONV2   = 24,

`elsif CITESEER
  parameter H_NUM_SPARSE_DATA       = 399058,
  parameter TOTAL_NODES             = 12383,
  parameter NUM_FEATURE_IN          = 3703,
  parameter NUM_FEATURE_OUT         = 16,
  parameter NUM_FEATURE_FINAL       = 7,
  parameter NUM_SUBGRAPHS           = 3327,
  parameter MAX_NODES               = 100,
  parameter DMVM_DATA_WIDTH         = 20,

  parameter WH_DATA_WIDTH_CONV1     = 10,
  parameter WH_DATA_WIDTH_CONV2     = 16,

  parameter DMVM_DATA_WIDTH_CONV1   = 20,
  parameter DMVM_DATA_WIDTH_CONV2   = 23,

`elsif PUBMED
  parameter H_NUM_SPARSE_DATA       = 557,
  parameter TOTAL_NODES             = 100,
  parameter NUM_FEATURE_IN          = 11,
  parameter NUM_FEATURE_OUT         = 16,
  parameter NUM_FEATURE_FINAL       = 7,
  parameter NUM_SUBGRAPHS           = 26,
  parameter MAX_NODES               = 6,
  parameter DMVM_DATA_WIDTH         = 20,

  parameter WH_DATA_WIDTH_CONV1     = 10,
  parameter WH_DATA_WIDTH_CONV2     = 16,

  parameter DMVM_DATA_WIDTH_CONV1   = 20,
  parameter DMVM_DATA_WIDTH_CONV2   = 23,
`endif

  parameter DATA_WIDTH              = 8,
  parameter SM_DATA_WIDTH           = 108,
  parameter SM_SUM_DATA_WIDTH       = 108,
  parameter ALPHA_DATA_WIDTH        = 32,
  parameter NEW_FEATURE_WIDTH       = 32,

  parameter COEF_DEPTH              = 500,
  parameter ALPHA_DEPTH             = 500,
  parameter DIVIDEND_DEPTH          = 500,
  parameter DIVISOR_DEPTH           = 500,
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
  localparam WH_WIDTH             = WH_DATA_WIDTH_CONV1 * W_NUM_OF_COLS + NUM_NODE_WIDTH + FLAG_WIDTH,

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

  // -- [NEW FEATURE]
  localparam NEW_FEATURE_ADDR_W   = $clog2(NEW_FEATURE_DEPTH)
  //* ==========================================================
) ();

  //* =================== DUT Initialization ===================
  logic                             clk                         ;
  logic                             rst_n                       ;

  logic                             gat_layer                   ;
  logic                             gat_ready                   ;
  logic   [31:0]                    gat_debug_1                 ;
  logic   [31:0]                    gat_debug_2                 ;
  logic   [31:0]                    gat_debug_3                 ;

  logic                             h_data_bram_load_done       ;
  logic                             h_node_info_bram_load_done  ;
  logic                             wgt_bram_load_done          ;

  logic   [H_DATA_WIDTH-1:0]        h_data_bram_din             ;
  logic   [H_DATA_WIDTH-1:0]        h_data_bram_douta           ;
  logic                             h_data_bram_ena             ;
  logic                             h_data_bram_wea             ;
  logic   [H_DATA_ADDR_W-1:0]       h_data_bram_addra           ;

  logic   [NODE_INFO_WIDTH-1:0]     h_node_info_bram_din        ;
  logic   [NODE_INFO_WIDTH-1:0]     h_node_info_bram_douta      ;
  logic                             h_node_info_bram_ena        ;
  logic                             h_node_info_bram_wea        ;
  logic   [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addra      ;
  logic   [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addrc      ;
  logic   [NODE_INFO_WIDTH-1:0]     h_node_info_bram_doutc      ;

  logic   [DATA_WIDTH-1:0]          wgt_bram_din                ;
  logic   [DATA_WIDTH-1:0]          wgt_bram_douta              ;
  logic                             wgt_bram_ena                ;
  logic                             wgt_bram_wea                ;
  logic   [WEIGHT_ADDR_W-1:0]       wgt_bram_addra              ;
  logic   [WEIGHT_ADDR_W-1:0]       wgt_bram_addrc              ;
  logic   [DATA_WIDTH-1:0]          wgt_bram_doutc              ;

  logic   [13:0]                    wh_out_bram_addrb           ;
  logic   [WH_DATA_WIDTH_CONV1-1:0] wh_out_bram_dout            ;

  logic   [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addrb             ;
  logic   [DATA_WIDTH-1:0]          feat_bram_dout              ;

  gat_top dut (.*);
  //* ==========================================================


  //* =================== CLK Initialization ===================
  always #5 clk = ~clk;
  initial begin
    clk       = 1'b1;
    rst_n     = 1'b0;
    #15.01;
    rst_n     = 1'b1;
  end
  //* ==========================================================


  //* ==================== Update Log Path =====================
  initial begin
    LOG_PATH = "D:/VLSI/Capstone/tb/log/conv1";
    wait(dut.gat_ready == 1'b1);
    LOG_PATH = "D:/VLSI/Capstone/tb/log/conv2";
  end
  //* ==========================================================


  `include "comparator.sv"
  `include "helper/helper.sv"
  `include "loader/input_loader.sv"
  `include "loader/output_loader.sv"


  //* ================= Output Comparator - Layer 1 =================
  OutputComparator #(longint, WH_DATA_WIDTH_CONV1, TOTAL_NODES, NUM_FEATURE_OUT)    spmm          = new("WH         ", WH_DATA_WIDTH_CONV1, 0, 1);

  OutputComparator #(longint, DMVM_DATA_WIDTH_CONV1, TOTAL_NODES)                   dmvm          = new("DMVM       ", DMVM_DATA_WIDTH_CONV1, 0, 1);
  OutputComparator #(longint, DATA_WIDTH, TOTAL_NODES)                              coef          = new("COEF       ", DATA_WIDTH, 0, 1);

  OutputComparator #(real, SM_DATA_WIDTH, TOTAL_NODES)                              dividend      = new("Dividend   ", SM_DATA_WIDTH, 0, 0);
  OutputComparator #(real, SM_SUM_DATA_WIDTH, NUM_SUBGRAPHS)                        divisor       = new("Divisor    ", SM_SUM_DATA_WIDTH, 0, 0);
  OutputComparator #(longint, NUM_NODE_WIDTH, NUM_SUBGRAPHS)                        sm_num_nodes  = new("Num Node   ", NUM_NODE_WIDTH, 0, 0);
  OutputComparator #(real, ALPHA_DATA_WIDTH, TOTAL_NODES)                           alpha         = new("Alpha      ", WOI, WOF, 0);

  OutputComparator #(real, NEW_FEATURE_WIDTH, NUM_SUBGRAPHS * NUM_FEATURE_OUT)      new_feature   = new("New Feature", 16, 16, 0);
  //* ===============================================================


  //* ================= Output Comparator - Layer 2 =================
  OutputComparator #(longint, WH_DATA_WIDTH_CONV2, TOTAL_NODES, NUM_FEATURE_FINAL)  spmm_conv2          = new("WH         ", WH_DATA_WIDTH_CONV2, 0, 1);

  OutputComparator #(longint, DMVM_DATA_WIDTH_CONV2, TOTAL_NODES)                   dmvm_conv2          = new("DMVM       ", DMVM_DATA_WIDTH_CONV2, 0, 1);
  OutputComparator #(longint, DATA_WIDTH, TOTAL_NODES)                              coef_conv2          = new("COEF       ", DATA_WIDTH, 0, 1);

  OutputComparator #(real, SM_DATA_WIDTH, TOTAL_NODES)                              dividend_conv2      = new("Dividend   ", SM_DATA_WIDTH, 0, 0);
  OutputComparator #(real, SM_SUM_DATA_WIDTH, NUM_SUBGRAPHS)                        divisor_conv2       = new("Divisor    ", SM_SUM_DATA_WIDTH, 0, 0);
  OutputComparator #(real, ALPHA_DATA_WIDTH, TOTAL_NODES)                           alpha_conv2         = new("Alpha      ", WOI, WOF, 0);

  OutputComparator #(real, NEW_FEATURE_WIDTH, NUM_SUBGRAPHS * NUM_FEATURE_FINAL)    new_feature_conv2   = new("New Feature", 16, 16, 0);
  //* ===============================================================

  `include "configuration.sv"

  //* =========================== Layer 1 ===========================
  initial begin
    gat_layer = 1'b0;

    // ================ Load IO ================
    fork
      input_loader();
      output_loader();
    join
    // =========================================


    // =========== Start Simulation ============
    $display("Starting Simulation...");
    c3;
    wait(dut.u_gat_conv1.u_SPMM.spmm_vld_i);
    start_time      = $time;
    lat_start_time  = $time;

    // -- Latency
    wait(dut.u_gat_conv1.u_aggregator.u_feature_controller.feat_bram_ena);
    lat_end_time = $time;

    // -- Total
    wait(dut.u_gat_conv1.gat_ready);
    end_time = $time;
    // =========================================


    // ================ Report =================
    summary_section();

    spmm.base_scoreboard();
    dmvm.base_scoreboard();
    coef.base_scoreboard();
    dividend.base_scoreboard();
    divisor.base_scoreboard();
    sm_num_nodes.base_scoreboard();
    alpha.base_scoreboard();
    new_feature.base_scoreboard();

    end_section();
    // =========================================
    $display("Here 0");

    wgt_bram_load_done          = 1'b0;
    h_data_bram_load_done       = 1'b0;
    h_node_info_bram_load_done  = 1'b0;
    c1;
    gat_layer = 1'b1;
    $display("Here 00");

    // ================ Load IO ================
    fork
      input_loader();
      output_loader();
    join
    // =========================================

    $display("Here 000");

    // =========== Start Simulation ============
    c3;
    wait(dut.u_gat_conv2.u_WH.wh_vld_i);
    $display("Here 1");
    start_time      = $time;
    lat_start_time  = $time;
    // -- Latency
    c3;
    wait(dut.u_gat_conv2.u_aggregator.u_feature_controller.feat_bram_ena);
    $display("Here 2");
    lat_end_time = $time;

    // -- Total
    c3;
    wait(dut.gat_ready == 1'b1);
    $display("Here 3");
    end_time = $time;

    // =========================================

    $finish();

    // ================ Report =================
    summary_section();

    spmm_conv2.base_scoreboard();
    dmvm_conv2.base_scoreboard();
    coef_conv2.base_scoreboard();
    dividend_conv2.base_scoreboard();
    divisor_conv2.base_scoreboard();
    alpha_conv2.base_scoreboard();
    new_feature_conv2.base_scoreboard();

    end_section();
    // =========================================

    $finish();
  end
  //* ===============================================================


  //* =========================== Layer 2 ===========================
  // initial begin
  //   c1;
  //   wait(dut.gat_ready == 1'b1);

  // end
  //* ===============================================================
endmodule