module SP_PE #(
  //* ========== parameter ===========
  parameter DATA_WIDTH          = 8,
  parameter DOT_PRODUCT_SIZE    = 1433,

  //* ========= localparams ==========
  parameter INDEX_WIDTH         = $clog2(DOT_PRODUCT_SIZE),
  parameter COL_IDX_WIDTH       = $clog2(DOT_PRODUCT_SIZE),
  parameter NODE_INFO_WIDTH     = $clog2(DOT_PRODUCT_SIZE) + 1,
  parameter FF_DATA_WIDTH       = COL_IDX_WIDTH + DATA_WIDTH,
  // -- max value
  parameter MAX_VALUE           = {DATA_WIDTH{1'b1}}
)(
  input   clk,
  input   rst_n,
  // -- inputs
  input                           pe_valid_i                          ,
  // -- H
  // -- -- col_idx & value
  input   [FF_DATA_WIDTH-1:0]     H_data_o                            ,
  input                           H_full                              ,
  input                           H_empty                             ,
  output                          H_rd_valid                          ,
  // -- -- node_info
  input   [NODE_INFO_WIDTH-1:0]   node_info_i                         ,
  // -- W
  input   [DATA_WIDTH-1:0]        weight_i    [0:DOT_PRODUCT_SIZE-1]  ,
  // -- outputs
  output                          pe_ready_o                          ,
  output  [DATA_WIDTH-1:0]        result_o
);
  //* =========== reg declaration ===========
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
  // -- check overflow
  wire  [DATA_WIDTH*2-1:0]      product_check   ;
  wire  [DATA_WIDTH:0]          sum_check       ;
  // -- H
  wire  [COL_IDX_WIDTH-1:0]     col_idx         ;
  wire  [DATA_WIDTH-1:0]        value           ;
  wire  [NODE_INFO_WIDTH-1:1]   row_len         ;
  wire                          node_flag       ;

  genvar i;

  // design_1_wrapper u_mult (
  //   .clk  (clk                      ),
  //   .A    (value                    ),
  //   .B    (weight_i[col_idx]        ),
  //   .P_0  (product_check            )
  // );

  assign { col_idx, value }     = H_data_o;
  assign { row_len, node_flag } = node_info_i;

  //* ========= output assignment =========
  assign result_o   = result_reg;
  assign pe_ready_o = pe_ready_reg;

  //* ============ calculation ============
  assign sum_check = result_reg + products_reg;

  always @(*) begin
    products  = products_reg;
    result    = result_reg;
    counter   = counter_reg;
    if ((pe_valid_i && (counter_reg == 0)) || (counter_reg > 0)) begin
      if (counter_reg <= row_len) begin
        products  = weight_i[col_idx];
        result    = (sum_check <= MAX_VALUE) ? sum_check : sum_check[8:1];
        counter   = counter_reg + 1;
      end
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

  //* ========= pe_ready =========
  always @(*) begin
    pe_ready = pe_ready_reg;
    if (counter == row_len) begin
      pe_ready = 1'b1;
    end else if (pe_ready_reg) begin
      pe_ready = 1'b0;
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      pe_ready_reg <= 0;
    end else begin
      pe_ready_reg <= pe_ready;
    end
  end
endmodule