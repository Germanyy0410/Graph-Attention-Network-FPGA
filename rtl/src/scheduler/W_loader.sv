//==================================================================
// File name  : W_loader.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   : Split each column of Weight into one BRAM
// Author     : @Germanyy0410
//==================================================================

module W_loader import gat_pkg::*;
(
  input                                                 clk                     ,
  input                                                 rst_n                   ,

  input                                                 w_vld_i                 ,
  output                                                w_rdy_o                 ,

  input   [DATA_WIDTH-1:0]                              wgt_bram_dout           ,
  output  [WEIGHT_ADDR_W-1:0]                           wgt_bram_addrb          ,

  output  [W_NUM_OF_COLS*DATA_WIDTH-1:0]                mult_wgt_dout_flat      ,
  input   [W_NUM_OF_COLS*MULT_WEIGHT_ADDR_W-1:0]        mult_wgt_addrb_flat
);

  logic                                               w_rdy               ;
  logic                                               w_rdy_reg           ;

  logic [WEIGHT_ADDR_W:0]                             addr                ;

  logic [W_NUM_OF_COLS-1:0] [DATA_WIDTH-1:0]          mult_wgt_din        ;
  logic [W_NUM_OF_COLS-1:0] [MULT_WEIGHT_ADDR_W-1:0]  mult_wgt_addra      ;
  logic [W_NUM_OF_COLS-1:0]                           mult_wgt_ena        ;

  logic [WEIGHT_ADDR_W-1:0]                           addr_reg            ;
  logic [W_ROW_WIDTH-1:0]                             row_idx             ;
  logic [W_ROW_WIDTH-1:0]                             row_idx_reg         ;
  logic [W_COL_WIDTH-1:0]                             col_idx             ;
  logic [W_COL_WIDTH-1:0]                             col_idx_reg         ;
  logic                                               w_vld_q1            ;
  logic                                               w_vld_q2            ;

  logic [W_NUM_OF_COLS-1:0] [DATA_WIDTH-1:0]          mult_wgt_dout       ;
  logic [W_NUM_OF_COLS-1:0] [MULT_WEIGHT_ADDR_W-1:0]  mult_wgt_addrb      ;

  assign mult_wgt_dout_flat  = mult_wgt_dout;
  assign mult_wgt_addrb      = mult_wgt_addrb_flat;
  //* =======================================


  //* ======== internal declaration =========
  genvar i, k;
  //* =======================================


  //* ============ bram instance ============
  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      BRAM #(
        .DATA_WIDTH   (DATA_WIDTH     ),
        .DEPTH        (W_NUM_OF_ROWS  ),
        .CLK_LATENCY  (0              )
      ) u_mult_wgt_bram (
        .clk          (clk               ),
        .rst_n        (rst_n             ),
        .din          (mult_wgt_din[i]   ),
        .addra        (mult_wgt_addra[i] ),
        .ena          (mult_wgt_ena[i]   ),
        .addrb        (mult_wgt_addrb[i] ),
        .dout         (mult_wgt_dout[i]  )
      );
    end
  endgenerate
  //* =======================================


  //* ========== output assignment ==========
  assign wgt_bram_addrb = addr_reg;
  assign w_rdy_o        = w_rdy_reg;
  //* =======================================


  //* ====== 2 cycles delay from bram =======
  always @(posedge clk) begin
    w_vld_q1 <= w_vld_i;
    w_vld_q2 <= w_vld_q1;
  end
  //* =======================================


  //* ====== Generate mul-weight bram =======
  always @(*) begin
    addr    = addr_reg;
    col_idx = col_idx_reg;
    row_idx = row_idx_reg;

    if (w_vld_i && addr_reg < W_NUM_OF_COLS * W_NUM_OF_ROWS) begin
      addr = addr_reg + 1;
    end

    if (w_vld_q1) begin
      if ((col_idx_reg == W_NUM_OF_COLS - 1)) begin
        col_idx = 0;
      end else begin
        col_idx = col_idx_reg + 1;
      end
    end

    if (w_vld_q1 && col_idx_reg == W_NUM_OF_COLS - 1) begin
      if (row_idx_reg == W_NUM_OF_ROWS - 1) begin
        row_idx = 0;
      end else begin
        row_idx = row_idx_reg + 1;
      end
    end
  end

  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      assign mult_wgt_addra[i] = row_idx_reg;
      assign mult_wgt_din[i]   = wgt_bram_dout;
      assign mult_wgt_ena[i]   = (i == col_idx_reg && ~w_rdy_reg) ? 1'b1 : 1'b0;
    end
  endgenerate

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      addr_reg    <= 'b0;
      row_idx_reg <= 'b0;
      col_idx_reg <= 'b0;
    end else begin
      addr_reg    <= addr;
      row_idx_reg <= row_idx;
      col_idx_reg <= col_idx;
    end
  end
  //* =======================================


  //* ============= [w_rdy] ===============
  assign w_rdy = (row_idx_reg == W_NUM_OF_ROWS - 1) && (col_idx_reg == W_NUM_OF_COLS - 1) ? 1'b1 : w_rdy_reg;

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      w_rdy_reg <= 'b0;
    end else begin
      w_rdy_reg <= w_rdy;
    end
  end
  //* =======================================
endmodule