module DMVM #(
  //* ========== parameter ===========
  parameter A_DEPTH           = 32                                      ,
  parameter DATA_WIDTH        = 8                                       ,
  parameter WH_ADDR_W         = 32                                      ,
  parameter NUM_OF_NODES      = 168                                     ,
  parameter W_NUM_OF_COLS     = 16                                      ,

  //* ========= localparams ==========
  parameter HALF_A_SIZE       = A_DEPTH / 2                             ,
  parameter MAX_VALUE         = {DATA_WIDTH{1'b1}}                      ,
  parameter NUM_NODE_WIDTH    = $clog2(NUM_OF_NODES) + 1                ,
  parameter WH_WIDTH          = DATA_WIDTH * W_NUM_OF_COLS + NUM_NODE_WIDTH + 1
)(
  input clk,
  input rst_n,

  input                             dmvm_valid_i                              ,
  output                            dmvm_ready_o                              ,
  // -- a
  input                             a_valid_i                                 ,
  input   [DATA_WIDTH-1:0]          a_i             [0:A_DEPTH-1]             ,
  // -- WH BRAM
  input   [WH_WIDTH-1:0]            WH_BRAM_doutb                             ,
  output  [WH_ADDR_W-1:0]           WH_BRAM_addrb                             ,
  // -- output
  output  [DATA_WIDTH-1:0]          coef_o          [0:NUM_OF_NODES-1]        ,
  output  [NUM_NODE_WIDTH-1:0]      num_of_nodes
);
  //* ========== wire declaration ===========
  logic                         dmvm_valid_q1                                 ;
  // -- Weight vector a1 & a2
  logic [DATA_WIDTH-1:0]        a_1                 [0:HALF_A_SIZE-1]         ;
  logic [DATA_WIDTH-1:0]        a_2                 [0:HALF_A_SIZE-1]         ;

  // -- WH array
  logic [WH_ADDR_W-1:0]         WH_addr                                       ;
  logic [WH_ADDR_W-1:0]         WH_addr_reg                                   ;
  logic [DATA_WIDTH-1:0]        WH_arr              [0:HALF_A_SIZE-1]         ;
  logic                         source_node_flag                              ;

  // -- product
  logic [DATA_WIDTH*2-1:0]      product_check       [0:HALF_A_SIZE-1]         ;
  logic [DATA_WIDTH-1:0]        product             [0:HALF_A_SIZE-1]         ;
  logic [DATA_WIDTH-1:0]        product_reg         [0:HALF_A_SIZE-1]         ;
  logic                         product_done                                  ;
  logic                         product_done_reg                              ;
  logic [NUM_NODE_WIDTH:0]      product_size                                  ;
  logic [NUM_NODE_WIDTH:0]      product_size_reg                              ;

  // -- sum
  logic                         sum_done                                      ;
  logic [DATA_WIDTH:0]          sum_check                                     ;
  logic [DATA_WIDTH:0]          sum_check_reg                                 ;

  // -- result
  logic [NUM_NODE_WIDTH-1:0]    idx                                           ;
  logic [NUM_NODE_WIDTH-1:0]    idx_reg                                       ;
  logic                         result_done                                   ;
  logic                         result_done_reg                               ;
  logic [DATA_WIDTH-1:0]        result              [0:NUM_OF_NODES-1]        ;
  logic [DATA_WIDTH-1:0]        result_reg          [0:NUM_OF_NODES-1]        ;

  // -- Relu
  logic                         sub_graph_done                                ;
  logic                         sub_graph_done_reg                            ;
  logic [DATA_WIDTH:0]          r_sum_check         [0:NUM_OF_NODES-1]        ;
  logic [DATA_WIDTH-1:0]        relu                [0:NUM_OF_NODES-1]        ;
  logic [DATA_WIDTH-1:0]        relu_reg            [0:NUM_OF_NODES-1]        ;

  // -- output
  logic                         dmvm_ready                                    ;
  logic                         dmvm_ready_reg                                ;
  //* =======================================

  genvar i;
  integer x;

  //* ============= skid input ==============
  always @(posedge clk) begin
    dmvm_valid_q1 <= dmvm_valid_i;
  end
  //* =======================================


  //* ========== output assignment ==========
  assign dmvm_ready_o = dmvm_ready_reg;

  generate
    for (i = 0; i < NUM_OF_NODES; i = i + 1) begin
      assign coef_o[i] = relu_reg[i];
    end
  endgenerate
  //* =======================================


  //* ========== split vector [a] ===========
  generate
    for (i = 0; i < HALF_A_SIZE; i = i + 1) begin
      assign a_1[i] = a_i[i];
    end

    for (i = 0; i < HALF_A_SIZE; i = i + 1) begin
      assign a_2[i] = a_i[i + HALF_A_SIZE];
    end
  endgenerate
  //* =======================================


  //* ======= get WH data from BRAM =========
  assign source_node_flag = WH_BRAM_doutb[0];
  assign num_of_nodes     = WH_BRAM_doutb[NUM_NODE_WIDTH:1];

  generate
    for (i = 0; i < HALF_A_SIZE; i = i + 1) begin
      assign WH_arr[i] = WH_BRAM_doutb[WH_WIDTH-1-i*DATA_WIDTH : WH_WIDTH-(i+1)*DATA_WIDTH];
    end
  endgenerate
  //* =======================================


  //* =========== WH_BRAM_addrb =============
  assign WH_BRAM_addrb  = WH_addr_reg;

  assign WH_addr = (product_size_reg == 2 && dmvm_valid_i) ? (WH_addr_reg + 1) : WH_addr_reg;

  always @(posedge clk) begin
    if (!rst_n) begin
      WH_addr_reg <= 0;
    end else begin
      WH_addr_reg <= WH_addr;
    end
  end
  //* =======================================


  //* ========== Sum Of Product =============
  generate
    for (i = 0; i < HALF_A_SIZE; i = i + 1) begin
      assign product_check[i] = (source_node_flag) ? (a_1[i] * WH_arr[i]) : (a_2[i] * WH_arr[i]);
    end
  endgenerate

  always @(*) begin
    product_done = product_done_reg;
    product_size = product_size_reg;
    sum_check    = sum_check_reg;

    for (x = 0; x < HALF_A_SIZE; x = x + 1) begin
      product[x] = product_reg[x];
    end

    if (~product_done_reg && dmvm_valid_q1) begin
      for (x = 0; x < HALF_A_SIZE; x = x + 1) begin
        product[x] = (product_check[x] <= MAX_VALUE) ? product_check[x] : product_check[x][15:8];
      end
      product_done = 1'b1;
    end else if (product_done_reg && dmvm_valid_q1) begin
      if (product_size_reg > 1) begin
        for (x = 0; x < HALF_A_SIZE / 2; x = x + 1) begin
          sum_check  = product_reg[2*x] + product_reg[2*x+1];
          product[x] = (sum_check <= MAX_VALUE) ? sum_check : sum_check[8:1];
        end
        product_size = product_size_reg / 2;
      end else if (product_size_reg == 1) begin
        product_size = HALF_A_SIZE;
        product_done = 1'b0;
      end
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      product_done_reg <= 0;
      product_size_reg <= HALF_A_SIZE;
    end else begin
      product_done_reg <= product_done;
      product_size_reg <= product_size;
    end
  end

  generate
    for (i = 0; i < HALF_A_SIZE; i = i + 1) begin
      always @(posedge clk) begin
        if (!rst_n) begin
          product_reg[i] <= 0;
        end else begin
          product_reg[i] <= product[i];
        end
      end
    end
  endgenerate
  //* =======================================


  //* ============== result =================
  assign result_done = (product_size_reg == 2) ? 1'b1 : 1'b0;
  assign idx = ((idx_reg == num_of_nodes - 1) && (product_size_reg == 1)) ? 0 : ((product_size_reg == 1) ? (idx_reg + 1) : idx_reg);

  generate
    for (i = 0; i < NUM_OF_NODES; i = i + 1) begin
      assign result[i] = (i == idx_reg && result_done_reg) ? product_reg[0] : result_reg[i];
    end
  endgenerate

  generate
    for (i = 0; i < NUM_OF_NODES; i = i + 1) begin
      always @(posedge clk) begin
        if (!rst_n) begin
          result_reg[i] <= 0;
        end else begin
          result_reg[i] <= result[i];
        end
      end
    end
  endgenerate

  always @(posedge clk) begin
    if (!rst_n) begin
      idx_reg         <= 0;
      result_done_reg <= 0;
    end else begin
      idx_reg         <= idx;
      result_done_reg <= result_done;
    end
  end
  //* =======================================


  //* ========== ReLU activation ============
  assign sub_graph_done = (sub_graph_done_reg) ? 1'b0 : (((idx_reg == num_of_nodes - 1) && (product_size_reg == 1)) ? 1'b1 : sub_graph_done_reg);

  generate
    for (i = 0; i < NUM_OF_NODES; i = i + 1) begin
      assign r_sum_check[i] = (i < num_of_nodes) ? (result_reg[0] + result_reg[i]) : 0;
      assign relu[i]        = sub_graph_done_reg
                              ? (r_sum_check[i] <= MAX_VALUE) ? r_sum_check[i] : MAX_VALUE
                              : relu_reg[i];
    end
  endgenerate

  always @(posedge clk) begin
    if (!rst_n) begin
      sub_graph_done_reg <= 0;
    end else begin
      sub_graph_done_reg <= sub_graph_done;
    end
  end

  generate
    for (i = 0; i < NUM_OF_NODES; i = i + 1) begin
      always @(posedge clk) begin
        if (!rst_n) begin
          relu_reg[i] <= 0;
        end else begin
          relu_reg[i] <= relu[i];
        end
      end
    end
  endgenerate
  //* =======================================


  //* ============ dmvm_ready ===============
  assign dmvm_ready = (dmvm_ready_reg == 1'b1) ? 1'b0 : ((sub_graph_done_reg == 1'b1) ? 1'b1 : dmvm_ready_reg);

  always @(posedge clk) begin
    if (!rst_n) begin
      dmvm_ready_reg <= 0;
    end else begin
      dmvm_ready_reg <= dmvm_ready;
    end
  end
  //* =======================================
endmodule