`include "./../others/pkgs/params_pkg.sv"

module a_loader import params_pkg::*;
(
  input                                   clk           ,
  input                                   rst_n         ,

  input                                   a_valid_i     ,
  output                                  a_ready_o     ,

  input   [DATA_WIDTH-1:0]                a_BRAM_dout   ,
  output                                  a_BRAM_enb    ,
  output  [A_ADDR_W-1:0]                  a_BRAM_addrb  ,

  output  [A_DEPTH-1:0] [DATA_WIDTH-1:0]  a_o
);
  //* ========== wire declaration ===========
  wire  [A_ADDR_W-1:0]                  a_addr      ;
  wire  [A_DEPTH-1:0] [DATA_WIDTH-1:0]  a           ;
  wire                                  rd_en       ;
  wire  [A_INDEX_WIDTH-1:0]             idx         ;
  //* =======================================


  //* =========== reg declaration ===========
  reg   [A_ADDR_W-1:0]                  a_addr_reg  ;
  reg   [A_DEPTH-1:0] [DATA_WIDTH-1:0]  a_reg       ;
  reg                                   rd_en_q1    ;
  reg                                   rd_en_q2    ;
  reg   [A_INDEX_WIDTH-1:0]             idx_reg     ;
  //* =======================================

  genvar i;

  //* ========= internal assignment =========
  assign rd_en = (a_valid_i && (a_addr_reg < A_DEPTH + 1));
  //* =======================================


  //* ========== output assignment ==========
  assign a_BRAM_addrb = a_addr_reg;
  assign a_BRAM_enb   = rd_en ? 1'b1 : 1'b0;
  assign a_ready_o    = (a_addr_reg == A_DEPTH + 1) ? 1'b1 : 1'b0;
  generate
    for (i = 0; i < A_DEPTH; i = i + 1) begin
      assign a_o[i] = a_reg[i];
    end
  endgenerate
  //* =======================================


  //* ================ addr =================
  assign a_addr = (a_valid_i && a_addr_reg < A_DEPTH - 1) ? (a_addr_reg + 1) : a_addr_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      a_addr_reg <= 0;
    end else begin
      a_addr_reg <= a_addr;
    end
  end
  //* =======================================


  always_ff @(posedge clk) begin
    rd_en_q1 <= rd_en;
    rd_en_q2 <= rd_en_q1;
  end


  //* ================= a ===================
  assign idx = (rd_en_q1 && (idx_reg < A_DEPTH - 1)) ? (idx_reg + 1) : idx_reg;

  generate
    for (i = 0; i < A_DEPTH; i = i + 1) begin
      assign a[i] = (i == idx_reg) ? a_BRAM_dout : a_reg[i];
    end
  endgenerate

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      idx_reg <= 0;
      a_reg   <= '0;
    end else begin
      idx_reg <= idx;
      a_reg   <= a;
    end
  end
  //* =======================================
endmodule