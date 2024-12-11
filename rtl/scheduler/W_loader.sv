`include "./../others/pkgs/params_pkg.sv"

module W_loader import params_pkg::*;
(
  input                                                 clk                     ,
  input                                                 rst_n                   ,

  input                                                 w_valid_i               ,
  output                                                w_ready_o               ,

  input   [DATA_WIDTH-1:0]                              Weight_BRAM_dout        ,
  output  [WEIGHT_ADDR_W-1:0]                           Weight_BRAM_addrb       ,

  output  [W_NUM_OF_COLS*DATA_WIDTH-1:0]                mult_weight_dout_flat   ,
  input   [W_NUM_OF_COLS*MULT_WEIGHT_ADDR_W-1:0]        mult_weight_addrb_flat
);

  logic [WEIGHT_ADDR_W:0]                             addr                ;
  logic                                               w_ready             ;

  logic [W_NUM_OF_COLS-1:0] [DATA_WIDTH-1:0]          mult_weight_din     ;
  logic [W_NUM_OF_COLS-1:0] [MULT_WEIGHT_ADDR_W-1:0]  mult_weight_addra   ;
  logic [W_NUM_OF_COLS-1:0]                           mult_weight_ena     ;

  logic                                               w_ready_reg         ;
  logic [WEIGHT_ADDR_W-1:0]                           addr_reg            ;
  logic [W_ROW_WIDTH-1:0]                             row_idx             ;
  logic [W_ROW_WIDTH-1:0]                             row_idx_reg         ;
  logic [W_COL_WIDTH-1:0]                             col_idx             ;
  logic [W_COL_WIDTH-1:0]                             col_idx_reg         ;
  logic                                               w_valid_q1          ;
  logic                                               w_valid_q2          ;

  logic [W_NUM_OF_COLS-1:0] [DATA_WIDTH-1:0]          mult_weight_dout    ;
  logic [W_NUM_OF_COLS-1:0] [MULT_WEIGHT_ADDR_W-1:0]  mult_weight_addrb   ;

  assign mult_weight_dout_flat  = mult_weight_dout;
  assign mult_weight_addrb      = mult_weight_addrb_flat;
  //* =======================================


  //* ======== internal declaration =========
  genvar i, k;
  //* =======================================


  //* ============ BRAM instance ============
  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      BRAM #(
        .DATA_WIDTH   (DATA_WIDTH     ),
        .DEPTH        (W_NUM_OF_ROWS  ),
        .CLK_LATENCY  (0              )
      ) u_mult_weight_BRAM (
        .clk          (clk                  ),
        .rst_n        (rst_n                ),
        .din          (mult_weight_din[i]   ),
        .addra        (mult_weight_addra[i] ),
        .ena          (mult_weight_ena[i]   ),
        .addrb        (mult_weight_addrb[i] ),
        .dout         (mult_weight_dout[i]  )
      );
    end
  endgenerate
  //* =======================================


  //* ========== output assignment ==========
  assign Weight_BRAM_addrb = addr_reg;
  assign w_ready_o         = w_ready_reg;
  //* =======================================


  //* ====== 2 cycles delay from BRAM =======
  always @(posedge clk) begin
    w_valid_q1 <= w_valid_i;
    w_valid_q2 <= w_valid_q1;
  end
  //* =======================================


  //* ====== Generate mul-weight BRAM =======
  always @(*) begin
    addr    = addr_reg;
    col_idx = col_idx_reg;
    row_idx = row_idx_reg;

    if (w_valid_i && addr_reg < W_NUM_OF_COLS * W_NUM_OF_ROWS) begin
      addr = addr_reg + 1;
    end

    if (w_valid_q1) begin
      if ((col_idx_reg == W_NUM_OF_COLS - 1)) begin
        col_idx = 0;
      end else begin
        col_idx = col_idx_reg + 1;
      end
    end

    if (w_valid_q1 && col_idx_reg == W_NUM_OF_COLS - 1) begin
      if (row_idx_reg == W_NUM_OF_ROWS - 1) begin
        row_idx = 0;
      end else begin
        row_idx = row_idx_reg + 1;
      end
    end
  end

  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      assign mult_weight_addra[i] = row_idx_reg;
      assign mult_weight_din[i]   = Weight_BRAM_dout;
      assign mult_weight_ena[i]   = (i == col_idx_reg && ~w_ready_reg) ? 1'b1 : 1'b0;
    end
  endgenerate

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      addr_reg    <= 0;
      row_idx_reg <= 0;
      col_idx_reg <= 0;
    end else begin
      addr_reg    <= addr;
      row_idx_reg <= row_idx;
      col_idx_reg <= col_idx;
    end
  end
  //* =======================================


  //* ============= [w_ready] ===============
  assign w_ready = (row_idx_reg == W_NUM_OF_ROWS - 1) && (col_idx_reg == W_NUM_OF_COLS - 1) ? 1'b1 : w_ready_reg;

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      w_ready_reg <= 1'b0;
    end else begin
      w_ready_reg <= w_ready;
    end
  end
  //* =======================================
endmodule