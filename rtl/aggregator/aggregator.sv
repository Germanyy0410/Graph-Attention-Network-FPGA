`include "./../others/pkgs/params_pkg.sv"

module aggregator import params_pkg::*;
(
  input                                               clk               ,
  input                                               rst_n             ,

  input                                               aggr_valid_i      ,
  output                                              aggr_ready_o      ,
  output                                              aggr_pre_ready_o  ,

  // -- WH
  input   [WH_WIDTH-1:0]                              WH_BRAM_doutb     ,
  output  [WH_2_ADDR_W-1:0]                           WH_BRAM_addrb     ,

  // -- alpha
  input   [MAX_NODES-1:0] [ALPHA_DATA_WIDTH-1:0]      alpha_i           ,
  input   [NUM_NODE_WIDTH-1:0]                        num_of_nodes
);
  //* ========== wire declaration ===========

  //* =======================================


  //* =========== reg declaration ===========

  //* =======================================

  genvar i;

  //* ========== output assignment ==========

  //* =======================================
endmodule