`timescale 1ns / 1ps

`ifdef CORA
	localparam string ROOT_PATH = "D:/VLSI/Capstone/data/cora/layer_2";
`elsif CITESEER
	localparam string ROOT_PATH = "D:/VLSI/Capstone/data/citeseer/layer_2";
`elsif PUBMED
	localparam string ROOT_PATH = "D:/VLSI/Capstone/data/pubmed/layer_2";
`else
	localparam string ROOT_PATH = "D:/VLSI/Capstone/tb";
`endif

localparam string INPUT_PATH    = { ROOT_PATH, "/input" };
localparam string GOLDEN_PATH   = { ROOT_PATH, "/output" };
localparam string LOG_PATH      = { ROOT_PATH, "/log" };

module gat_top_conv2_tb #(
  //* ======================= parameter ========================
`ifdef TESTBENCH
  parameter H_NUM_SPARSE_DATA       = 555,
  parameter TOTAL_NODES             = 100,
  parameter NUM_FEATURE_IN          = 11,
  parameter NUM_FEATURE_OUT         = 16,
  parameter NUM_SUBGRAPHS           = 25,
  parameter MAX_NODES               = 6,

  parameter WH_DATA_WIDTH           = 16,
  parameter DMVM_DATA_WIDTH         = 24,

`elsif CORA
  parameter H_NUM_SPARSE_DATA       = 242101,
  parameter TOTAL_NODES             = 13264,
  parameter NUM_FEATURE_IN          = 16,
  parameter NUM_FEATURE_OUT         = 7,
  parameter NUM_SUBGRAPHS           = 2708,
  parameter MAX_NODES               = 169,

  parameter WH_DATA_WIDTH           = 16,
  parameter DMVM_DATA_WIDTH         = 24,

