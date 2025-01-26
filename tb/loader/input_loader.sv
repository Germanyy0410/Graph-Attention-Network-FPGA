
  integer node_info_file, a_file, weight_file, value_file;
  integer nd_r, w_r, a_r, value_r;
  string file_path;

  initial begin
    h_node_info_bram_ena        = 1'b1;
		h_node_info_bram_load_done  = 1'b0;

		file_path       = $sformatf("%s/node_info.txt", INPUT_PATH);
    node_info_file  = $fopen(file_path, "r");

    for (int i = 0; i < NODE_INFO_DEPTH; i++) begin
      nd_r = $fscanf(node_info_file, "%b\n", h_node_info_bram_din);
      h_node_info_bram_addra = i;
      c1;
    end

		h_node_info_bram_ena        = 1'b0;
		h_node_info_bram_load_done  = 1'b1;

    $fclose(node_info_file);
	end

	initial begin
		wgt_bram_ena       = 1'b1;
		wgt_bram_load_done = 1'b0;

		file_path   = $sformatf("%s/weight.txt", INPUT_PATH);
    weight_file = $fopen(file_path, "r");

    for (int i = 0; i < WEIGHT_DEPTH; i++) begin
      w_r = $fscanf(weight_file, "%d\n", wgt_bram_din);
      wgt_bram_addra = i;
      c1;
    end

		wgt_bram_ena       = 1'b0;
		wgt_bram_load_done = 1'b1;

		$fclose(weight_file);
	end

	initial begin
		a_bram_ena        = 1'b1;
		a_bram_load_done  = 1'b0;

		file_path = $sformatf("%s/a.txt", INPUT_PATH);
		a_file    = $fopen(file_path, "r");

		for (int i = 0; i < A_DEPTH; i++) begin
			a_r = $fscanf(a_file, "%d\n", a_bram_din);
			a_bram_addra = i;
			c1;
		end

		a_bram_ena        = 1'b0;
		a_bram_load_done  = 1'b1;
		$fclose(a_file);
	end

	initial begin
		h_data_bram_ena       = 1'b1;
		h_data_bram_load_done = 1'b0;

		file_path   = $sformatf("%s/h_data.txt", INPUT_PATH);
		value_file  = $fopen(file_path, "r");

		for (int i = 0; i < H_DATA_DEPTH; i++) begin
			value_r = $fscanf(value_file, "%b\n", h_data_bram_din);
			h_data_bram_addra = i;
			c1;
		end

		h_data_bram_ena       = 1'b0;
		h_data_bram_load_done = 1'b1;

		$fclose(value_file);
	end