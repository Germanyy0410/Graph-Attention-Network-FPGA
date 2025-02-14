// ==================================================================
// File name  : SPMM.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   :
// -- Calculate the multiplication of Feature & Weight: Wh = H x W
// -- Pipeline stage = 1
// -- Initialize multiple Processing Element for parallel computation
// -- Store the result in BRAM
// Author     : @Germanyy0410
// ==================================================================

module WH import gat_pkg::*;
(
  input                                                               clk                       ,
  input                                                               rst_n                     ,

  input                                                               spmm_vld_i                ,
  output                                                              spmm_rdy_o                ,

  // -- Feature
  input   [H_DATA_WIDTH-1:0]                                          h_data_bram_dout          ,
  output  [H_DATA_ADDR_W-1:0]                                         h_data_bram_addrb         ,

  // -- Weight
  input   [W_NUM_OF_COLS-1:0] [W_NUM_OF_ROWS-1:0] [DATA_WIDTH-1:0]    wgt                       ,

  // -- DMVM
  output  [WH_WIDTH-1:0]                                              wh_data_o                 ,

  output  wh_t                                                        wh_bram_din               ,
  output                                                              wh_bram_ena               ,
  output  [WH_ADDR_W-1:0]                                             wh_bram_addra
);

  

endmodule