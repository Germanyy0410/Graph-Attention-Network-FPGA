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

`include "comparator.sv"

module gat_top_tb import gat_pkg::*;
();
  logic                             clk                         ;
  logic                             rst_n                       ;

  logic   [H_DATA_WIDTH-1:0]        h_data_bram_din             ;
  logic                             h_data_bram_ena             ;
  logic   [H_DATA_ADDR_W-1:0]       h_data_bram_addra           ;
  logic                             h_data_bram_enb             ;
  logic   [H_DATA_ADDR_W-1:0]       h_data_bram_addrb           ;
  logic                             h_data_bram_load_done       ;

  logic   [NODE_INFO_WIDTH-1:0]     h_node_info_bram_din        ;
  logic                             h_node_info_bram_ena        ;
  logic   [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addra      ;
  logic                             h_node_info_bram_enb        ;
  logic   [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addrb      ;
  logic                             h_node_info_bram_load_done  ;

  logic   [DATA_WIDTH-1:0]          wgt_bram_din                ;
  logic                             wgt_bram_ena                ;
  logic   [WEIGHT_ADDR_W-1:0]       wgt_bram_addra              ;
  logic                             wgt_bram_enb                ;
  logic   [WEIGHT_ADDR_W-1:0]       wgt_bram_addrb              ;
  logic                             wgt_bram_load_done          ;

  logic   [DATA_WIDTH-1:0]          a_bram_din                  ;
  logic                             a_bram_ena                  ;
  logic   [A_ADDR_W-1:0]            a_bram_addra                ;
  logic                             a_bram_enb                  ;
  logic   [A_ADDR_W-1:0]            a_bram_addrb                ;
  logic                             a_bram_load_done            ;

  logic   [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addrb             ;
  logic   [DATA_WIDTH-1:0]          feat_bram_dout              ;

  gat_top dut (.*);

  ///////////////////////////////////////////////////////////////////
  always #5 clk = ~clk;
  initial begin
    clk   = 1'b1;
    rst_n = 1'b0;
    #15.01;
    rst_n = 1'b1;
  end
  ///////////////////////////////////////////////////////////////////


  longint start_time, end_time;
  longint lat_start_time, lat_end_time;

  `include "helper/helper.sv"
  `include "loader/input_loader.sv"
  `include "loader/output_loader.sv"


  ///////////////////////////////////////////////////////////////////
  OutputComparator #(longint, WH_DATA_WIDTH, TOTAL_NODES, NUM_FEATURE_OUT)  spmm         = new("WH         ", WH_DATA_WIDTH, 0, 1);

  OutputComparator #(longint, DMVM_DATA_WIDTH, TOTAL_NODES)                 dmvm         = new("DMVM       ", DMVM_DATA_WIDTH, 0, 1);
  OutputComparator #(longint, DATA_WIDTH, TOTAL_NODES)                      coef         = new("COEF       ", DATA_WIDTH, 0, 1);

  OutputComparator #(longint, SM_DATA_WIDTH, TOTAL_NODES)                   dividend     = new("Dividend   ", SM_DATA_WIDTH, 0, 0);
  OutputComparator #(longint, SM_SUM_DATA_WIDTH, NUM_SUBGRAPHS)             divisor      = new("Divisor    ", SM_SUM_DATA_WIDTH, 0, 0);
  OutputComparator #(longint, NUM_NODE_WIDTH, NUM_SUBGRAPHS)                sm_num_nodes = new("SM_NUM_NODE", NUM_NODE_WIDTH, 0, 0);
  OutputComparator #(real, ALPHA_DATA_WIDTH, TOTAL_NODES)                   alpha        = new("Alpha      ", WOI, WOF, 0);
  OutputComparator #(real, ALPHA_DATA_WIDTH, TOTAL_NODES)                   exp_alpha    = new("Exp_Alpha  ", WOI, WOF, 0);

  OutputComparator #(real, NEW_FEATURE_WIDTH, NUM_SUBGRAPHS)                new_feature  = new("New_Feature", NEW_FEATURE_WIDTH, 8, 32);
  ///////////////////////////////////////////////////////////////////


  ///////////////////////////////////////////////////////////////////
  initial begin
    spmm.monitor_path         = "/SPMM/wh.log";
    dmvm.monitor_path         = "/DMVM/dmvm.log";
    coef.monitor_path         = "/DMVM/coef.log";
    dividend.monitor_path     = "/softmax/dividend.log";
    divisor.monitor_path      = "/softmax/divisor.log";
    sm_num_nodes.monitor_path = "/softmax/num_nodes.log";
    alpha.monitor_path        = "/softmax/alpha.log";
    new_feature.monitor_path  = "/aggregator/new_feature.log";
  end
  ///////////////////////////////////////////////////////////////////


  ///////////////////////////////////////////////////////////////////
  always_comb begin
    spmm.dut_ready              = dut.u_SPMM.spmm_rdy_o;
    spmm.dut_spmm_output        = dut.u_SPMM.sppe;
    spmm.golden_spmm_output     = golden_spmm;
  end

  always_comb begin
    dmvm.dut_ready              = dut.u_DMVM.vld_shft_reg[COEF_DELAY_LENGTH-1];
    dmvm.dut_output             = dut.u_DMVM.pipe_prod_reg[NUM_STAGES][0];
    dmvm.golden_output          = golden_dmvm;

    coef.dut_ready              = dut.u_DMVM.dmvm_rdy_o;
    coef.dut_output             = dut.u_DMVM.coef_ff_din;
    coef.golden_output          = golden_coef;
  end

  always_comb begin
    dividend.dut_ready          = dut.u_softmax.divd_ff_rd_vld;
    dividend.dut_output         = dut.u_softmax.divd_ff_dout;
    dividend.golden_output      = golden_dividend;

    divisor.dut_ready           = dut.u_softmax.dvsr_ff_wr_vld;
    divisor.dut_output          = dut.u_softmax.dvsr_ff_din.divisor;
    divisor.golden_output       = golden_divisor;

    sm_num_nodes.dut_ready      = dut.u_softmax.dvsr_ff_wr_vld;
    sm_num_nodes.dut_output     = dut.u_softmax.dvsr_ff_din.num_of_nodes;
    sm_num_nodes.golden_output  = golden_sm_num_node;

    alpha.dut_ready             = dut.u_softmax.sm_rdy_o;
    alpha.dut_output            = dut.u_softmax.alpha_ff_din;
    alpha.golden_output         = golden_alpha;

    exp_alpha.dut_ready         = dut.u_softmax.sm_rdy_o;
    exp_alpha.dut_output        = dut.u_softmax.alpha_ff_din;
    exp_alpha.golden_output     = golden_exp_alpha;
  end

