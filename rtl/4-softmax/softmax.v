module softmax #(
  parameter DATA_WIDTH        = 8,
  parameter NUM_OF_NODES      = 5,

  localparam DATA_WIDTH_FLAT  = NUM_OF_NODES * DATA_WIDTH
)(
  input clk,
  input rst_n,

  input                         sm_valid_i  ,
  output                        sm_ready_o  ,

  input   [DATA_WIDTH_FLAT-1:0] coef_i      ,
  output  [DATA_WIDTH_FLAT-1:0] alpha_o
);
  //* ========== wire declaration ===========
  wire  [DATA_WIDTH-1:0]        coef  [0:NUM_OF_NODES-1];

  //* =========== reg declaration ===========
  reg   [DATA_WIDTH-1:0]        alpha [0:NUM_OF_NODES-1];

  //* ========= internal declaration ========
  genvar i, j;

  //* ========== input assignment ===========
  // -- deflatten input
  generate
    for (i = 0; i < NUM_OF_NODES; i = i + 1) begin
      assign coef[NUM_OF_NODES-1-i] = coef_i[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i];
    end
  endgenerate

  //* ========== output assignment ==========
  // -- flatten output
  generate
    for (i = 0; i < NUM_OF_NODES; i = i + 1) begin
      for (j = 0; j < DATA_WIDTH; j = j + 1) begin
        assign alpha_o[i*DATA_WIDTH+j] = alpha[i][j];
      end
    end
  endgenerate
endmodule