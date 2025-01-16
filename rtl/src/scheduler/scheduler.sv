// ==================================================================
// File name  : scheduler.sv
// Project    : Graph Attention Network Accelerator on FPGA
// Function   :
// -- Split each column of Weight into one BRAM
// -- Fetch Attention Weight from BRAM to a register
// Author     : @Germanyy0410
// ==================================================================

module scheduler import gat_pkg::*;
(
  input                                                 clk                   ,
  input                                                 rst_n                 ,

  // -- wgt BRAM
  input   [DATA_WIDTH-1:0]                              wgt_bram_dout         ,
  output  [WEIGHT_ADDR_W-1:0]                           wgt_bram_addrb        ,
  input                                                 wgt_bram_load_done    ,
  input   [W_NUM_OF_COLS*MULT_WEIGHT_ADDR_W-1:0]        mult_wgt_addrb        ,
  output  [W_NUM_OF_COLS*DATA_WIDTH-1:0]                mult_wgt_dout         ,
  output                                                w_rdy_o               ,

  // -- a BRAM
  input   [DATA_WIDTH-1:0]                              a_bram_dout           ,
  output  [A_ADDR_W-1:0]                                a_bram_addrb          ,
  input                                                 a_bram_load_done      ,
  output  [A_DEPTH*DATA_WIDTH-1:0]                      a                     ,
  output                                                a_rdy_o
);


  //* ======================== W_loader ========================
  W_loader u_W_loader (
    .clk                      (clk                    ),
    .rst_n                    (rst_n                  ),

    .w_vld_i                  (wgt_bram_load_done     ),
    .w_rdy_o                  (w_rdy_o                ),

    .wgt_bram_dout            (wgt_bram_dout          ),
    .wgt_bram_addrb           (wgt_bram_addrb         ),

    .mult_wgt_addrb_flat      (mult_wgt_addrb         ),
    .mult_wgt_dout_flat       (mult_wgt_dout          )
  );
  //* ==========================================================


  //* ======================== a_loader ========================
  a_loader u_a_loader (
    .clk              (clk                    ),
    .rst_n            (rst_n                  ),

    .a_vld_i          (a_bram_load_done       ),
    .a_rdy_o          (a_rdy_o                ),

    .a_bram_dout      (a_bram_dout            ),
    .a_bram_enb       (a_bram_enb             ),
    .a_bram_addrb     (a_bram_addrb           ),

    .a_flat_o         (a                      )
  );
  //* ==========================================================
endmodule


