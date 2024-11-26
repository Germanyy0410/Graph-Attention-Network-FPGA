module scheduler #(
  //* ========== parameter ===========
  parameter DATA_WIDTH          = 8,
  // -- W
  parameter W_NUM_OF_ROWS       = 1433,
  parameter W_NUM_OF_COLS       = 16,
  // -- BRAM
  parameter WEIGHT_DEPTH        = 22928,
  parameter A_DEPTH             = 2 * 16,

  //* ========= localparams ==========
  parameter WEIGHT_ADDR_W       = $clog2(WEIGHT_DEPTH),
  parameter MULT_WEIGHT_ADDR_W  = $clog2(W_NUM_OF_ROWS),
  parameter A_ADDR_W            = $clog2(A_DEPTH)
)(
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
  W_loader #(
    .DATA_WIDTH       (DATA_WIDTH       ),
    .W_NUM_OF_COLS    (W_NUM_OF_COLS    ),
    .W_NUM_OF_ROWS    (W_NUM_OF_ROWS    )
  ) u_W_loader (
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
  a_loader #(
    .DATA_WIDTH       (DATA_WIDTH       ),
    .A_ADDR_W         (A_ADDR_W         ),
    .A_DEPTH          (A_DEPTH          )
  ) u_a_loader (
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


