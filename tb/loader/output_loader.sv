// -- Conv1
longint   golden_spmm_conv1         [TOTAL_NODES*NUM_FEATURE_OUT];
longint   golden_dmvm_conv1         [TOTAL_NODES];
longint   golden_coef_conv1         [TOTAL_NODES];
real      golden_dividend_conv1     [TOTAL_NODES];
real      golden_divisor_conv1      [NUM_SUBGRAPHS];
longint   golden_sm_num_node_conv1  [NUM_SUBGRAPHS];
real      golden_alpha_conv1        [TOTAL_NODES];
real      golden_exp_alpha_conv1    [TOTAL_NODES];
real      golden_new_feature_conv1  [NUM_SUBGRAPHS*NUM_FEATURE_OUT];

// -- Conv2
longint   golden_spmm_conv2         [TOTAL_NODES*NUM_FEATURE_FINAL];
longint   golden_dmvm_conv2         [TOTAL_NODES];
longint   golden_coef_conv2         [TOTAL_NODES];
real      golden_dividend_conv2     [TOTAL_NODES];
real      golden_divisor_conv2      [NUM_SUBGRAPHS];
longint   golden_sm_num_node_conv2  [NUM_SUBGRAPHS];
real      golden_alpha_conv2        [TOTAL_NODES];
real      golden_exp_alpha_conv2    [TOTAL_NODES];
real      golden_new_feature_conv2  [NUM_SUBGRAPHS*NUM_FEATURE_FINAL];

