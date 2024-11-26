module aggregator #(
  //* ========== parameter ===========
  parameter DATA_WIDTH        = 8,
  parameter WH_DATA_WIDTH     = 12,
  parameter ALPHA_DATA_WIDTH  = 32,

  parameter W_NUM_OF_COLS     = 16,
  parameter WH_DEPTH          = 13264,
  parameter NUM_OF_NODES      = 168,

  //* ========= localparams ==========
  parameter NUM_NODE_WIDTH    = $clog2(NUM_OF_NODES),
  parameter WH_WIDTH          = WH_DATA_WIDTH * W_NUM_OF_COLS + NUM_NODE_WIDTH + 1,
  parameter WH_ADDR_W         = $clog2(WH_DEPTH)
)(
  input                             clk                                       ,
  input                             rst_n                                     ,

  input                             aggr_valid_i                              ,
  output                            aggr_ready_o                              ,
  output                            aggr_pre_ready_o                          ,

  // -- WH
  input   [WH_WIDTH-1:0]            WH_BRAM_doutc                             ,
  output  [WH_ADDR_W-1:0]           WH_BRAM_addrc                             ,

  // -- alpha
  input   [ALPHA_DATA_WIDTH-1:0]    alpha_i         [0:NUM_OF_NODES-1]        ,
  input   [NUM_NODE_WIDTH-1:0]      num_of_nodes
);
  //* ========== wire declaration ===========

  //* =======================================


  //* =========== reg declaration ===========
  reg   [DATA_WIDTH-1:0]   H_next       [0:NUM_OF_NODES-1]        ;
  //* =======================================

  genvar i;

  //* ========== output assignment ==========

  //* =======================================
endmodule