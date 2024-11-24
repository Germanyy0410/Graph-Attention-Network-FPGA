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
    forever begin
      wait(ready_signal);
      for (int i = 0; i < N; i++) begin
        #0.01;
        if ($signed(golden_output[i]) === $signed(dut_output[i])) begin
          pass_checker++;
        end
        total_checker++;
      end
      $display("Total Checks: %0d, Passed: %0d", total_checker, pass_checker);
    end
  endtask

  function void update_inputs(bit ready, int golden[], int dut[]);
    ready_signal = ready;
    golden_output = golden;
    dut_output = dut;
  endfunction
endclass