task output_loader();
  string  OUTPUT_PATH_CONV1, OUTPUT_PATH_CONV2;
  integer num_feature_out;

  longint status;
  longint spmm_file, dmvm_file, coef_file, alpha_file, dividend_file, divisor_file, sm_num_node_file, exp_alpha_file, new_feature_file;
  longint spmm_value, dmvm_value, coef_value, sm_num_node_value;
  real    dividend_value, divisor_value, alpha_value, exp_alpha_value, new_feature_value;
  string  golden_file_path;

  OUTPUT_PATH_CONV1 = $sformatf("%s/layer_1/output", ROOT_PATH);
  OUTPUT_PATH_CONV2 = $sformatf("%s/layer_2/output", ROOT_PATH);

  // -- Task 1: SPMM / WH
  spmm_file = $fopen($sformatf("%s/SPMM/WH.txt", OUTPUT_PATH_CONV1), "r");
  for (longint i = 0; i < TOTAL_NODES*NUM_FEATURE_OUT; i++) begin
    status = $fscanf(spmm_file, "%d\n", spmm_value);
    golden_spmm_conv1[i] = spmm_value;
  end
  $fclose(spmm_file);
  spmm_file = $fopen($sformatf("%s/SPMM/WH.txt", OUTPUT_PATH_CONV2), "r");
  for (longint i = 0; i < TOTAL_NODES*NUM_FEATURE_FINAL; i++) begin
    status = $fscanf(spmm_file, "%d\n", spmm_value);
    golden_spmm_conv2[i] = spmm_value;
  end
  $fclose(spmm_file);

  // -- Task 2: DMVM
  dmvm_file = $fopen($sformatf("%s/DMVM/dmvm.txt", OUTPUT_PATH_CONV1), "r");
  for (longint i = 0; i < TOTAL_NODES+NUM_SUBGRAPHS; i++) begin
    status = $fscanf(dmvm_file, "%d\n", dmvm_value);
    golden_dmvm_conv1[i] = dmvm_value;
  end
  $fclose(dmvm_file);
  dmvm_file = $fopen($sformatf("%s/DMVM/dmvm.txt", OUTPUT_PATH_CONV2), "r");
  for (longint i = 0; i < TOTAL_NODES; i++) begin
    status = $fscanf(dmvm_file, "%d\n", dmvm_value);
    golden_dmvm_conv2[i] = dmvm_value;
  end
  $fclose(dmvm_file);

  // -- Task 3: COEF
  coef_file = $fopen($sformatf("%s/DMVM/coef.txt", OUTPUT_PATH_CONV1), "r");
  for (longint i = 0; i < TOTAL_NODES; i++) begin
    status = $fscanf(coef_file, "%d\n", coef_value);
    golden_coef_conv1[i] = coef_value;
  end
  $fclose(coef_file);
  coef_file = $fopen($sformatf("%s/DMVM/coef.txt", OUTPUT_PATH_CONV2), "r");
  for (longint i = 0; i < TOTAL_NODES; i++) begin
    status = $fscanf(coef_file, "%d\n", coef_value);
    golden_coef_conv2[i] = coef_value;
  end
  $fclose(coef_file);

  // -- Task 4: ALPHA
  alpha_file = $fopen($sformatf("%s/softmax/alpha.txt", OUTPUT_PATH_CONV1), "r");
  for (int i = 0; i < TOTAL_NODES; i++) begin
    status = $fscanf(alpha_file, "%f\n", alpha_value);
    golden_alpha_conv1[i] = alpha_value;
  end
  $fclose(alpha_file);
  alpha_file = $fopen($sformatf("%s/softmax/alpha.txt", OUTPUT_PATH_CONV2), "r");
  for (int i = 0; i < TOTAL_NODES; i++) begin
    status = $fscanf(alpha_file, "%f\n", alpha_value);
    golden_alpha_conv2[i] = alpha_value;
  end
  $fclose(alpha_file);

  // -- Task 5: DIVIDEND
  dividend_file = $fopen($sformatf("%s/softmax/dividend.txt", OUTPUT_PATH_CONV1), "r");
  for (int i = 0; i < TOTAL_NODES; i++) begin
    status = $fscanf(dividend_file, "%f\n", dividend_value);
    golden_dividend_conv1[i] = dividend_value;
  end
  $fclose(dividend_file);
  dividend_file = $fopen($sformatf("%s/softmax/dividend.txt", OUTPUT_PATH_CONV2), "r");
  for (int i = 0; i < TOTAL_NODES; i++) begin
    status = $fscanf(dividend_file, "%f\n", dividend_value);
    golden_dividend_conv2[i] = dividend_value;
  end
  $fclose(dividend_file);

  // -- Task 6: DIVISOR
  divisor_file = $fopen($sformatf("%s/softmax/divisor.txt", OUTPUT_PATH_CONV1), "r");
  for (int i = 0; i < TOTAL_NODES; i++) begin
    status = $fscanf(divisor_file, "%f\n", divisor_value);
    golden_divisor_conv1[i] = divisor_value;
  end
  $fclose(divisor_file);
  divisor_file = $fopen($sformatf("%s/softmax/divisor.txt", OUTPUT_PATH_CONV2), "r");
  for (int i = 0; i < TOTAL_NODES; i++) begin
    status = $fscanf(divisor_file, "%f\n", divisor_value);
    golden_divisor_conv2[i] = divisor_value;
  end
  $fclose(divisor_file);

  // -- Task 7: NUM_NODE
  sm_num_node_file = $fopen($sformatf("%s/softmax/num_nodes.txt", OUTPUT_PATH_CONV1), "r");
  for (int i = 0; i < TOTAL_NODES; i++) begin
    status = $fscanf(sm_num_node_file, "%f\n", sm_num_node_value);
    golden_sm_num_node_conv1[i] = sm_num_node_value;
  end
  $fclose(sm_num_node_file);
  sm_num_node_file = $fopen($sformatf("%s/softmax/num_nodes.txt", OUTPUT_PATH_CONV2), "r");
  for (int i = 0; i < TOTAL_NODES; i++) begin
    status = $fscanf(sm_num_node_file, "%f\n", sm_num_node_value);
    golden_sm_num_node_conv2[i] = sm_num_node_value;
  end
  $fclose(sm_num_node_file);

  // -- Task 8: NEW_FEATURE
  new_feature_file = $fopen($sformatf("%s/aggregator/new_feature.txt", OUTPUT_PATH_CONV1), "r");
  for (longint i = 0; i < NUM_SUBGRAPHS*NUM_FEATURE_OUT; i++) begin
    status = $fscanf(new_feature_file, "%f\n", new_feature_value);
    golden_new_feature_conv1[i] = new_feature_value;
  end
  $fclose(new_feature_file);
  new_feature_file = $fopen($sformatf("%s/aggregator/new_feature.txt", OUTPUT_PATH_CONV2), "r");
  for (longint i = 0; i < NUM_SUBGRAPHS*NUM_FEATURE_FINAL; i++) begin
    status = $fscanf(new_feature_file, "%f\n", new_feature_value);
    golden_new_feature_conv2[i] = new_feature_value;
  end
  $fclose(new_feature_file);
	$display("[Output ] - Loading completed...");

endtask