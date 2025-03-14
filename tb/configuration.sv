  //* ============================ Layer 1 ============================
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

  always_comb begin
    spmm.dut_ready              = dut.u_gat_conv1.u_SPMM.spmm_rdy_o;
    spmm.dut_spmm_output        = dut.u_gat_conv1.u_SPMM.sppe;
    spmm.golden_spmm_output     = golden_spmm_conv1;
  end

  always_comb begin
    dmvm.dut_ready              = dut.u_gat_conv1.u_DMVM.dut_dmvm_ready;
    dmvm.dut_output             = dut.u_gat_conv1.u_DMVM.dut_dmvm_output;
    dmvm.golden_output          = golden_dmvm_conv1;

    coef.dut_ready              = dut.u_gat_conv1.u_DMVM.dmvm_rdy_o;
    coef.dut_output             = dut.u_gat_conv1.u_DMVM.coef_ff_din;
    coef.golden_output          = golden_coef_conv1;
  end

  always_comb begin
    dividend.dut_ready          = dut.u_gat_conv1.u_softmax.divd_ff_rd_vld;
    dividend.dut_output         = dut.u_gat_conv1.u_softmax.divd_ff_dout;
    dividend.golden_output      = golden_dividend_conv1;

    divisor.dut_ready           = dut.u_gat_conv1.u_softmax.dvsr_ff_wr_vld;
    divisor.dut_output          = dut.u_gat_conv1.u_softmax.sum_reg;
    divisor.golden_output       = golden_divisor_conv1;

    sm_num_nodes.dut_ready      = dut.u_gat_conv1.u_softmax.dvsr_ff_wr_vld;
    sm_num_nodes.dut_output     = dut.u_gat_conv1.u_softmax.num_node_reg;
    sm_num_nodes.golden_output  = golden_sm_num_node_conv1;

    alpha.dut_ready             = dut.u_gat_conv1.u_softmax.sm_rdy_o;
    alpha.dut_output            = dut.u_gat_conv1.u_softmax.alpha_ff_din;
    alpha.golden_output         = golden_alpha_conv1;
  end

  always_comb begin
    new_feature.dut_ready       = dut.u_gat_conv1.u_aggregator.u_feature_controller.feat_bram_ena;
    new_feature.dut_output      = dut.u_gat_conv1.u_aggregator.u_feature_controller.feat_bram_din;
    new_feature.golden_output   = golden_new_feature_conv1;
  end

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
  //* =================================================================


  //* ============================ Layer 2 ============================
  initial begin
    spmm_conv2.header               = "SPMM";
    dmvm_conv2.header               = "DMVM";
    dividend_conv2.header           = "SOFTMAX";
    new_feature_conv2.header        = "AGGREGATOR";

    spmm_conv2.log_file             = "/SPMM/wh.log";
    dmvm_conv2.log_file             = "/DMVM/dmvm.log";
    coef_conv2.log_file             = "/DMVM/coef.log";
    dividend_conv2.log_file         = "/softmax/dividend.log";
    divisor_conv2.log_file          = "/softmax/divisor.log";
    sm_num_nodes_conv2.log_file     = "/softmax/num_nodes.log";
    alpha_conv2.log_file            = "/softmax/alpha.log";
    new_feature_conv2.log_file      = "/aggregator/new_feature.log";
  end

  always_comb begin
    spmm_conv2.dut_ready              = dut.u_gat_conv2.u_WH.wh_rdy_o;
    spmm_conv2.dut_spmm_output        = dut.u_gat_conv2.u_WH.res_reg;
    spmm_conv2.golden_spmm_output     = golden_spmm_conv2;
  end

  always_comb begin
    dmvm_conv2.dut_ready              = dut.u_gat_conv2.u_DMVM.dut_dmvm_ready;
    dmvm_conv2.dut_output             = dut.u_gat_conv2.u_DMVM.dut_dmvm_output;
    dmvm_conv2.golden_output          = golden_dmvm_conv2;

    coef_conv2.dut_ready              = dut.u_gat_conv2.u_DMVM.dmvm_rdy_o;
    coef_conv2.dut_output             = dut.u_gat_conv2.u_DMVM.coef_ff_din;
    coef_conv2.golden_output          = golden_coef_conv2;
  end

  always_comb begin
    dividend_conv2.dut_ready          = dut.u_gat_conv2.u_softmax.divd_ff_rd_vld;
    dividend_conv2.dut_output         = dut.u_gat_conv2.u_softmax.divd_ff_dout;
    dividend_conv2.golden_output      = golden_dividend_conv2;

    divisor_conv2.dut_ready           = dut.u_gat_conv2.u_softmax.dvsr_ff_wr_vld;
    divisor_conv2.dut_output          = dut.u_gat_conv2.u_softmax.sum_reg;
    divisor_conv2.golden_output       = golden_divisor_conv2;

    sm_num_nodes_conv2.dut_ready      = dut.u_gat_conv2.u_softmax.dvsr_ff_wr_vld;
    sm_num_nodes_conv2.dut_output     = dut.u_gat_conv2.u_softmax.num_node_reg;
    sm_num_nodes_conv2.golden_output  = golden_sm_num_node_conv2;

    alpha_conv2.dut_ready             = dut.u_gat_conv2.u_softmax.sm_rdy_o;
    alpha_conv2.dut_output            = dut.u_gat_conv2.u_softmax.alpha_ff_din;
    alpha_conv2.golden_output         = golden_alpha_conv2;
  end

  always_comb begin
    new_feature_conv2.dut_ready       = dut.u_gat_conv2.u_aggregator.u_feature_controller.feat_bram_ena;
    new_feature_conv2.dut_output      = dut.u_gat_conv2.u_aggregator.u_feature_controller.feat_bram_din;
    new_feature_conv2.golden_output   = golden_new_feature_conv2;
  end

  initial begin
    fork
      spmm_conv2.packed_checker();
      dmvm_conv2.output_checker();
      coef_conv2.output_checker();
      dividend_conv2.output_checker();
      divisor_conv2.output_checker();
      sm_num_nodes_conv2.output_checker();
      alpha_conv2.output_checker(0.0001);
      new_feature_conv2.output_checker(0.01);
    join
  end
  //* =================================================================
