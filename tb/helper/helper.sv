task automatic c1;
  begin
      @(posedge clk);
      #0.1;
  end
endtask

task automatic c2;
  begin
    @(negedge clk);
    #0.1;
  end
endtask

task automatic c3;
  begin
    #0.1;
  end
endtask

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

`ifdef VIVADO
  string begin_str    = "BEGIN";
  string summary_str  = "REPORT SUMMARY";
  string end_str      = "END";
`else
  string begin_str    = "\033[38;5;220mBEGIN\033[0m";
  string summary_str  = "\033[38;5;220mREPORT SUMMARY\033[0m";
  string end_str      = "\033[38;5;220mEND\033[0m";
`endif

real    total_latency, total_time;
string  content  = "";
longint start_time, end_time, lat_start_time, lat_end_time;
integer file;

task begin_section;
  $display("------------------------------------------------------------");
  $display("|                         %s                            |", begin_str);
  $display("------------------------------------------------------------");
endtask

task summary_section;
  total_time      = (end_time - start_time) / 10.0;
  total_latency   = (lat_end_time - lat_start_time) / 10.0;

  begin_section;
  content = { content, $sformatf("\n------------------------------------------------------------") };
  content = { content, $sformatf("\n|                    %s                        |", summary_str) };
  content = { content, $sformatf("\n------------------------------------------------------------") };
  content = { content, $sformatf("\n  TOTAL NODES   = %6d\tNUM_FEATURE_IN  = %0d", TOTAL_NODES, NUM_FEATURE_IN) };
  content = { content, $sformatf("\n  NUM_SUBGRAPHS = %6d\tNUM_FEATURE_OUT = %0d", NUM_SUBGRAPHS, NUM_FEATURE_OUT) };
  content = { content, $sformatf("\n  MAX_NODES     = %6d\tNUM_SPARSE_DATA = %0d", MAX_NODES, H_NUM_SPARSE_DATA) };
  content = { content, $sformatf("\n------------------------------------------------------------") };
  content = { content, $sformatf("\n  Time    = %6d cycles   (%0d us - %0d us)  ", total_time, start_time / 1000.00, end_time / 1000.00) };
  content = { content, $sformatf("\n  Latency = %6d cycles\n", total_latency) };
  content = { content, $sformatf("\n  F = 100 MHz -> Time = %7.2f us -> Latency = %0.2f us", total_time * 10.0 / 1000.00, total_latency * 10.0 / 1000.00) };
  content = { content, $sformatf("\n  F = 150 MHz -> Time = %7.2f us -> Latency = %0.2f us", total_time * 6.67 / 1000.00, total_latency * 6.67 / 1000.00) };
  content = { content, $sformatf("\n  F = 200 MHz -> Time = %7.2f us -> Latency = %0.2f us", total_time * 5.00 / 1000.00, total_latency * 5.00 / 1000.00) };
  content = { content, $sformatf("\n  F = 225 MHz -> Time = %7.2f us -> Latency = %0.2f us", total_time * 4.44 / 1000.00, total_latency * 4.44 / 1000.00) };
  content = { content, $sformatf("\n  F = 300 MHz -> Time = %7.2f us -> Latency = %0.2f us", total_time * 3.33 / 1000.00, total_latency * 3.33 / 1000.00) };
  content = { content, $sformatf("\n------------------------------------------------------------") };

  summary_log = { summary_log, content };
  $display(content);
endtask

task end_section;
  content = "";
  content = { content, $sformatf("\n------------------------------------------------------------") };
  content = { content, $sformatf("\n|                          %s                             |", end_str) };
  content = { content, $sformatf("\n------------------------------------------------------------") };
  content = { content, $sformatf("\n") };
  $display(content);

  summary_log = { summary_log, content };

  file = $fopen($sformatf("%s/summary.log", LOG_PATH), "w");
  if (file == 0) $error("Summary: Failed to open summary file ");
  $fwrite(file, "%s\n", summary_log);
  $fclose(file);
endtask

