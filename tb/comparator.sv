// `include "./loader/output_loader.sv"

`ifdef VIVADO
  string pass = "[PASSED]";
  string fail = "[FAILED]";
`else
  string pass = "\033[32m[PASSED]\033[0m";
  string fail = "\033[31m[FAILED]\033[0m";
`endif


string red    = "\033[31m";
string green  = "\033[32m";
string reset  = "\033[0m";

string summary_log = "";
string log_divider = "-------------------------";

class OutputComparator #(type T = longint, parameter DATA_WIDTH = 8, parameter DEPTH = 256, parameter SPMM_DEPTH = 16);
  logic dut_ready;

  logic [DATA_WIDTH-1:0] dut_output;
  T golden_output [DEPTH];

  logic signed [SPMM_DEPTH-1:0] [DATA_WIDTH-1:0] dut_spmm_output;
  T golden_spmm_output [DEPTH*SPMM_DEPTH];

  string  label;
  string  header;
  string  log_file;

  longint pass_checker;
  longint total_checker;

  longint int_bits;
  longint frac_bits;

  longint comparator;

  longint signed_bit;
  real    real_dut_output;

  longint node_count;
  longint subgraph_count;

  function new(string label, int int_bits, int frac_bits, int signed_bit);
    this.header         = "";
    this.pass_checker   = 0;
    this.total_checker  = 0;
    this.comparator     = 0;
    this.label          = label;
    this.int_bits       = int_bits;
    this.frac_bits      = frac_bits;
    this.signed_bit     = signed_bit;
  endfunction

  //=========================================================================
  // Task Name        : output_checker
  // Description      : Compares the DUT output with the golden output and logs results.
  // Parameters       :
  //    - real error (default = 0) : Allowed error margin for floating-point comparisons.
  // Notes            : Supports both integer and floating-point comparisons, handles subgraph logic.
  //=========================================================================
  task output_checker(real error = 0);
    log_checker("", "clear");
    subgraph_count = 0;

    for (int i = 0; i < DEPTH; i++) begin
      string msg;
      if (i == 0) begin
        msg = $sformatf("\n%s Subgraph 0 %s\n\n", log_divider, log_divider);
      end else begin
        msg = "";
      end
      wait(dut_ready);

      // Compare DUT & Golden
      if (error == 0) begin
        real_dut_output = (signed_bit) ? $signed(dut_output) : dut_output;
        comparator      = (signed_bit) ? ($signed(dut_output) == golden_output[i]) : (dut_output == golden_output[i]);
      end else begin
        real_dut_output = fxp_to_dec();
        comparator      = abs(real_dut_output - golden_output[i]) <= error;
      end

      // Comparison result
      if (comparator) begin
        pass_checker++;
        msg = { msg, $sformatf("%s -> %s - %0tps | [i] = %0d\n", pass, rm_spc(label), $time, i) };
        if (frac_bits == 0) begin
          if (signed_bit) msg = { msg, $sformatf("\t\t- Golden = %0f\n\t\t- DUT    = %0f\n", golden_output[i], $signed(dut_output)) };
          else msg = { msg, $sformatf("\t\t- Golden = %0f\n\t\t- DUT    = %0f\n", golden_output[i], real_dut_output) };
        end else begin
          msg = { msg, $sformatf("\t\t- Golden = %0.15f\n\t\t- DUT    = %0.15f\n", golden_output[i], real_dut_output) };
          msg = { msg, $sformatf("\t\t- Diff   = %0.15f\n", abs(real_dut_output - golden_output[i])) };
        end
      end else begin
        msg = { msg, $sformatf("%s -> %s - %0tps | [i] = %0d\n", fail, rm_spc(label), $time, i) };
        if (frac_bits == 0) begin
          if (signed_bit) msg = { msg, $sformatf("\t\t- Golden = %0d\n\t\t- DUT    = %0d\n", golden_output[i], $signed(dut_output)) };
          else msg = { msg, $sformatf("\t\t- Golden = %0d\n\t\t- DUT    = %0d\n", golden_output[i], real_dut_output) };
        end else begin
          msg = { msg, $sformatf("\t\t- Golden = %0.15f\n\t\t- DUT    = %0.15f\n", golden_output[i], real_dut_output) };
          msg = { msg, $sformatf("\t\t- Diff   = %0.15f\n", abs(real_dut_output - golden_output[i])) };
        end
      end
      total_checker++;

      // Split into subgraphs
      if (label == "DMVM       ") begin
        if (i == 0) begin
          node_count = golden_sm_num_node_conv1[0] + 1;
        end
        if (i == node_count - 1) begin
          subgraph_count++;
          node_count += golden_sm_num_node_conv1[subgraph_count] + 1;
          msg = { msg, $sformatf("\n%s Subgraph %0d %s\n", log_divider, subgraph_count, log_divider) };
        end
      end
      else if (label == "Divisor    " || label == "Num Node   ") begin
        msg = { msg, $sformatf("\n%s Subgraph %0d %s\n", log_divider, i + 1, log_divider) };
      end
      else if (label == "New Feature") begin
        if ((i + 1) % NUM_FEATURE_OUT == 0) begin
          msg = { msg, $sformatf("\n%s Subgraph %0d %s\n", log_divider, (i + 1) / NUM_FEATURE_OUT, log_divider) };
        end
      end
      else begin
        if (i == 0) begin
          node_count = golden_sm_num_node_conv1[0];
        end
        if (i == node_count - 1) begin
          subgraph_count++;
          node_count += golden_sm_num_node_conv1[subgraph_count];
          msg = { msg, $sformatf("\n%s Subgraph %0d %s\n", log_divider, subgraph_count, log_divider) };
        end
      end

      // Log result
    `ifdef PASSED
      log_checker(msg);
    `else
      if (!comparator) log_checker(msg);
    `endif

      c1;
    end
  endtask

  //=========================================================================
  // Task Name        : packed_checker
  // Description      : Compares packed DUT output (multi-dimensional array) with
  //                    the golden output and logs results.
  // Parameters       : None
  // Usage            : Handles multi-dimensional comparisons.
  //=========================================================================
  task packed_checker();
    log_checker("", "clear");
    subgraph_count  = 0;
    node_count      = golden_sm_num_node_conv1[0];

    for (int i = 0; i < DEPTH; i++) begin
      logic signed [DATA_WIDTH-1:0]   golden_temp   [SPMM_DEPTH];
      logic signed [DATA_WIDTH-1:0]   dut_temp      [SPMM_DEPTH];
      string msg = "";
      int num_pass = 0, num_total = 0;
      if (i == 0) begin
        msg = { msg, $sformatf("\n%s Subgraph 0 %s\n\n", log_divider, log_divider) };
      end
      wait(dut_ready);

      // Compare DUT & Golden
      for (int j = 0; j < SPMM_DEPTH; j++) begin
        dut_temp[j] = dut_spmm_output[j];
        if (dut_temp[j] == golden_spmm_output[i * SPMM_DEPTH + j]) begin
          num_pass++;
        end
        num_total++;
        golden_temp[j] = golden_spmm_output[i * SPMM_DEPTH + j];
      end

      // Comparison result
      if (num_pass == num_total) begin
        pass_checker++;
        msg = { msg, $sformatf("%s -> %s - %0tps | [i] = %0d\n", pass, rm_spc(label), $time, i) };
        msg = { msg, $sformatf("\t- Golden = %p\n\t- DUT    = %p\n,", golden_temp, dut_temp) };
      end else begin
        msg = { msg, $sformatf("%s -> %s - %0tps\n", fail, rm_spc(label), $time) };
        msg = { msg, $sformatf("\t- Golden = %p\n\t- DUT    = %p\n", golden_temp, dut_temp) };
      end
      total_checker++;

      // Split into subgraphs
      if (i == node_count - 1) begin
        subgraph_count++;
        node_count += golden_sm_num_node_conv1[subgraph_count];
        msg = { msg, $sformatf("\n%s Subgraph %0d %s\n", log_divider, subgraph_count, log_divider) };
      end

      // Log result
    `ifdef PASSED
      log_checker(msg);
    `else
      if (num_pass != num_total) log_checker(msg);
    `endif

      c1;
    end
  endtask

  //=========================================================================
  // Task Name        : base_scoreboard
  // Description      : Summarizes the pass/fail results and displays the overall accuracy.
  // Parameters       : None
  // Usage            : Displays and logs the pass/fail statistics for the DUT.
  //=========================================================================
  task base_scoreboard();
    int     accuracy  = pass_checker * 100 / total_checker;
    string  color     = (accuracy == 100) ? green : red;
    string  result    = "";

    // Display checker header
    if (header != "") begin
      header = $sformatf("\n  %s:", header);
      $display(header);
      summary_log = { summary_log, $sformatf("%s\n", header) };
    end

    // Simulation results
  `ifndef VIVADO
    result = $sformatf("     - %s     : %5d | %5d\t(%s%0d%%%s)", label, pass_checker, total_checker, color, accuracy, reset );
  `else
    result = $sformatf("     - %s     : %5d | %5d\t(%0d%%)", label, pass_checker, total_checker, accuracy );
  `endif

    summary_log = { summary_log, $sformatf("%s\n", result) };
    $display(result);
  endtask

  //=========================================================================
  // Task Name        : log_checker
  // Description      : Logs messages to a file, with options to append or overwrite.
  // Parameters       :
  //    - string msg    : Message to be logged.
  //    - string option : Logging mode ("update" for appending, "clear" for overwriting).
  //=========================================================================
  task log_checker(string msg, string option="update");
    integer file;

    if (option == "update") begin
      file = $fopen($sformatf("%s/%s", LOG_PATH, log_file), "a");
    end else if (option == "clear") begin
      file = $fopen($sformatf("%s/%s", LOG_PATH, log_file), "w");
    end
    if (file == 0) $error("Monitor: Failed to open %s", log_file);

    $fwrite(file, "%s\n", msg);
    $fclose(file);
  endtask

  //=========================================================================
  // Function Name    : fxp_to_dec
  // Description      : Converts a fixed-point value (DUT output) into a decimal (real) value.
  // Parameters       : None
  // Return Value     : real : The decimal value of the DUT output.
  //=========================================================================
  function real fxp_to_dec();
    real scaled_factor = 2.0 ** frac_bits;
    return $itor($signed(dut_output)) / scaled_factor;
  endfunction

endclass

