`include "./../others/params_pkg.sv"

module scheduler import params_pkg::*;
(
  input                             clk                                       ,
  input                             rst_n                                     ,

  // -- Weight BRAM
  input   [DATA_WIDTH-1:0]          Weight_BRAM_dout                          ,
  output  [WEIGHT_ADDR_W-1:0]       Weight_BRAM_addrb                         ,
  input                             Weight_BRAM_load_done                     ,
  input   [MULT_WEIGHT_ADDR_W-1:0]  mult_weight_addrb   [0:W_NUM_OF_COLS-1]   ,
  output  [DATA_WIDTH-1:0]          mult_weight_dout    [0:W_NUM_OF_COLS-1]   ,
  output                            w_ready_o                                 ,

  // -- a BRAM
  input   [DATA_WIDTH-1:0]          a_BRAM_dout                               ,
  output  [A_ADDR_W-1:0]            a_BRAM_addrb                              ,
  input                             a_BRAM_load_done                          ,
  output  [DATA_WIDTH-1:0]          a                   [0:A_DEPTH-1]         ,
  output                            a_ready_o
);


  //* ======================== W_loader ========================
  W_loader u_W_loader (
    .clk                      (clk                    ),
    .rst_n                    (rst_n                  ),

    .w_valid_i                (Weight_BRAM_load_done  ),
    .w_ready_o                (w_ready_o              ),

    .Weight_BRAM_dout         (Weight_BRAM_dout       ),
    .Weight_BRAM_enb          (Weight_BRAM_enb        ),
    .Weight_BRAM_addrb        (Weight_BRAM_addrb      ),

    .mult_weight_addrb        (mult_weight_addrb      ),
    .mult_weight_dout         (mult_weight_dout       )
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

    .a_o              (a                      )
  );
  //* ==========================================================
endmodule


