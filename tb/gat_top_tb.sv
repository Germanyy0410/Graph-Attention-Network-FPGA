`timescale 1ns / 1ps

`ifdef CORA
	localparam string ROOT_PATH = "d:/VLSI/Capstone/data/cora/layer_1";
`elsif CITESEER
	localparam string ROOT_PATH = "d:/VLSI/Capstone/data/citeseer/layer_1";
`elsif PUBMED
	localparam string ROOT_PATH = "d:/VLSI/Capstone/data/pubmed/layer_1";
`else
	localparam string ROOT_PATH = "d:/VLSI/Capstone/tb";
`endif

localparam string INPUT_PATH    = { ROOT_PATH, "/input" };
localparam string GOLDEN_PATH   = { ROOT_PATH, "/output" };
localparam string LOG_PATH      = "D:/VLSI/Capstone/tb/log";

`include "../rtl/inc/gat_pkg.sv"

module gat_top_tb import gat_pkg::*;
();
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
  logic   [WEIGHT_ADDR_W-1:0]       wgt_bram_addra              ;
  logic   [WEIGHT_ADDR_W-1:0]       wgt_bram_addrb              ;
  logic                             wgt_bram_load_done          ;

  logic   [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addrb             ;
  logic   [DATA_WIDTH-1:0]          feat_bram_dout              ;

  gat_top dut (.*);

  ///////////////////////////////////////////////////////////////////
  always #5 clk = ~clk;
  initial begin
    gat_layer = 1'b0;
    clk   = 1'b1;
    rst_n = 1'b0;
    #15.01;
    rst_n = 1'b1;
  end
  ///////////////////////////////////////////////////////////////////


  `include "comparator.sv"
  `include "helper/helper.sv"
  `include "loader/input_loader.sv"
  `include "loader/output_loader.sv"


  ///////////////////////////////////////////////////////////////////
  OutputComparator #(longint, WH_DATA_WIDTH, TOTAL_NODES, NUM_FEATURE_OUT)    spmm         = new("WH         ", WH_DATA_WIDTH, 0, 1);

  OutputComparator #(longint, DMVM_DATA_WIDTH, TOTAL_NODES)                   dmvm         = new("DMVM       ", DMVM_DATA_WIDTH, 0, 1);
  OutputComparator #(longint, DATA_WIDTH, TOTAL_NODES)                        coef         = new("COEF       ", DATA_WIDTH, 0, 1);

  OutputComparator #(real, SM_DATA_WIDTH, TOTAL_NODES)                        dividend     = new("Dividend   ", SM_DATA_WIDTH, 0, 0);
  OutputComparator #(real, SM_SUM_DATA_WIDTH, NUM_SUBGRAPHS)                  divisor      = new("Divisor    ", SM_SUM_DATA_WIDTH, 0, 0);
  OutputComparator #(longint, NUM_NODE_WIDTH, NUM_SUBGRAPHS)                  sm_num_nodes = new("Num Node   ", NUM_NODE_WIDTH, 0, 0);
  OutputComparator #(real, ALPHA_DATA_WIDTH, TOTAL_NODES)                     alpha        = new("Alpha      ", WOI, WOF, 0);

  OutputComparator #(real, NEW_FEATURE_WIDTH, NUM_SUBGRAPHS*NUM_FEATURE_OUT)  new_feature  = new("New Feature", WH_DATA_WIDTH, 32, 0);
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
    spmm.dut_ready              = dut.u_gat_conv1.u_SPMM.spmm_rdy_o;
    spmm.dut_spmm_output        = dut.u_gat_conv1.u_SPMM.sppe;
    spmm.golden_spmm_output     = golden_spmm;
  end

  always_comb begin
    dmvm.dut_ready              = dut.u_gat_conv1.u_DMVM.dut_dmvm_ready;
    dmvm.dut_output             = dut.u_gat_conv1.u_DMVM.dut_dmvm_output;
    dmvm.golden_output          = golden_dmvm;

    coef.dut_ready              = dut.u_gat_conv1.u_DMVM.dmvm_rdy_o;
    coef.dut_output             = dut.u_gat_conv1.u_DMVM.coef_ff_din;
    coef.golden_output          = golden_coef;
  end

  always_comb begin
    dividend.dut_ready          = dut.u_gat_conv1.u_softmax.divd_ff_rd_vld;
    dividend.dut_output         = dut.u_gat_conv1.u_softmax.divd_ff_dout;
    dividend.golden_output      = golden_dividend;

    divisor.dut_ready           = dut.u_gat_conv1.u_softmax.dvsr_ff_wr_vld;
    divisor.dut_output          = dut.u_gat_conv1.u_softmax.sum_reg;
    divisor.golden_output       = golden_divisor;

    sm_num_nodes.dut_ready      = dut.u_gat_conv1.u_softmax.dvsr_ff_wr_vld;
    sm_num_nodes.dut_output     = dut.u_gat_conv1.u_softmax.num_node_reg;
    sm_num_nodes.golden_output  = golden_sm_num_node;

    alpha.dut_ready             = dut.u_gat_conv1.u_softmax.sm_rdy_o;
    alpha.dut_output            = dut.u_gat_conv1.u_softmax.alpha_ff_din;
    alpha.golden_output         = golden_alpha;
  end

  always_comb begin
    new_feature.dut_ready       = dut.u_gat_conv1.u_aggregator.u_feature_controller.feat_bram_ena;
    new_feature.dut_output      = dut.u_gat_conv1.u_aggregator.u_feature_controller.feat_bram_din;
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
    wait(dut.u_gat_conv1.u_SPMM.spmm_vld_i);
    start_time      = $time;
    lat_start_time  = $time;
    for (int i = 0; i < NUM_SUBGRAPHS * NUM_FEATURE_OUT; i++) begin
      c1;
      wait(dut.u_gat_conv1.u_aggregator.u_feature_controller.feat_bram_ena);
      if (i == 0) begin
        lat_end_time = $time;
      end
    end
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