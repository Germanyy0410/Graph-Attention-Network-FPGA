module softmax #(
  parameter DATA_WIDTH        = 8,
  parameter NUM_OF_NODES      = 5
)(
  input clk,
  input rst_n,

  input                     sm_valid_i                      ,
  output                    sm_ready_o                      ,

  input   [DATA_WIDTH-1:0]  coef_i      [0:NUM_OF_NODES-1]  ,
  output  [DATA_WIDTH-1:0]  alpha_o     [0:NUM_OF_NODES-1]
);
endmodule