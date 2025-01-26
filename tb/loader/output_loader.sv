
  longint   golden_spmm         [TOTAL_NODES*NUM_FEATURE_OUT];

  longint   golden_dmvm         [TOTAL_NODES];
  longint   golden_coef         [TOTAL_NODES];

  real      golden_dividend     [TOTAL_NODES];
  real      golden_divisor      [NUM_SUBGRAPHS];
  longint   golden_sm_num_node  [NUM_SUBGRAPHS];
  real      golden_alpha        [TOTAL_NODES];
  real      golden_exp_alpha    [TOTAL_NODES];

  real      golden_new_feature  [NUM_SUBGRAPHS*NUM_FEATURE_OUT];

  longint status;
  longint spmm_file, dmvm_file, coef_file, alpha_file, dividend_file, divisor_file, sm_num_node_file, exp_alpha_file, new_feature_file ;
  longint spmm_value, dmvm_value, coef_value, sm_num_node_value;
  real    dividend_value, divisor_value, alpha_value, exp_alpha_value, new_feature_value;
  string  golden_file_path;

  initial begin
    spmm_file = $fopen($sformatf("%s/SPMM/wh.txt", GOLDEN_PATH), "r");
    for (longint i = 0; i < TOTAL_NODES*NUM_FEATURE_OUT; i++) begin
      status = $fscanf(spmm_file, "%d\n", spmm_value);
      golden_spmm[i] = spmm_value;
    end
    $fclose(spmm_file);
  end

  initial begin
    dmvm_file = $fopen( $sformatf("%s/DMVM/dmvm.txt", GOLDEN_PATH), "r");
    for (longint i = 0; i < TOTAL_NODES; i++) begin
      status = $fscanf(dmvm_file, "%d\n", dmvm_value);
      golden_dmvm[i] = dmvm_value;
    end
    $fclose(dmvm_file);
  end

  initial begin
    coef_file = $fopen($sformatf("%s/DMVM/coef.txt", GOLDEN_PATH), "r");
    for (longint i = 0; i < TOTAL_NODES; i++) begin
      status = $fscanf(coef_file, "%d\n", coef_value);
      golden_coef[i] = coef_value;
    end
    $fclose(coef_file);
  end

  initial begin
    alpha_file = $fopen($sformatf("%s/softmax/alpha.txt", GOLDEN_PATH), "r");
    for (int i = 0; i < TOTAL_NODES; i++) begin
      status = $fscanf(alpha_file, "%f\n", alpha_value);
      golden_alpha[i] = alpha_value;
    end
    $fclose(alpha_file);
  end

  initial begin
    dividend_file = $fopen($sformatf("%s/softmax/dividend.txt", GOLDEN_PATH), "r");
    for (int i = 0; i < TOTAL_NODES; i++) begin
      status = $fscanf(dividend_file, "%f\n", dividend_value);
      golden_dividend[i] = dividend_value;
    end
    $fclose(dividend_file);
  end

  initial begin
    divisor_file = $fopen($sformatf("%s/softmax/divisor.txt", GOLDEN_PATH), "r");
    for (int i = 0; i < TOTAL_NODES; i++) begin
      status = $fscanf(divisor_file, "%f\n", divisor_value);
      golden_divisor[i] = divisor_value;
    end
    $fclose(divisor_file);
  end

  initial begin
    sm_num_node_file = $fopen($sformatf("%s/softmax/num_nodes.txt", GOLDEN_PATH), "r");
    for (int i = 0; i < TOTAL_NODES; i++) begin
      status = $fscanf(sm_num_node_file, "%f\n", sm_num_node_value);
      golden_sm_num_node[i] = sm_num_node_value;
    end
    $fclose(sm_num_node_file);
  end

  initial begin
    exp_alpha_file = $fopen($sformatf("%s/softmax/exp_alpha.txt", GOLDEN_PATH), "r");
    for (int i = 0; i < TOTAL_NODES; i++) begin
      status = $fscanf(exp_alpha_file, "%f\n", exp_alpha_value);
      golden_exp_alpha[i] = exp_alpha_value;
    end
    $fclose(exp_alpha_file);
  end

  initial begin
    new_feature_file = $fopen($sformatf("%s/aggregator/new_feature.txt", GOLDEN_PATH), "r");
    for (longint i = 0; i < NUM_SUBGRAPHS*NUM_FEATURE_OUT; i++) begin
      status = $fscanf(new_feature_file, "%f\n", new_feature_value);
      golden_new_feature[i] = new_feature_value;
    end
    $fclose(new_feature_file);
  end