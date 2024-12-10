`include "./../others/pkgs/params_pkg.sv"

module DMVM_pipe import params_pkg::*;
(
  input                                         clk             ,
  input                                         rst_n           ,

  input                                         dmvm_valid_i    ,
  output                                        dmvm_ready_o    ,
  // -- a
  input                                         a_valid_i       ,
  input   [A_DEPTH-1:0] [DATA_WIDTH-1:0]        a_i             ,
  // -- WH BRAM
  input   [WH_WIDTH-1:0]                        WH_BRAM_dout    ,
  output  [WH_1_ADDR_W-1:0]                     WH_BRAM_addrb   ,
  // -- output
  output  [MAX_NODES-1:0] [DATA_WIDTH-1:0]      coef_o          ,
  output  [NUM_NODE_WIDTH-1:0]                  num_of_nodes_o
);
  //* ========== logic declaration ===========
  logic                                                   dmvm_valid_q1       ;
  // -- Weight vector a1 & a2
  logic         [HALF_A_SIZE-1:0] [DATA_WIDTH-1:0]        a_source            ;
  logic         [HALF_A_SIZE-1:0] [DATA_WIDTH-1:0]        a_neighbor          ;

  // -- WH array
  logic         [WH_1_ADDR_W-1:0]                         WH_addr             ;
  logic         [WH_1_ADDR_W-1:0]                         WH_addr_reg         ;
  logic         [HALF_A_SIZE-1:0] [WH_DATA_WIDTH-1:0]     WH_arr              ;
  logic                                                   source_node_flag    ;

  // -- product
  logic signed  [HALF_A_SIZE-1:0] [DMVM_DATA_WIDTH-1:0]   product             ;
  logic signed  [HALF_A_SIZE-1:0] [DMVM_DATA_WIDTH-1:0]   product_reg         ;
  logic                                                   product_done        ;
  logic                                                   product_done_reg    ;
  logic         [DMVM_PRODUCT_WIDTH:0]                    product_size        ;
  logic         [DMVM_PRODUCT_WIDTH:0]                    product_size_reg    ;

  // -- sum
  logic                                                   sum_done            ;

  // -- result
  logic         [NUM_NODE_WIDTH-1:0]                      idx                 ;
  logic         [NUM_NODE_WIDTH-1:0]                      idx_reg             ;
  logic                                                   result_done         ;
  logic                                                   result_done_reg     ;
  logic signed  [MAX_NODES-1:0] [DMVM_DATA_WIDTH-1:0]     result              ;
  logic signed  [MAX_NODES-1:0] [DMVM_DATA_WIDTH-1:0]     result_reg          ;

  // -- Relu
  logic                                                   sub_graph_done      ;
  logic                                                   sub_graph_done_reg  ;
  logic signed  [MAX_NODES-1:0] [DMVM_DATA_WIDTH-1:0]     r_sum_check         ;
  logic signed  [MAX_NODES-1:0] [DATA_WIDTH-1:0]          relu                ;
  logic signed  [MAX_NODES-1:0] [DATA_WIDTH-1:0]          relu_reg            ;
  logic         [NUM_NODE_WIDTH-1:0]                      num_of_nodes        ;
  logic         [NUM_NODE_WIDTH-1:0]                      num_of_nodes_q1     ;
  logic         [NUM_NODE_WIDTH-1:0]                      num_of_nodes_fn     ;
  logic         [NUM_NODE_WIDTH-1:0]                      num_of_nodes_fn_reg ;

  // -- output
  logic                                                   dmvm_ready          ;
  logic                                                   dmvm_ready_reg      ;
  //* =======================================

  genvar i;
  integer x;

  //* ============= skid input ==============
  always_ff @(posedge clk) begin
    dmvm_valid_q1 <= dmvm_valid_i;
  end
  //* =======================================


  //* ========== output assignment ==========
  assign dmvm_ready_o   = dmvm_ready_reg;
  assign num_of_nodes_o = num_of_nodes_fn_reg;
  generate
    for (i = 0; i < MAX_NODES; i = i + 1) begin
      assign coef_o[i] = relu_reg[i];
    end
  endgenerate
  //* =======================================


  //* ========== split vector [a] ===========
  generate
    for (i = 0; i < HALF_A_SIZE; i = i + 1) begin
      assign a_source[i] = a_i[i];
    end

    for (i = 0; i < HALF_A_SIZE; i = i + 1) begin
      assign a_neighbor[i] = a_i[i + HALF_A_SIZE];
    end
  endgenerate
  //* =======================================


  //* ======= get WH data from BRAM =========
  assign source_node_flag = WH_BRAM_dout[0];
  assign num_of_nodes     = WH_BRAM_dout[NUM_NODE_WIDTH:1];

  generate
    for (i = 0; i < HALF_A_SIZE; i = i + 1) begin
      assign WH_arr[i] = WH_BRAM_dout[WH_WIDTH-1-i*WH_DATA_WIDTH : WH_WIDTH-(i+1)*WH_DATA_WIDTH];
    end
  endgenerate
  //* =======================================


  //* ========= num_of_nodes logic ==========
  always_ff @(posedge clk) begin
    num_of_nodes_q1 <= num_of_nodes;
  end

  assign num_of_nodes_fn = (sub_graph_done_reg) ? num_of_nodes_q1 : num_of_nodes_fn_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      num_of_nodes_fn_reg <= 0;
    end else begin
      num_of_nodes_fn_reg <= num_of_nodes_fn;
    end
  end
  //* =======================================


  //* =========== WH_BRAM_addrb =============
  assign WH_BRAM_addrb  = WH_addr_reg;

  assign WH_addr = ((product_size_reg == 2 || product_size_reg == 3) && dmvm_valid_i) ? ((WH_addr_reg < WH_1_DEPTH - 1) ? (WH_addr_reg + 1) : 0) : WH_addr_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      WH_addr_reg <= 0;
    end else begin
      WH_addr_reg <= WH_addr;
    end
  end
  //* =======================================


  //* ========== Sum Of Product =============
  always_comb begin
    product_done = product_done_reg;
    product_size = product_size_reg;
    for (x = 0; x < HALF_A_SIZE; x = x + 1) begin
      product[x] = product_reg[x];
    end

    if (~product_done_reg && dmvm_valid_q1) begin
      for (x = 0; x < HALF_A_SIZE; x = x + 1) begin
        product[x] = (source_node_flag) ? ($signed(a_source[x]) * $signed(WH_arr[x])) : ($signed(a_neighbor[x]) * $signed(WH_arr[x]));
      end
      product_done = 1'b1;
    end else if (product_done_reg && dmvm_valid_q1) begin
      if (product_size_reg > 1) begin
        for (x = 0; x < HALF_A_SIZE / 2; x = x + 1) begin
          product[x] = $signed(product_reg[2*x]) + $signed(product_reg[2*x+1]);
        end
        product_size = product_size_reg >> 1;
      end else if (product_size_reg == 1) begin
        product_size = HALF_A_SIZE;
        product_done = 1'b0;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      product_done_reg <= 0;
      product_size_reg <= HALF_A_SIZE;
      product_reg      <= '0;
    end else begin
      product_done_reg <= product_done;
      product_size_reg <= product_size;
      product_reg      <= product;
    end
  end
  //* =======================================


  //* ============== result =================
  assign result_done = (product_size_reg == 2 || product_size_reg == 3) ? 1'b1 : 1'b0;

  always_comb begin
    idx = idx_reg;
    if ((idx_reg == num_of_nodes - 1) && (product_size_reg == 1)) begin
      idx = 0;
    end else if (product_size_reg == 1) begin
      idx = idx_reg + 1;
    end
  end

  generate
    for (i = 0; i < MAX_NODES; i = i + 1) begin
      assign result[i] = (i == idx_reg && result_done_reg) ? (product_reg[0] + product_reg[2]) : result_reg[i];
    end
  endgenerate

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      idx_reg         <= 0;
      result_done_reg <= 0;
      result_reg      <= '0;
    end else begin
      idx_reg         <= idx;
      result_done_reg <= result_done;
      result_reg      <= result;
    end
  end
  //* =======================================


  //* ========== ReLU activation ============
  always_comb begin
    sub_graph_done = sub_graph_done_reg;
    if (sub_graph_done_reg) begin
      sub_graph_done = 1'b0;
    end else if ((idx_reg == num_of_nodes - 1) && (product_size_reg == 1)) begin
      sub_graph_done = 1'b1;
    end
  end

  generate
    for (i = 0; i < MAX_NODES; i = i + 1) begin
      always_comb begin
        relu[i] = relu_reg[i];

        if (i < num_of_nodes_q1) begin
          r_sum_check[i] = $signed(result_reg[0]) + $signed(result_reg[i]);
        end else begin
          r_sum_check[i] = 0;
        end

        if (sub_graph_done_reg) begin
          if ($signed(r_sum_check[i]) < ZERO) begin
            relu[i] = 0;
          end else begin
            relu[i] = r_sum_check[i] >> (DMVM_DATA_WIDTH - DATA_WIDTH);
          end
        end
      end
    end
  endgenerate

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      relu_reg            <= '0;
      sub_graph_done_reg  <= 0;
    end else begin
      relu_reg            <= relu;
      sub_graph_done_reg  <= sub_graph_done;
    end
  end
  //* =======================================


  //* ============ dmvm_ready ===============
  always_comb begin
    dmvm_ready = dmvm_ready_reg;
    if (dmvm_ready_reg == 1'b1) begin
      dmvm_ready = 1'b0;
    end else if (sub_graph_done_reg == 1'b1) begin
      dmvm_ready = 1'b1;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dmvm_ready_reg <= 0;
    end else begin
      dmvm_ready_reg <= dmvm_ready;
    end
  end
  //* =======================================
endmodule