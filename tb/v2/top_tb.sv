`timescale 1ns / 1ps
// `include "checker.sv"
class OutputComparator;
  bit ready_signal;
  int golden_output[];
  int dut_output[];
  int pass_checker;
  int total_checker;
  int N;

  function new(int size);
    N = size;
    pass_checker = 0;
    total_checker = 0;
  endfunction

  task compare_output();
    for (int i = 0; i < N; i++) begin
      #0.01;
      if (golden_output[i] === dut_output[i]) begin
        pass_checker++;
      end
      else begin
        $display("ERROR: error at index [%0d], GOLDEN: %0d \t\t DUT: %0d", i, golden_output[i], dut_output[i]);
      end
      total_checker++;
    end
  endtask

  function void update_inputs(bit ready, int golden[], int dut[]);
    ready_signal = ready;
    golden_output = golden;
    dut_output = dut;
  endfunction
  function void monitor_checker();
    $display("Total Checks: %0d, Passed: %0d", total_checker, pass_checker);
    if (total_checker === pass_checker) begin
      $display("TEST PASSED");
    end else begin
      $display("TEST FAILED");
    end
  endfunction
endclass

module top_tb #(
  //* ========== parameter ===========
  parameter DATA_WIDTH        = 8,
  // -- H
  parameter H_NUM_OF_ROWS			= 100,
  parameter H_NUM_OF_COLS			= 10,
  // -- W
  parameter W_NUM_OF_ROWS			= 10,
  parameter W_NUM_OF_COLS			= 16,
  // -- BRAM
  parameter COL_IDX_DEPTH			= 499,
  parameter VALUE_DEPTH			= 499,
  parameter NODE_INFO_DEPTH			= 100,
  parameter WEIGHT_DEPTH			= 160,
  parameter WH_DEPTH			= 100,
  parameter A_DEPTH			= 32,
  // -- NUM_OF_NODES
  parameter NUM_OF_NODES			= 6,

  //* ========= localparams ==========
  // -- col_idx
  parameter COL_IDX_WIDTH     = $clog2(H_NUM_OF_COLS)                 ,
  parameter COL_IDX_ADDR_W    = $clog2(COL_IDX_DEPTH)                 ,
  // -- value
  parameter VALUE_WIDTH       = DATA_WIDTH                            ,
  parameter VALUE_ADDR_W      = $clog2(VALUE_DEPTH)                   ,
  // -- node_info = [row_len, num_nodes, flag]
  parameter ROW_LEN_WIDTH     = $clog2(H_NUM_OF_COLS)                 ,
  parameter NUM_NODE_WIDTH    = $clog2(NUM_OF_NODES)                  ,
  parameter NODE_INFO_WIDTH   = ROW_LEN_WIDTH + 1 + NUM_NODE_WIDTH + 1,
  parameter NODE_INFO_ADDR_W  = $clog2(NODE_INFO_DEPTH)               ,
  // -- Weight
  parameter WEIGHT_ADDR_W     = $clog2(WEIGHT_DEPTH)                  ,
  parameter WH_DATA_WIDTH     = 12                                    ,
  // -- WH_BRAM
  parameter WH_WIDTH          = WH_DATA_WIDTH * 5 + NUM_NODE_WIDTH + 1,
  parameter WH_ADDR_W         = $clog2(WH_DEPTH)                      ,
  // -- a
  parameter A_ADDR_W          = $clog2(A_DEPTH)
) ();

  logic                             clk                         ;
  logic                             rst_n                       ;

  logic   [COL_IDX_WIDTH-1:0]       H_col_idx_BRAM_din          ;
  logic                             H_col_idx_BRAM_ena          ;
  logic   [COL_IDX_ADDR_W-1:0]      H_col_idx_BRAM_addra        ;
  logic                             H_col_idx_BRAM_enb          ;
  logic   [COL_IDX_ADDR_W-1:0]      H_col_idx_BRAM_addrb        ;
  logic                             H_col_idx_BRAM_load_done    ;

  logic   [VALUE_WIDTH-1:0]         H_value_BRAM_din            ;
  logic                             H_value_BRAM_ena            ;
  logic   [VALUE_ADDR_W-1:0]        H_value_BRAM_addra          ;
  logic                             H_value_BRAM_enb            ;
  logic   [VALUE_ADDR_W-1:0]        H_value_BRAM_addrb          ;
  logic                             H_value_BRAM_load_done      ;

  logic   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_din        ;
  logic                             H_node_info_BRAM_ena        ;
  logic   [NODE_INFO_ADDR_W-1:0]    H_node_info_BRAM_addra      ;
  logic                             H_node_info_BRAM_enb        ;
  logic   [NODE_INFO_ADDR_W-1:0]    H_node_info_BRAM_addrb      ;
  logic                             H_node_info_BRAM_load_done  ;

  logic   [DATA_WIDTH-1:0]          Weight_BRAM_din             ;
  logic                             Weight_BRAM_ena             ;
  logic   [WEIGHT_ADDR_W-1:0]       Weight_BRAM_addra           ;
  logic                             Weight_BRAM_enb             ;
  logic   [WEIGHT_ADDR_W-1:0]       Weight_BRAM_addrb           ;
  logic                             Weight_BRAM_load_done       ;

  logic   [WH_WIDTH-1:0]            WH_BRAM_din                 ;
  logic                             WH_BRAM_ena                 ;
  logic   [WH_ADDR_W-1:0]           WH_BRAM_addra               ;
  logic                             WH_BRAM_enb                 ;
  logic   [WH_ADDR_W-1:0]           WH_BRAM_addrb               ;

  logic   [DATA_WIDTH-1:0]          a_BRAM_din                  ;
  logic                             a_BRAM_ena                  ;
  logic   [A_ADDR_W-1:0]            a_BRAM_addra                ;
  logic                             a_BRAM_enb                  ;
  logic   [A_ADDR_W-1:0]            a_BRAM_addrb                ;
  logic                             a_BRAM_load_done            ;

  top #(
    .DATA_WIDTH       (DATA_WIDTH       ),
    .H_NUM_OF_ROWS    (H_NUM_OF_ROWS    ),
    .H_NUM_OF_COLS    (H_NUM_OF_COLS    ),
    .W_NUM_OF_ROWS    (W_NUM_OF_ROWS    ),
    .W_NUM_OF_COLS    (W_NUM_OF_COLS    ),
    .COL_IDX_DEPTH    (COL_IDX_DEPTH    ),
    .VALUE_DEPTH      (VALUE_DEPTH      ),
    .NODE_INFO_DEPTH  (NODE_INFO_DEPTH  ),
    .WEIGHT_DEPTH     (WEIGHT_DEPTH     ),
    .WH_DEPTH         (WH_DEPTH         ),
    .A_DEPTH          (A_DEPTH          ),
    .NUM_OF_NODES     (NUM_OF_NODES     )
  ) dut (.*);


  integer node_info_file, a_file, weight_file, col_idx_file, value_file;
  integer nd_r, w_r, a_r, value_r, col_idx_r, wh_r;

	localparam string ROOT_PATH = "d:/VLSI/Capstone";

  bit ready_signal;
  logic signed [WH_DATA_WIDTH-1:0]  golden_input[NODE_INFO_DEPTH][16];
  logic signed [WH_DATA_WIDTH-1:0]   dut_output[NODE_INFO_DEPTH][16];
  string line;
  int WH_output_file, line_count, wh_o;
  string file_path;
  string output_file_path;
  OutputComparator comparer;

  //////C///////////////////////////////////
  always #10 clk = ~clk;
  initial begin
    clk       = 1'b1;
    rst_n     = 1'b0;
    #31.01;
    rst_n     = 1'b1;
  end
  ////////////////////////////////////////////


    int i=0;
  initial begin
    //compare
    comparer = new(16);

    output_file_path = $sformatf("%s/tb/outputs/WH.txt", ROOT_PATH);
    WH_output_file = $fopen(output_file_path, "r");
    if(WH_output_file == 0) begin
      $display("FATAL");
      $finish;
    end
    for (int i = 0; i < NODE_INFO_DEPTH; i++) begin
      for (int j = 0; j < 16; j++) begin
        wh_r = $fscanf(WH_output_file, "%d\n", wh_o);
        if (wh_r != 1) begin
          $display("Error or end of file");
          break;
        end
       // $display("HOHO %d", wh_o);
        golden_input[i][j] = wh_o;
      end
    end

      #0.01;
      for(int i = 0; i < NODE_INFO_DEPTH; i++) begin
        wait(dut.u_scheduler.u_SPMM.pe_ready_o == {16{1'b1}});
        for(int j = 0; j < 16;j++) begin
          dut_output[i][j] = dut.u_scheduler.u_SPMM.result[j];
        end
        $display("-----------------------------------COMPARATOR--------------------------------");
        $display("Time %0tps", $time);
        $display("INFO: [Golden] \t%p", golden_input[i]);
        $display("INFO: [DUT] \t%p", dut_output[i]);
        comparer.update_inputs(dut.u_scheduler.u_SPMM.pe_ready_o, golden_input[i], dut_output[i]);
        comparer.compare_output();
        $display("-----------------------------------------------------------------------------");
        #20.02;
      end
    //BUG HERE: dut cannot change.


    #200;
    comparer.monitor_checker();
  end

  initial begin
  end
  // ---------------- Input ----------------
	initial begin
		H_col_idx_BRAM_ena = 1'b1;
		H_col_idx_BRAM_load_done = 1'b0;
		H_value_BRAM_ena = 1'b1;
		H_value_BRAM_load_done = 1'b0;

		H_col_idx_BRAM_ena = 1'b0;
		H_col_idx_BRAM_load_done = 1'b1;
		H_value_BRAM_ena = 1'b0;
		H_value_BRAM_load_done = 1'b1;
	end


	initial begin
    H_node_info_BRAM_ena = 1'b1;
		H_node_info_BRAM_load_done = 1'b0;
		file_path = $sformatf("%s/tb/inputs/node_info.txt", ROOT_PATH);
		//$display(file_path);

    node_info_file = $fopen(file_path, "r");

    //$display("Nodefile %d", node_info_file);
    if (node_info_file == 0) begin
      $display("ERROR: file open failed");
      $finish;
    end
    for (int i = 0; i < NODE_INFO_DEPTH; i++) begin
      nd_r = $fscanf(node_info_file, "%b\n", H_node_info_BRAM_din);  // Read a binary number from the file
      if (nd_r != 1) begin
        $display("Error or end of file");
        break;
      end
      H_node_info_BRAM_addra = i;

      #20.4;
    end
		H_node_info_BRAM_ena = 1'b0;
		H_node_info_BRAM_load_done = 1'b1;

    $fclose(node_info_file);
	end

	initial begin // weight
		Weight_BRAM_ena = 1'b1;
		Weight_BRAM_load_done = 1'b0;

		file_path = $sformatf("%s/tb/inputs/weight.txt", ROOT_PATH);

    weight_file = $fopen(file_path, "r");
    //$display("Weight file %d", weight_file);
    if (weight_file == 0) begin
      $display("ERROR: file open failed");
      $finish;
    end
    for (int k = 0; k < WEIGHT_DEPTH; k++) begin
      w_r = $fscanf(weight_file, "%d\n", Weight_BRAM_din);  // Read a binary number from the file
      //$display(Weight_BRAM_din);
      if (w_r != 1) begin
        $display("Error or end of file");
        break;
      end
      Weight_BRAM_addra = k;
      #20.4;
    end

		Weight_BRAM_ena = 1'b0;
		Weight_BRAM_load_done = 1'b1;
		$fclose(weight_file);
	end

	initial begin
		a_BRAM_ena = 1'b1;
		a_BRAM_load_done = 1'b0;

		file_path = $sformatf("%s/tb/inputs/a.txt", ROOT_PATH);

		a_file = $fopen(file_path, "r");
		if (a_file == 0) begin
			$display("ERROR: file open failed");
			$finish;
		end
		for (int j = 0; j < A_DEPTH; j++) begin
			a_r = $fscanf(a_file, "%d\n", a_BRAM_din);  // Read a binary number from the file
			if (a_r != 1) begin
				$display("Error or end of file aaaasa");
				break;
			end
			a_BRAM_addra = j;
			#20.4;
		end

		a_BRAM_ena = 1'b0;
		a_BRAM_load_done = 1'b1;
		$fclose(a_file);
	end
	// ---------------------------------------

	initial begin // value
		H_value_BRAM_ena = 1'b1;
		H_value_BRAM_load_done = 1'b0;

		file_path = $sformatf("%s/tb/inputs/value.txt", ROOT_PATH);

		value_file = $fopen(file_path, "r");
		if (value_file == 0) begin
			$display("ERROR: file open failed");
			$finish;
		end
		for (int j = 0; j < VALUE_DEPTH; j++) begin
			value_r = $fscanf(value_file, "%d\n", H_value_BRAM_din);  // Read a binary number from the file
			if (value_r != 1) begin
				$display("Error or end of file aaaasa");
				break;
			end
			H_value_BRAM_addra = j;
			#20.4;
		end

		H_value_BRAM_ena = 1'b0;
		H_value_BRAM_load_done = 1'b1;
		$fclose(value_file);
	end

	initial begin // col_idx
		H_col_idx_BRAM_ena = 1'b1;
		H_col_idx_BRAM_load_done = 1'b0;

		file_path = $sformatf("%s/tb/inputs/col_idx.txt", ROOT_PATH);

		col_idx_file = $fopen(file_path, "r");
		if (col_idx_file == 0) begin
			$display("ERROR: file open failed");
			$finish;
		end
		for (int j = 0; j < COL_IDX_DEPTH; j++) begin
			col_idx_r = $fscanf(col_idx_file, "%d\n", H_col_idx_BRAM_din);  // Read a binary number from the file
			if (col_idx_r != 1) begin
				$display("Error or end of file");
				break;
			end
			H_col_idx_BRAM_addra = j;
			#20.4;
		end

		H_col_idx_BRAM_ena = 1'b0;
		H_col_idx_BRAM_load_done = 1'b1;
		$fclose(col_idx_file);
	end

endmodule






