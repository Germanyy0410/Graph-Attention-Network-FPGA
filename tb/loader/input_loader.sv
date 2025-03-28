task input_loader();
  string INPUT_PATH;

	integer node_info_file, weight_file, value_file, subgraph_idx_file;
  integer nd_r, w_r, value_r, idx_r;
  string  file_path;
	integer weight_depth, h_data_depth;

	INPUT_PATH = $sformatf("%s/layer_1/input", ROOT_PATH);

		// -- Task 1: Weight & Attention Weight
		begin
			wgt_bram_ena       = 1'b1;
			wgt_bram_wea       = 1'b1;
			wgt_bram_load_done = 1'b0;

			file_path   = $sformatf("%s/weight.txt", INPUT_PATH);
			weight_file = $fopen(file_path, "r");

			for (int i = 0; i < WEIGHT_DEPTH; i++) begin
				w_r = $fscanf(weight_file, "%b\n", wgt_bram_din);
				wgt_bram_addra = i;
				c1;
			end

			$display("[ Input ] - Weight Compeleted...");

			wgt_bram_ena       = 1'b0;
			wgt_bram_wea       = 1'b0;
			wgt_bram_load_done = 1'b1;

			$fclose(weight_file);
		end

		// -- Task 2: Node-Info
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

			$display("[ Input ] - Node Info Compeleted...");

			h_node_info_bram_ena        = 1'b0;
			h_node_info_bram_wea        = 1'b0;
			h_node_info_bram_load_done  = 1'b1;

			$fclose(node_info_file);
		end

		// -- Task 3: H Data
		begin
			c1;
			h_data_bram_ena_conv1 = 1'b1;
			h_data_bram_wea_conv1	= 1'b1;
			h_data_bram_load_done = 1'b0;

			file_path   = $sformatf("%s/h_data.txt", INPUT_PATH);
			value_file  = $fopen(file_path, "r");

			for (int i = 0; i < H_DATA_DEPTH; i++) begin
				value_r = $fscanf(value_file, "%b\n", h_data_bram_din_conv1);
				h_data_bram_addra_conv1 = i;
				c1;
			end

			$display("[ Input ] - H Data Compeleted...");

			h_data_bram_ena_conv1 = 1'b0;
			h_data_bram_wea_conv1	= 1'b0;
			h_data_bram_load_done = 1'b1;

			$fclose(value_file);
		end

		// -- Task 4: Subgraph Index
		begin
			c1;
			subgraph_bram_ena = 1'b1;
			subgraph_bram_wea	= 1'b1;

			file_path = $sformatf("%s/graph_index.txt", INPUT_PATH);
			subgraph_idx_file = $fopen(file_path, "r");

			for (int i = 0; i < TOTAL_NODES; i++) begin
				idx_r = $fscanf(subgraph_idx_file, "%b\n", subgraph_bram_din);
				subgraph_bram_addra = i;
				c1;
			end

			$display("[ Input ] - Subgraph Index Compeleted...");

			subgraph_bram_ena = 1'b0;
			subgraph_bram_wea	= 1'b0;

			$fclose(subgraph_idx_file);
		end

	$display("[ Input ] - Loading completed...");
endtask
