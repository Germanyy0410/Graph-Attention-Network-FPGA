module SP_PE #(
  //* ========== parameter ===========
  parameter DATA_WIDTH          = 8,
  parameter DOT_PRODUCT_SIZE    = 1433,
  parameter BRAM_ADDR_WIDTH     = 32,

  //* ========= localparams ==========
  parameter INDEX_WIDTH         = $clog2(DOT_PRODUCT_SIZE),
  parameter COL_IDX_WIDTH       = $clog2(DOT_PRODUCT_SIZE),
  parameter ROW_LEN_WIDTH       = $clog2(DOT_PRODUCT_SIZE),
  parameter NODE_INFO_WIDTH     = ROW_LEN_WIDTH + 1,
  parameter FF_DATA_WIDTH       = COL_IDX_WIDTH + DATA_WIDTH,
  // -- max value
  parameter MAX_VALUE           = {DATA_WIDTH{1'b1}}
)(
  input                           clk                     ,
  input                           rst_n                   ,

  input                           pe_valid_i              ,
  output                          pe_ready_o              ,

  input   [COL_IDX_WIDTH-1:0]     col_idx_i               ,
  input   [DATA_WIDTH-1:0]        value_i                 ,
  input   [ROW_LEN_WIDTH-1:0]     row_length_i            ,

  input   [DATA_WIDTH-1:0]        Weight_BRAM_dout        ,
  output                          Weight_BRAM_enb         ,
  output  [BRAM_ADDR_WIDTH-1:0]   Weight_BRAM_addrb       ,

  output  [DATA_WIDTH-1:0]        result_o
);
  //* ============= reg declaration =============
  // -- [pe_ready] logic
  reg                           pe_ready        ;
  reg                           pe_ready_reg    ;
  // -- [result] logic
  reg   [DATA_WIDTH-1:0]        result          ;
  reg   [DATA_WIDTH-1:0]        result_reg      ;

  reg   [DATA_WIDTH-1:0]        products        ;
  reg   [DATA_WIDTH-1:0]        products_reg    ;

  reg   [INDEX_WIDTH-1:0]       counter         ;
  reg   [INDEX_WIDTH-1:0]       counter_reg     ;
  //* ===========================================


  //* ============ wire declaration =============
  // -- check overflow
  wire  [DATA_WIDTH*2-1:0]      product_check   ;
  wire  [DATA_WIDTH:0]          sum_check       ;
  // -- H
  wire  [COL_IDX_WIDTH-1:0]     col_idx         ;
  wire  [DATA_WIDTH-1:0]        value           ;
  wire                          node_flag       ;
  //* ===========================================

  integer i;

  //* ============ output assignment ============
  assign result_o   = result_reg;
  assign pe_ready_o = pe_ready_reg;
  //* ===========================================


  //* =============== calculation ===============
  assign Weight_BRAM_addrb  = col_idx_i;
  assign Weight_BRAM_enb    = ((pe_valid_i && (counter_reg == 0)) || ((counter_reg > 0) && (counter_reg < row_length_i - 1))) ? 1'b1 : 1'b0;

  assign product_check      = value_i * Weight_BRAM_dout;
  assign sum_check          = result_reg + products_reg;

  always @(*) begin
    products  = products_reg;
    result    = result_reg;
    counter   = counter_reg;
    if ((pe_valid_i && (counter_reg == 0)) || ((counter_reg > 0) && (counter_reg < row_length_i - 1))) begin
      products  = product_check;
      result    = (sum_check <= MAX_VALUE) ? sum_check : sum_check[8:1];
      counter   = counter_reg + 1;
    end else if (counter_reg == row_length_i - 1) begin
      products  = 0;
      result    = 0;
      counter   = 0;
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
    if (pe_ready_reg) begin
      pe_ready = 1'b0;
    end else if (counter_reg == row_length_i - 1) begin
      pe_ready = 1'b1;
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      pe_ready_reg <= 0;
    end else begin
      pe_ready_reg <= pe_ready;
    end
  end
  //* ===========================================
endmodule