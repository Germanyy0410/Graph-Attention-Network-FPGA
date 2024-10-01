module SP_PE #(
  //* ========== parameter ===========
  parameter DATA_WIDTH          = 8,
  parameter DOT_PRODUCT_SIZE    = 5,

  //* ========= localparams ==========
  parameter ARR_SIZE_WIDTH      = $clog2(DOT_PRODUCT_SIZE),
  parameter COL_IDX_WIDTH       = $clog2(DOT_PRODUCT_SIZE),
  parameter NODE_INFO_WIDTH     = $clog2(DOT_PRODUCT_SIZE) + 1,
  // -- max value
  parameter MAX_VALUE           = {DATA_WIDTH{1'b1}}
)(
  input   clk,
  input   rst_n,
  // -- inputs
  input                           pe_valid_i                          ,
  // -- -- H
  input   [COL_IDX_WIDTH-1:0]     col_idx_i   [0:DOT_PRODUCT_SIZE-1]  ,
  input   [DATA_WIDTH-1:0]        value_i     [0:DOT_PRODUCT_SIZE-1]  ,
  input   [NODE_INFO_WIDTH-1:0]   node_info_i                         ,
  // -- -- W
  input   [DATA_WIDTH-1:0]        weight_i    [0:DOT_PRODUCT_SIZE-1]  ,
  // -- outputs
  output                          pe_ready_o                          ,
  output  [DATA_WIDTH-1:0]        result_o
);
  //* ========== wire declaration ===========
  // -- -- pe_valid
  wire                          pe_valid                              ;
  // -- -- feature row
  wire  [COL_IDX_WIDTH-1:0]     col_idx       [0:DOT_PRODUCT_SIZE-1]  ;
  wire  [DATA_WIDTH-1:0]        value         [0:DOT_PRODUCT_SIZE-1]  ;
  wire  [NODE_INFO_WIDTH-1:0]   node_info												      ;
  // -- -- weight column
  wire  [DATA_WIDTH-1:0]        weight        [0:DOT_PRODUCT_SIZE-1]  ;

  //* =========== reg declaration ===========
  // -- multilpication flag
  reg                           products_enable                       ;
  reg                           products_enable_reg                   ;
  // -- [pe_ready] logic
  reg                           pe_ready                              ;
  reg                           pe_ready_reg                          ;
  // -- [result] logic
  reg   [DATA_WIDTH-1:0]        result                                ;
  reg   [DATA_WIDTH-1:0]        result_reg                            ;
  // -- sizeof(products)
  reg   [ARR_SIZE_WIDTH-1:0]    arr_size                              ;
  reg   [ARR_SIZE_WIDTH-1:0]    arr_size_reg                          ;
  // -- [products] logic
  reg   [DATA_WIDTH-1:0]        products      [0:DOT_PRODUCT_SIZE-1]  ;
  reg   [DATA_WIDTH-1:0]        products_reg  [0:DOT_PRODUCT_SIZE-1]  ;
  // -- check overflow
  reg   [DATA_WIDTH*2-1:0]      product_check                         ;
  reg   [DATA_WIDTH:0]          sum_check                             ;
  reg   [DATA_WIDTH:0]          result_check                          ;

  //* ======== internal declaration =======
  integer i;
  genvar a;

  //* ========= input assignment ==========
  assign pe_valid  = pe_valid_i;
  assign col_idx   = col_idx_i;
  assign value     = value_i;
  assign node_info = node_info_i;
  assign weight    = weight_i;

  //* ========= output assignment =========
  assign result_o   = result_reg;
  assign pe_ready_o = pe_ready_reg;

  //* ============ calculation ============
  always @(*) begin
    for (i = 0; i < DOT_PRODUCT_SIZE; i = i + 1) begin
      products[i] = products_reg[i];
    end
    arr_size        = arr_size_reg;
    products_enable = products_enable_reg;
    product_check   = 0;
    sum_check       = 0;

    if (pe_valid && ~products_enable_reg) begin          // receive data
      for (i = 0; i < DOT_PRODUCT_SIZE; i = i + 1) begin
        if (i < node_info[NODE_INFO_WIDTH-1:1]) begin
          product_check         = value[i] * weight[col_idx[i]];
          products[col_idx[i]]  = (product_check <= MAX_VALUE) ? product_check : product_check[15:8];
        end
      end
      arr_size        = DOT_PRODUCT_SIZE;
      products_enable = 1'b1;
    end else if (products_enable_reg) begin     // after multiplication
      if (arr_size_reg > 1) begin            // reduce array size
        for (i = 0; i < DOT_PRODUCT_SIZE / 2; i = i + 1) begin
          if (i < arr_size_reg) begin
            sum_check   = products_reg[2*i] + products_reg[2*i+1];
            products[i] = (sum_check <= MAX_VALUE) ? sum_check : sum_check[8:1];
            arr_size    = (arr_size_reg >> 1);
          end
        end
      end else begin                        // final result -> reset
        products_enable = 1'b0;
        arr_size        = DOT_PRODUCT_SIZE;
        for (i = 0; i < DOT_PRODUCT_SIZE; i = i + 1) begin
          products[i] = 0;
        end
      end
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      arr_size_reg        <= DOT_PRODUCT_SIZE;
      products_enable_reg <= 1'b0;
    end else begin
      arr_size_reg        <= arr_size;
      products_enable_reg <= products_enable;
    end
  end

  generate
    for (a = 0; a < DOT_PRODUCT_SIZE; a = a + 1) begin
      always @(posedge clk) begin
        if (!rst_n) begin
          products_reg[a] <= 0;
        end else begin
          products_reg[a] <= products[a];
        end
      end
    end
  endgenerate

  //* ========= pe_ready =========
  always @(*) begin
    pe_ready = pe_ready_reg;
    if ((arr_size_reg == 1) && (~pe_ready_reg)) begin
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

  //* ========== result ==========
  always @(*) begin
    result        = result_reg;
    result_check  = 0;
    if (pe_ready) begin
      if (DOT_PRODUCT_SIZE % 2 == 1) begin
        result_check  = products_reg[0] + products_reg[DOT_PRODUCT_SIZE-1];
        result        = (result_check <= MAX_VALUE) ? result_check : result_check[8:1];
      end else begin
        result = products_reg[0];
      end
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      result_reg <= 0;
    end else begin
      result_reg <= result;
    end
  end
endmodule