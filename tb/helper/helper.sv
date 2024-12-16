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

`ifdef VIVADO
  string begin_str    = "BEGIN";
  string summary_str  = "REPORT SUMMARY";
  string end_str      = "END";
`else
  string begin_str    = "\033[38;5;220mBEGIN\033[0m";
  string summary_str  = "\033[38;5;220mREPORT SUMMARY\033[0m";
  string end_str      = "\033[38;5;220mEND\033[0m";
`endif

task begin_section;
  $display("----------------------------------------------------------");
  $display("|                         %s                          |", begin_str);
  $display("----------------------------------------------------------");
endtask

task summary_section;
  $display("----------------------------------------------------------");
  $display("|                    %s                      |", summary_str);
  $display("----------------------------------------------------------");
  $display("TOTAL NODES   = %0d\t\t  NUM_FEATURE_IN  = %0d", TOTAL_NODES, NUM_FEATURE_IN);
  $display("NUM_SUBGRAPHS = %0d\t\t  NUM_FEATURE_OUT = %0d", NUM_SUBGRAPHS, NUM_FEATURE_OUT);
  $display("----------------------------------------------------------");
  $display("Total Clock = %0d cycle\n", (end_time - start_time) / 10);
  $display("\t\tF = 100 MHz -> %0.5f us", ((end_time - start_time) / 10) * 10 / 1000);
  $display("\t\tF = 150 MHz -> %0.5f us", ((end_time - start_time) / 10) * 6.67 / 1000);
  $display("\t\tF = 200 MHz -> %0.5f us", ((end_time - start_time) / 10) * 5 / 1000);
  $display("----------------------------------------------------------");
endtask

task end_section;
  $display("\n");
  $display("----------------------------------------------------------");
  $display("|                          %s                           |", end_str);
  $display("----------------------------------------------------------");
  $display("\n");
endtask