`elsif CITESEER
  parameter H_NUM_SPARSE_DATA       = 399058,
  parameter TOTAL_NODES             = 12383,
  parameter NUM_FEATURE_IN          = 16,
  parameter NUM_FEATURE_OUT         = 6,
  parameter NUM_SUBGRAPHS           = 3327,
  parameter MAX_NODES               = 100,
  parameter DMVM_DATA_WIDTH         = 20,

  parameter WH_DATA_WIDTH           = 16,
  parameter DMVM_DATA_WIDTH         = 23,

`elsif PUBMED
  parameter H_NUM_SPARSE_DATA       = 557,
  parameter TOTAL_NODES             = 100,
  parameter NUM_FEATURE_IN          = 16,
  parameter NUM_FEATURE_OUT         = 3,
  parameter NUM_SUBGRAPHS           = 26,
  parameter MAX_NODES               = 6,
  parameter DMVM_DATA_WIDTH         = 20,

  parameter WH_DATA_WIDTH           = 16,
  parameter DMVM_DATA_WIDTH         = 23,
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
  localparam WEIGHT_DEPTH         = NUM_FEATURE_OUT * (NUM_FEATURE_IN + 2) + NUM_FEATURE_FINAL * (NUM_FEATURE_OUT + 2),
  localparam WH_DEPTH             = 128,
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
  localparam MULT_WEIGHT_ADDR_W   = $clog2(NUM_FEATURE_IN),

  // -- [WH]
  localparam DOT_PRODUCT_SIZE     = H_NUM_OF_COLS,
  localparam WH_ADDR_W            = $clog2(WH_DEPTH),
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

  // -- [NEW FEATURE]
  localparam NEW_FEATURE_ADDR_W   = $clog2(NEW_FEATURE_DEPTH)
  //* ==========================================================
) ();

  localparam WEIGHT_ADDR_W_2 = $clog2(1433*16+16*2);

  logic                             clk                         ;
  logic                             rst_n                       ;

  logic                             gat_layer                   ;
  logic                             gat_ready                   ;

  logic   [H_DATA_WIDTH-1:0]        h_data_bram_din             ;
  logic                             h_data_bram_ena             ;
  logic                             h_data_bram_wea             ;
  logic   [H_DATA_ADDR_W-1:0]       h_data_bram_addra           ;
  logic   [H_DATA_ADDR_W-1:0]       h_data_bram_addrb           ;
  logic                             h_data_bram_load_done       ;

  logic   [NODE_INFO_WIDTH-1:0]     h_node_info_bram_din        ;
  logic                             h_node_info_bram_ena        ;
  logic                             h_node_info_bram_wea        ;
  logic   [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addra      ;
  logic   [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addrb      ;
  logic                             h_node_info_bram_load_done  ;

  logic   [DATA_WIDTH-1:0]          wgt_bram_din                ;
  logic                             wgt_bram_ena                ;
  logic                             wgt_bram_wea                ;
  logic   [WEIGHT_ADDR_W_2-1:0]     wgt_bram_addra              ;
  logic   [WEIGHT_ADDR_W_2-1:0]     wgt_bram_addrb              ;
  logic                             wgt_bram_load_done          ;

  logic   [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addrb             ;
  logic   [DATA_WIDTH-1:0]          feat_bram_dout              ;

  gat_top dut (.*);

  ///////////////////////////////////////////////////////////////////
  always #5 clk = ~clk;
  initial begin
    gat_layer = 1'b1;
    clk       = 1'b1;
    rst_n     = 1'b0;
    #15.01;
    rst_n     = 1'b1;
  end
  ///////////////////////////////////////////////////////////////////


  ///////////////////////////////////////////////////////////////////
  `include "comparator.sv"
  `include "helper/helper.sv"
  `include "loader/input_loader.sv"
  `include "loader/output_loader.sv"
  ///////////////////////////////////////////////////////////////////


  ///////////////////////////////////////////////////////////////////
  OutputComparator #(longint, WH_DATA_WIDTH, TOTAL_NODES, NUM_FEATURE_OUT)    spmm          = new("WH         ", WH_DATA_WIDTH, 0, 1);

  OutputComparator #(longint, DMVM_DATA_WIDTH, TOTAL_NODES)                   dmvm          = new("DMVM       ", DMVM_DATA_WIDTH, 0, 1);
  OutputComparator #(longint, DATA_WIDTH, TOTAL_NODES)                        coef          = new("COEF       ", DATA_WIDTH, 0, 1);

  OutputComparator #(real, SM_DATA_WIDTH, TOTAL_NODES)                        dividend      = new("Dividend   ", SM_DATA_WIDTH, 0, 0);
  OutputComparator #(real, SM_SUM_DATA_WIDTH, NUM_SUBGRAPHS)                  divisor       = new("Divisor    ", SM_SUM_DATA_WIDTH, 0, 0);
  OutputComparator #(longint, NUM_NODE_WIDTH, NUM_SUBGRAPHS)                  sm_num_nodes  = new("Num Node   ", NUM_NODE_WIDTH, 0, 0);
  OutputComparator #(real, ALPHA_DATA_WIDTH, TOTAL_NODES)                     alpha         = new("Alpha      ", WOI, WOF, 0);

  OutputComparator #(real, NEW_FEATURE_WIDTH, NUM_SUBGRAPHS*NUM_FEATURE_OUT)  new_feature   = new("New Feature", 16, 16, 0);
  ///////////////////////////////////////////////////////////////////


  ///////////////////////////////////////////////////////////////////
  initial begin
    spmm.header               = "SPMM";
    dmvm.header               = "DMVM";
    dividend.header           = "SOFTMAX";
    new_feature.header        = "AGGREGATOR";

    spmm.log_file             = "/SPMM/wh.log";
    dmvm.log_file             = "/DMVM/dmvm.log";
    coef.log_file             = "/DMVM/coef.log";
    dividend.log_file         = "/softmax/dividend.log";
    divisor.log_file          = "/softmax/divisor.log";
    sm_num_nodes.log_file     = "/softmax/num_nodes.log";
    alpha.log_file            = "/softmax/alpha.log";
    new_feature.log_file      = "/aggregator/new_feature.log";
  end
  ///////////////////////////////////////////////////////////////////


  ///////////////////////////////////////////////////////////////////
  always_comb begin
    spmm.dut_ready              = dut.u_gat_conv2.u_WH.wh_rdy_o;
    spmm.dut_spmm_output        = dut.u_gat_conv2.u_WH.res_reg;
    spmm.golden_spmm_output     = golden_spmm;
  end

  always_comb begin
    dmvm.dut_ready              = dut.u_gat_conv2.u_DMVM.dut_dmvm_ready;
    dmvm.dut_output             = dut.u_gat_conv2.u_DMVM.dut_dmvm_output;
    dmvm.golden_output          = golden_dmvm;

    coef.dut_ready              = dut.u_gat_conv2.u_DMVM.dmvm_rdy_o;
    coef.dut_output             = dut.u_gat_conv2.u_DMVM.coef_ff_din;
    coef.golden_output          = golden_coef;
  end

  always_comb begin
    dividend.dut_ready          = dut.u_gat_conv2.u_softmax.divd_ff_rd_vld;
    dividend.dut_output         = dut.u_gat_conv2.u_softmax.divd_ff_dout;
    dividend.golden_output      = golden_dividend;

    divisor.dut_ready           = dut.u_gat_conv2.u_softmax.dvsr_ff_wr_vld;
    divisor.dut_output          = dut.u_gat_conv2.u_softmax.sum_reg;
    divisor.golden_output       = golden_divisor;

    sm_num_nodes.dut_ready      = dut.u_gat_conv2.u_softmax.dvsr_ff_wr_vld;
    sm_num_nodes.dut_output     = dut.u_gat_conv2.u_softmax.num_node_reg;
    sm_num_nodes.golden_output  = golden_sm_num_node;

    alpha.dut_ready             = dut.u_gat_conv2.u_softmax.sm_rdy_o;
    alpha.dut_output            = dut.u_gat_conv2.u_softmax.alpha_ff_din;
    alpha.golden_output         = golden_alpha;
  end

  always_comb begin
    new_feature.dut_ready       = dut.u_gat_conv2.u_aggregator.u_feature_controller.feat_bram_ena;
    new_feature.dut_output      = dut.u_gat_conv2.u_aggregator.u_feature_controller.feat_bram_din;
    new_feature.golden_output   = golden_new_feature;
  end
  ///////////////////////////////////////////////////////////////////


  ///////////////////////////////////////////////////////////////////
  initial begin
    fork
      spmm.packed_checker();
      dmvm.output_checker();
      coef.output_checker();
      dividend.output_checker();
      divisor.output_checker();
      sm_num_nodes.output_checker();
      alpha.output_checker(0.0001);
      new_feature.output_checker(0.01);
    join
  end
  ///////////////////////////////////////////////////////////////////


  ///////////////////////////////////////////////////////////////////
  initial begin
    c3;
    wait(dut.u_gat_conv2.u_WH.wh_vld_i);
    start_time      = $time;
    lat_start_time  = $time;

    // -- Latency
    wait(dut.u_gat_conv2.u_aggregator.u_feature_controller.feat_bram_ena);
    lat_end_time = $time;

    // -- Total
    wait(dut.u_gat_conv2.gat_ready);
    end_time = $time;

    //////////////////////////////
    summary_section;
    //////////////////////////////

    spmm.base_scoreboard();
    dmvm.base_scoreboard();
    coef.base_scoreboard();
    dividend.base_scoreboard();
    divisor.base_scoreboard();
    sm_num_nodes.base_scoreboard();
    alpha.base_scoreboard();
    new_feature.base_scoreboard();

    //////////////////////////////
    end_section;
    //////////////////////////////

    c1;
    $finish();
  end
  ///////////////////////////////////////////////////////////////////
endmodule