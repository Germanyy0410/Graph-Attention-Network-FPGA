`include "./../others/pkgs/params_pkg.sv"

module aggregator import params_pkg::*;
(
  input                                               clk               ,
  input                                               rst_n             ,

  input                                               aggr_valid_i      ,
  output                                              aggr_ready_o      ,

  // -- WH
  input   [WH_WIDTH-1:0]                              WH_BRAM_dout      ,
  output  [WH_2_ADDR_W-1:0]                           WH_BRAM_addrb     ,

  // -- alpha
  input   [ALPHA_DATA_WIDTH-1:0]                      alpha_FIFO_dout   ,
  input                                               alpha_FIFO_empty  ,
  output                                              alpha_FIFO_rd_vld
);
  //* ========== wire declaration ===========

  //* =======================================


  //* =========== reg declaration ===========

  //* =======================================

  genvar i;

  //* ========== output assignment ==========

  //* =======================================
endmodule