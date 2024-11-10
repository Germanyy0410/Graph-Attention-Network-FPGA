module softmax_tb #(
  parameter DATA_WIDTH = 8,
  parameter MAX_NODES      = 168,
  parameter NODE_WIDTH    =  $clog2(MAX_NODES)
)();

  logic clk;
  logic rst_n;
	logic [NODE_WIDTH-1:0]  num_of_nodes;
  logic                     sm_valid_i;
  logic                    sm_ready_o;

  logic   [DATA_WIDTH-1:0]  coef_i      [0:MAX_NODES-1];
  logic  [12-1:0]  alpha_o  [0:MAX_NODES-1];  
  
	//hehe	
	
  softmax dut(.*);

  always #10 clk = ~clk;

	initial begin
    clk   = 1'b1;
		num_of_nodes = 'd5;
    rst_n = 1'b0;
    #11.01;
    rst_n = 1'b1;
		
    #5000;
    $finish();
  end
	
	initial begin
		sm_valid_i = 1'b0;
		#20;
		for(int i = 0; i < MAX_NODES; i++) begin
			coef_i[i] = 8'd0;
		end
		for(int i = 0; i < num_of_nodes; i++) begin
			coef_i[i] = i + 1;
		end
		sm_valid_i = 1'b1;
    #20.01;
    sm_valid_i = 1'b0;
	end
endmodule
