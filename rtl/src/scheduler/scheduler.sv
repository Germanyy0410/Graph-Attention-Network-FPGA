`include "./../../inc/gat_pkg.sv"

module scheduler import gat_pkg::*;
(
  input                                                 clk                   ,
  input                                                 rst_n                 ,

  // -- weight BRAM
  input   [DATA_WIDTH-1:0]                              weight_BRAM_dout      ,
  output  [WEIGHT_ADDR_W-1:0]                           weight_BRAM_addrb     ,
  input                                                 weight_BRAM_load_done ,
  input   [W_NUM_OF_COLS*MULT_WEIGHT_ADDR_W-1:0]        mult_weight_addrb     ,
  output  [W_NUM_OF_COLS*DATA_WIDTH-1:0]                mult_weight_dout      ,
  output                                                w_ready_o             ,

  // -- a BRAM
  input   [DATA_WIDTH-1:0]                              a_BRAM_dout           ,
  output  [A_ADDR_W-1:0]                                a_BRAM_addrb          ,
  input                                                 a_BRAM_load_done      ,
  output  [A_DEPTH*DATA_WIDTH-1:0]                      a                     ,
  output                                                a_ready_o
);


  //* ======================== W_loader ========================
  W_loader u_W_loader (
    .clk                      (clk                    ),
    .rst_n                    (rst_n                  ),

    .w_valid_i                (weight_BRAM_load_done  ),
    .w_ready_o                (w_ready_o              ),

    .weight_BRAM_dout         (weight_BRAM_dout       ),
    .weight_BRAM_addrb        (weight_BRAM_addrb      ),

    .mult_weight_addrb_flat   (mult_weight_addrb      ),
    .mult_weight_dout_flat    (mult_weight_dout       )
  );
  //* ==========================================================


  //* ======================== a_loader ========================
  a_loader u_a_loader (
    .clk              (clk                    ),
    .rst_n            (rst_n                  ),

    .a_valid_i        (a_BRAM_load_done       ),
    .a_ready_o        (a_ready_o              ),

    .a_BRAM_dout      (a_BRAM_dout            ),
    .a_BRAM_enb       (a_BRAM_enb             ),
    .a_BRAM_addrb     (a_BRAM_addrb           ),

    .a_flat_o         (a                      )
  );
  //* ==========================================================
endmodule


