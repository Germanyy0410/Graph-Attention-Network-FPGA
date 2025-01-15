module SP_PE import gat_pkg::*;
(
  input                             clk                     ,
  input                             rst_n                   ,

  input                             pe_vld_i                ,
  output                            pe_rdy_o                ,

  input   [COL_IDX_WIDTH-1:0]       col_idx_i               ,
  input   [DATA_WIDTH-1:0]          val_i                   ,
  input   [ROW_LEN_WIDTH-1:0]       row_len_i               ,

  input   [DATA_WIDTH-1:0]          wgt_dout                ,
  output  [MULT_WEIGHT_ADDR_W-1:0]  wgt_addrb               ,

  output  [WH_DATA_WIDTH-1:0]       res_o
);
  //* ============= reg declaration =============
  // -- [pe_rdy] logic
  logic                               pe_rdy              ;
  logic                               pe_rdy_reg          ;
  // -- [res] logic
  logic signed  [WH_DATA_WIDTH-1:0]   res                 ;
  logic signed  [WH_DATA_WIDTH-1:0]   res_reg             ;

  logic signed  [WH_DATA_WIDTH-1:0]   prod                ;
  logic signed  [WH_DATA_WIDTH-1:0]   prod_reg            ;

  logic         [ROW_LEN_WIDTH:0]     cnt                 ;
  logic         [ROW_LEN_WIDTH:0]     cnt_reg             ;

  logic                               calc_ena  ;
  //* ===========================================

  integer i;

  //* ============ output assignment ============
  assign res_o    = res_reg;
  assign pe_rdy_o = pe_rdy_reg;
  //* ===========================================


  //* =============== calculation ===============
  assign wgt_addrb  = col_idx_i;
  assign calc_ena   = ((cnt_reg == 0 && (pe_vld_i || row_len_i == 1)) || (cnt_reg > 0 && cnt_reg < row_len_i && row_len_i > 1));

  always_comb begin
    prod  = prod_reg;
    res   = res_reg;
    cnt   = cnt_reg;

    if (calc_ena) begin
      prod  = $signed(val_i) * $signed(wgt_dout);
      res   = (cnt_reg != 0) ? ($signed(res_reg) + $signed(prod)) : prod;
      cnt   = (cnt_reg == row_len_i - 1) ? 0 : (cnt_reg + 1);
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prod_reg  <= 'b0;
      cnt_reg   <= 'b0;
      res_reg   <= 'b0;
    end else begin
      cnt_reg   <= cnt;
      prod_reg  <= prod;
      res_reg   <= res;
    end
  end
  //* ===========================================


  //* ================ pe_rdy =================
  always_comb begin
    pe_rdy = pe_rdy_reg;
    if (pe_rdy_reg && (row_len_i > 1)) begin
      pe_rdy = 1'b0;
    end else if ((cnt_reg == row_len_i - 1) || (row_len_i == 1)) begin
      pe_rdy = 1'b1;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pe_rdy_reg <= 'b0;
    end else begin
      if (row_len_i == 1 && pe_vld_i) begin
        pe_rdy_reg <= 1'b1;
      end else begin
        pe_rdy_reg <= pe_rdy;
      end
    end
  end
  //* ===========================================
endmodule