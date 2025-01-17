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

`ifndef VIVADO
  `include "D:/VLSI/Capstone/rtl/inc/gat_pkg.sv"
`endif

localparam string MONITOR_PATH  = { ROOT_PATH, "/monitor" };

class OutputComparator #(type T = longint, parameter DATA_WIDTH = 8, parameter DEPTH = 256, parameter SPMM_DEPTH = 16);
  logic                                           dut_ready;

  logic        [DATA_WIDTH-1:0]                   dut_output;
  T                                               golden_output       [DEPTH];

  logic signed [SPMM_DEPTH-1:0] [DATA_WIDTH-1:0]  dut_spmm_output;
  T                                               golden_spmm_output  [DEPTH*SPMM_DEPTH];

  string  label;
  string  monitor;
  string  monitor_path;

  longint pass_checker;
  longint total_checker;

  longint int_bits;
  longint frac_bits;

  longint comparator;

  longint signed_bit;
  longint dec_dut_output;
  real    real_dut_output;

  function new (string label, int int_bits, int frac_bits, int signed_bit);
    this.monitor        = "";
    this.pass_checker   = 0;
    this.total_checker  = 0;
    this.comparator     = 0;
    this.label          = label;
    this.int_bits       = int_bits;
    this.frac_bits      = frac_bits;
    this.signed_bit     = signed_bit;
  endfunction

  task output_checker(real error = 0);
    string msg = "";

    for (int i = 0; i < DEPTH; i++) begin
      #0.1;
      wait(dut_ready == 1'b1);

      real_dut_output = fxp_to_dec();

      if (error == 0) begin
        comparator      = (signed_bit) ? ($signed(dut_output) == golden_output[i]) : (dut_output == golden_output[i]);
        real_dut_output = (signed_bit) ? $signed(dut_output) : dut_output;
      end else begin
        comparator = (real_dut_output - golden_output[i]) <= (error * golden_output[i]);
      end

      if (comparator) begin
        pass_checker++;
      `ifdef PASSED
        monitor = { monitor, $sformatf("\n%s -> %s - %0t ps\n", pass, rm_spc(label), $time) };
        monitor = { monitor, $sformatf("\t\t- Golden = %0d\n\t\t- DUT    = %0d\n", golden_output[i], real_dut_output) };
      `endif
      end else begin
      `ifdef FAILED
        monitor = { monitor, $sformatf("\n%s -> %s - %0t ps\n", fail, rm_spc(label), $time) };
        if (frac_bits == 0) begin
          monitor = { monitor, $sformatf("\t\t- Golden = %0d\n\t\t- DUT    = %0d, [i] = %0d\n", golden_output[i], real_dut_output, i) };
        end else begin
          monitor = { monitor, $sformatf("\t\t- Golden = %0.15f\n\t\t- DUT    = %0.15f\n", golden_output[i], real_dut_output) };
        end
      `endif
      end
      total_checker++;
      #10.01;
    end
  endtask

  task packed_checker();
    for (int i = 0; i < DEPTH; i++) begin
      logic signed [DATA_WIDTH-1:0] golden_temp   [SPMM_DEPTH];
      logic signed [DATA_WIDTH-1:0] dut_temp      [SPMM_DEPTH];

      #0.1;
      wait(dut_ready == 1'b1);

      for (int j = 0; j < SPMM_DEPTH; j++) begin
        dut_temp[j] = dut_spmm_output[j];
        if (dut_temp[j] == golden_spmm_output[i * SPMM_DEPTH + j]) begin
          pass_checker++;
        end
        total_checker++;
        golden_temp[j] = golden_spmm_output[i * SPMM_DEPTH + j];
      end

      if (pass_checker == total_checker) begin
      `ifdef PASSED
        monitor = { monitor, $sformatf("\n%s -> %s - %0t ps\n", pass, rm_spc(label), $time) };
        monitor = { monitor, $sformatf("\t- Golden = %p\n\t- DUT    = %p\n", golden_temp, dut_temp) };
      `endif
      end else begin
      `ifdef FAILED
        monitor = { monitor, $sformatf("\n%s -> %s - %0t ps\n", fail, rm_spc(label), $time) };
        monitor = { monitor, $sformatf("\t- Golden = %p\n\t- DUT    = %p\n", golden_temp, dut_temp) };
      `endif
      end
      #10.01;
    end
  endtask

  task base_monitor();
    if (monitor != "") begin
      $display("\n---------------------------ooOoo----------------------------");
      $display("%s", monitor);
      $display("---------------------------ooOoo----------------------------\n");
    end
  endtask

  task base_scoreboard();
    int accuracy = pass_checker * 100 / total_checker;
    string color = (accuracy == 100) ? green : red;
  `ifndef VIVADO
    $display("     - %s     : %5d | %5d\t(%s%0d%%%s)", label, pass_checker, total_checker, color, accuracy, reset );
  `else
    $display("     - %s     : %5d | %5d\t(%0d%%)", label, pass_checker, total_checker, accuracy );
  `endif
    export_monitor();
  endtask

  task export_monitor();
    integer file;
    file = $fopen($sformatf("%s/%s", MONITOR_PATH, monitor_path), "w");
    if (file == 0) $error("Monitor: Failed to open %s", monitor_path);

    $fwrite(file, "%s\n", monitor);
    $fclose(file);
  endtask

  function real fxp_to_dec();
    real scaled_factor = 2.0 ** frac_bits;
    return $itor($signed(dut_output)) / scaled_factor;
  endfunction

  function real abs(real value);
    return (value < 0.0) ? -value : value;
  endfunction

  function string rm_spc(string input_string);
    string output_string = "";
    for (int i = 0; i < input_string.len(); i++) begin
      if (input_string[i] != " ") begin
        output_string = {output_string, input_string[i]};
      end
    end
    return output_string;
  endfunction

endclass

