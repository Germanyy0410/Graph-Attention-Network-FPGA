task input_loader();
  string INPUT_PATH;

	integer node_info_file, weight_file, value_file;
  integer nd_r, w_r, value_r;
  string  file_path;
	integer weight_depth, h_data_depth;

	INPUT_PATH = (gat_layer == 1'b0) ? $sformatf("%s/layer_1/input", ROOT_PATH) : $sformatf("%s/layer_2/input", ROOT_PATH);

		// -- Task 1: Node-Info
		begin
			c1;
			h_node_info_bram_ena        = 1'b1;
			h_node_info_bram_wea        = 1'b1;
			h_node_info_bram_load_done  = 1'b0;

			file_path       = $sformatf("%s/node_info.txt", INPUT_PATH);
			node_info_file  = $fopen(file_path, "r");

			for (int i = 0; i < NODE_INFO_DEPTH; i++) begin
				nd_r = $fscanf(node_info_file, "%b\n", h_node_info_bram_din);
				h_node_info_bram_addra = i;
				c1;
			end

			$display("NODE_INFO FINISH");

			h_node_info_bram_ena        = 1'b0;
			h_node_info_bram_wea        = 1'b0;
			h_node_info_bram_load_done  = 1'b1;

			$fclose(node_info_file);
		end

		// -- Task 2: Weight & Attention Weight
		begin
			wgt_bram_ena       = 1'b1;
			wgt_bram_wea       = 1'b1;
			wgt_bram_load_done = 1'b0;

			file_path   = $sformatf("%s/weight.txt", INPUT_PATH);
			weight_file = $fopen(file_path, "r");

			if (gat_layer == 1'b0) begin
				weight_depth = NUM_FEATURE_IN * NUM_FEATURE_OUT + NUM_FEATURE_OUT * 2;
			end else if (gat_layer == 1'b1) begin
				weight_depth = NUM_FEATURE_OUT * NUM_FEATURE_FINAL + NUM_FEATURE_FINAL * 2;
			end

			for (int i = 0; i < weight_depth; i++) begin
				w_r = $fscanf(weight_file, "%b\n", wgt_bram_din);
				wgt_bram_addra = i;
				c1;
			end

			$display("WEIGHT FINISH");

			wgt_bram_ena       = 1'b0;
			wgt_bram_wea       = 1'b0;
			wgt_bram_load_done = 1'b1;

			$fclose(weight_file);
		end

		// -- Task 3: H Data
		begin
			c1;
			h_data_bram_ena       = 1'b1;
			h_data_bram_wea       = 1'b1;
			h_data_bram_load_done = 1'b0;

			file_path   = $sformatf("%s/h_data.txt", INPUT_PATH);
			value_file  = $fopen(file_path, "r");

			if (gat_layer == 1'b0) begin
				h_data_depth = H_DATA_DEPTH;
			end else if (gat_layer == 1'b1) begin
				h_data_depth = 212224;
			end

			for (int i = 0; i < h_data_depth; i++) begin
				if (gat_layer == 1'b0) begin
					value_r = $fscanf(value_file, "%b\n", h_data_bram_din);
				end else if (gat_layer == 1'b1) begin
					value_r = $fscanf(value_file, "%b\n", h_data_bram_din);
				end
				h_data_bram_addra = i;
				c1;
			end

			$display("H_DATA FINISH");

			h_data_bram_ena       = 1'b0;
			h_data_bram_wea       = 1'b0;
			h_data_bram_load_done = 1'b1;

			$fclose(value_file);
		end

	$display("DEBUG FINISH");
endtask