// always_comb begin
  //   new_feature.dut_ready        = dut.u_aggregator.aggr_ready_o;
  //   new_feature.dut_output       = dut.u_aggregator.new_feature;
  //   new_feature.golden_output    = golden_new_feature;
  // end
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
      alpha.output_checker(0.005);
      exp_alpha.output_checker(0.1);
    join
  end
  ///////////////////////////////////////////////////////////////////


  ///////////////////////////////////////////////////////////////////
  initial begin
    #0.1;
    wait(dut.u_SPMM.spmm_vld_i == 1'b1);
    start_time      = $time;
    lat_start_time  = $time;
    for (int i = 0; i < TOTAL_NODES; i++) begin
      #10.01;
      wait(dut.u_softmax.sm_rdy_o == 1'b1);
      if (i == 0) begin
        lat_end_time = $time;
      end
    end
    end_time = $time;

    begin_section;

    spmm.base_monitor();
    dmvm.base_monitor();
    coef.base_monitor();
    dividend.base_monitor();
    sm_num_nodes.base_monitor();
    divisor.base_monitor();
    alpha.base_monitor();

    summary_section;

    $display("\n  SPMM:");
    spmm.base_scoreboard();
    $display("\n  DMVM:");
    dmvm.base_scoreboard();
    coef.base_scoreboard();
    $display("\n  SOFTMAX:");
    dividend.base_scoreboard();
    divisor.base_scoreboard();
    sm_num_nodes.base_scoreboard();
    alpha.base_scoreboard();

    end_section;

  `ifndef VIVADO
    #200;
    $finish();
  `endif
  end
  ///////////////////////////////////////////////////////////////////
endmodule



