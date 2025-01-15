module a_loader import gat_pkg::*;
(
  input                                   clk           ,
  input                                   rst_n         ,

  input                                   a_vld_i       ,
  output                                  a_rdy_o       ,

  input   [DATA_WIDTH-1:0]                a_bram_dout   ,
  output                                  a_bram_enb    ,
  output  [A_ADDR_W-1:0]                  a_bram_addrb  ,

  output  [A_DEPTH*DATA_WIDTH-1:0]        a_flat_o
);
  //* ========== logic declaration ==========
  logic [A_ADDR_W-1:0]                    a_addr      ;
  logic [A_ADDR_W-1:0]                    a_addr_reg  ;

  logic [A_DEPTH-1:0] [DATA_WIDTH-1:0]    a           ;
  logic [A_DEPTH-1:0] [DATA_WIDTH-1:0]    a_reg       ;

  logic                                   rd_en       ;
  logic                                   rd_en_q1    ;
  logic                                   rd_en_q2    ;

  logic [A_INDEX_WIDTH-1:0]               idx         ;
  logic [A_INDEX_WIDTH-1:0]               idx_reg     ;

  logic [A_DEPTH-1:0] [DATA_WIDTH-1:0]    a_o         ;
  //* =======================================

  genvar i;

  //* ========= internal assignment =========
  assign rd_en = (a_vld_i && (a_addr_reg < A_DEPTH + 1));
  //* =======================================


  //* ========== output assignment ==========
  assign a_bram_addrb = a_addr_reg;
  assign a_bram_enb   = rd_en ? 1'b1 : 1'b0;
  assign a_rdy_o      = (a_addr_reg == A_DEPTH + 1) ? 1'b1 : 1'b0;
  generate
    for (i = 0; i < A_DEPTH; i = i + 1) begin
      assign a_o[i] = a_reg[i];
    end
  endgenerate

  assign a_flat_o = a_o;
  //* =======================================


  //* ================ addr =================
  assign a_addr = (a_vld_i && a_addr_reg < A_DEPTH - 1) ? (a_addr_reg + 1) : a_addr_reg;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      a_addr_reg <= 'b0;
    end else begin
      a_addr_reg <= a_addr;
    end
  end
  //* =======================================


  always @(posedge clk) begin
    rd_en_q1 <= rd_en;
    rd_en_q2 <= rd_en_q1;
  end


  //* ================= a ===================
  assign idx = (rd_en_q1 && (idx_reg < A_DEPTH - 1)) ? (idx_reg + 1) : idx_reg;

  generate
    for (i = 0; i < A_DEPTH; i = i + 1) begin
      assign a[i] = (i == idx_reg) ? a_bram_dout : a_reg[i];
    end
  endgenerate

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      idx_reg <= 'b0;
      a_reg   <= 'b0;
    end else begin
      idx_reg <= idx;
      a_reg   <= a;
    end
  end
  //* =======================================
endmodule