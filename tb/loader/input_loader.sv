  integer node_info_file, a_file, weight_file, value_file;
  integer nd_r, w_r, a_r, value_r;
  string file_path;

	localparam string INPUT_PATH  = "D:/VLSI/Capstone/tb/input";

  initial begin
    H_node_info_BRAM_ena        = 1'b1;
		H_node_info_BRAM_load_done  = 1'b0;

		file_path       = $sformatf("%s/node_info.txt", INPUT_PATH);
    node_info_file  = $fopen(file_path, "r");

    for (int i = 0; i < NODE_INFO_DEPTH; i++) begin
      nd_r = $fscanf(node_info_file, "%b\n", H_node_info_BRAM_din);
      H_node_info_BRAM_addra = i;
      #10.4;
    end

		H_node_info_BRAM_ena        = 1'b0;
		H_node_info_BRAM_load_done  = 1'b1;

    $fclose(node_info_file);
	end

	initial begin
		Weight_BRAM_ena       = 1'b1;
		Weight_BRAM_load_done = 1'b0;

		file_path   = $sformatf("%s/weight.txt", INPUT_PATH);
    weight_file = $fopen(file_path, "r");

    for (int i = 0; i < WEIGHT_DEPTH; i++) begin
      w_r = $fscanf(weight_file, "%d\n", Weight_BRAM_din);
      Weight_BRAM_addra = i;
      #10.4;
    end

		Weight_BRAM_ena       = 1'b0;
		Weight_BRAM_load_done = 1'b1;

		$fclose(weight_file);
	end

	initial begin
		a_BRAM_ena        = 1'b1;
		a_BRAM_load_done  = 1'b0;

		file_path = $sformatf("%s/a.txt", INPUT_PATH);
		a_file    = $fopen(file_path, "r");

		for (int i = 0; i < A_DEPTH; i++) begin
			a_r = $fscanf(a_file, "%d\n", a_BRAM_din);
			a_BRAM_addra = i;
			#10.4;
		end

		a_BRAM_ena        = 1'b0;
		a_BRAM_load_done  = 1'b1;
		$fclose(a_file);
	end

	initial begin
		H_data_BRAM_ena       = 1'b1;
		H_data_BRAM_load_done = 1'b0;

		file_path   = $sformatf("%s/h_data.txt", INPUT_PATH);
		value_file  = $fopen(file_path, "r");

		for (int i = 0; i < H_DATA_DEPTH; i++) begin
			value_r = $fscanf(value_file, "%b\n", H_data_BRAM_din);
			H_data_BRAM_addra = i;
			#10.4;
		end

		H_data_BRAM_ena       = 1'b0;
		H_data_BRAM_load_done = 1'b1;

		$fclose(value_file);
	end