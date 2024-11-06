module aggregator #(
  //* ========== parameter ===========
  parameter DOT_PRODUCT_SIZE  = 1433                      ,
  parameter DATA_WIDTH        = 8                         ,
  parameter BRAM_ADDR_WIDTH   = 32                        ,
  parameter NUM_OF_NODES      = 168                       ,

  //* ========= localparams ==========
  parameter INDEX_WIDTH       = $clog2(DOT_PRODUCT_SIZE)  ,
  parameter MAX_VALUE         = {DATA_WIDTH{1'b1}}        ,
  parameter NUM_NODE_WIDTH    = $clog2(NUM_OF_NODES)
)(
  input clk,
  input rst_n,

  // -- WH BRAM
  input   [DATA_WIDTH-1:0]          WH_BRAM_doutc                             ,
  output  [BRAM_ADDR_WIDTH-1:0]     WH_BRAM_addrc                             ,
  input   [NUM_NODE_WIDTH-1:0]      num_of_nodes                              ,
  // -- alpha
  input   [DATA_WIDTH-1:0]          alpha_i         [0:NUM_OF_NODES-1]        ,
  // -- H BRAM
  input   [DATA_WIDTH-1:0]          H_BRAM_din                                ,
  output                            H_BRAM_ena                                ,
  output                            H_BRAM_wea                                ,
  output  [BRAM_ADDR_WIDTH-1:0]     H_BRAM_addra
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