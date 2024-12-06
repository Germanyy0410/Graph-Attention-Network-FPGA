`include "./../others/params_pkg.sv"

module SP_PE import params_pkg::*;
(
  input                             clk                     ,
  input                             rst_n                   ,

  input                             pe_valid_i              ,
  output                            pe_ready_o              ,

  input   [COL_IDX_WIDTH-1:0]       col_idx_i               ,
  input   [DATA_WIDTH-1:0]          value_i                 ,
  input   [ROW_LEN_WIDTH-1:0]       row_length_i            ,

  input   [DATA_WIDTH-1:0]          weight_dout             ,
  output  [MULT_WEIGHT_ADDR_W-1:0]  weight_addrb            ,

  output  [WH_DATA_WIDTH-1:0]       result_o
);
  //* ============= reg declaration =============
  // -- [pe_ready] logic
  logic                               pe_ready            ;
  logic                               pe_ready_reg        ;
  // -- [result] logic
  logic signed  [WH_DATA_WIDTH-1:0]   result              ;
  logic signed  [WH_DATA_WIDTH-1:0]   result_reg          ;

  logic signed  [WH_DATA_WIDTH-1:0]   products            ;
  logic signed  [WH_DATA_WIDTH-1:0]   products_reg        ;

  logic         [ROW_LEN_WIDTH:0]     counter             ;
  logic         [ROW_LEN_WIDTH:0]     counter_reg         ;

  logic                               calculation_enable  ;
  //* ===========================================

  integer i;

  //* ============ output assignment ============
  assign result_o   = result_reg;
  assign pe_ready_o = pe_ready_reg;
  //* ===========================================


  //* =============== calculation ===============
  assign weight_addrb       = col_idx_i;
  assign calculation_enable = ((counter_reg == 0 && (pe_valid_i || row_length_i == 1)) || (counter_reg > 0 && counter_reg < row_length_i && row_length_i > 1));

  always @(*) begin
    products  = products_reg;
    result    = result_reg;
    counter   = counter_reg;

    if (calculation_enable) begin
      products  = $signed(value_i) * $signed(weight_dout);
      result    = (counter_reg != 0) ? ($signed(result_reg) + $signed(products)) : products;
      counter   = (counter_reg == row_length_i - 1) ? 0 : (counter_reg + 1);
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      products_reg  <= 0;
      counter_reg   <= 0;
      result_reg    <= 0;
    end else begin
      counter_reg   <= counter;
      products_reg  <= products;
      result_reg    <= result;
    end
  end
  //* ===========================================


  //* ================ pe_ready =================
  always @(*) begin
    pe_ready = pe_ready_reg;
    if (pe_ready_reg && (row_length_i > 1)) begin
      pe_ready = 1'b0;
    end else if ((counter_reg == row_length_i - 1) || (row_length_i == 1)) begin
      pe_ready = 1'b1;
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      pe_ready_reg <= 0;
    end else begin
      if (row_length_i == 1 && pe_valid_i) begin
        pe_ready_reg <= 1'b1;
      end else begin
        pe_ready_reg <= pe_ready;
      end
    end
  end
  //* ===========================================
endmodule