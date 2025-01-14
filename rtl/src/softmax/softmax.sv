`include "./../../inc/gat_pkg.sv"

module softmax import gat_pkg::*;
(
  input                               clk                 ,
  input                               rst_n               ,

  input                               sm_valid_i          ,
  output                              sm_ready_o          ,

  input   [DATA_WIDTH-1:0]            coef_FIFO_dout      ,
  input                               coef_FIFO_empty     ,
  output                              coef_FIFO_rd_vld    ,

  input   [NUM_NODE_WIDTH-1:0]        num_node_BRAM_dout  ,
  output  [NUM_NODE_ADDR_W-1:0]       num_node_BRAM_addrb ,

  output  [ALPHA_DATA_WIDTH-1:0]      alpha_FIFO_din      ,
  input                               alpha_FIFO_full     ,
  output                              alpha_FIFO_wr_vld
);

  logic                         subgraph_done         ;
  logic                         div_subgraph_done     ;
  logic                         coef_FIFO_empty_reg   ;

  // -- handshake
  logic                         div_valid             ;
  logic                         div_ready             ;

  // -- addr
  logic [NUM_NODE_ADDR_W-1:0]   addr                  ;
  logic [NUM_NODE_ADDR_W-1:0]   addr_reg              ;

  // -- sum
  logic [SM_DATA_WIDTH-1:0]     exp                   ;
  logic [SM_DATA_WIDTH-1:0]     exp_reg               ;
  logic [SM_SUM_DATA_WIDTH-1:0] sum                   ;
  logic [SM_SUM_DATA_WIDTH-1:0] sum_reg               ;
  logic [NUM_NODE_WIDTH-1:0]    node_counter          ;
  logic [NUM_NODE_WIDTH-1:0]    node_counter_reg      ;
  logic [NUM_NODE_WIDTH-1:0]    num_of_nodes          ;
  logic [NUM_NODE_WIDTH-1:0]    num_of_nodes_reg      ;

  // -- div
  logic [NUM_NODE_WIDTH-1:0]    div_node_counter      ;
  logic [NUM_NODE_WIDTH-1:0]    div_node_counter_reg  ;
  logic [NUM_NODE_WIDTH-1:0]    div_num_of_nodes      ;
  logic [NUM_NODE_WIDTH-1:0]    div_num_of_nodes_reg  ;


  logic [SM_DATA_WIDTH-1:0]     dividend_FIFO_din     ;
  logic                         dividend_FIFO_wr_vld  ;
  logic                         dividend_FIFO_full    ;
  logic                         dividend_FIFO_empty   ;
  logic [SM_DATA_WIDTH-1:0]     dividend_FIFO_dout    ;
  logic                         dividend_FIFO_rd_vld  ;
  logic [SM_DATA_WIDTH-1:0]     dividend              ;

  divisor_t                     divisor_FIFO_din      ;
  logic                         divisor_FIFO_wr_vld   ;
  logic                         divisor_FIFO_full     ;
  logic                         divisor_FIFO_empty    ;
  divisor_t                     divisor_FIFO_dout     ;
  logic                         divisor_FIFO_rd_vld   ;
  logic [SM_SUM_DATA_WIDTH-1:0] divisor               ;
  logic [SM_SUM_DATA_WIDTH-1:0] divisor_reg           ;

  logic [ALPHA_DATA_WIDTH-1:0]  out                   ;

  FIFO #(
    .DATA_WIDTH (SM_DATA_WIDTH        ),
    .FIFO_DEPTH (DIVIDEND_DEPTH       )
  ) u_dividend_FIFO (
    .clk        (clk                  ),
    .rst_n      (rst_n                ),
    .din        (dividend_FIFO_din    ),
    .wr_vld     (dividend_FIFO_wr_vld ),
    .full       (dividend_FIFO_full   ),
    .empty      (dividend_FIFO_empty  ),
    .dout       (dividend_FIFO_dout   ),
    .rd_vld     (dividend_FIFO_rd_vld )
  );

  FIFO #(
    .DATA_WIDTH (DIVISOR_FF_WIDTH     ),
    .FIFO_DEPTH (DIVISOR_DEPTH        )
  ) u_divisor_FIFO (
    .clk        (clk                  ),
    .rst_n      (rst_n                ),
    .din        (divisor_FIFO_din     ),
    .wr_vld     (divisor_FIFO_wr_vld  ),
    .full       (divisor_FIFO_full    ),
    .empty      (divisor_FIFO_empty   ),
    .dout       (divisor_FIFO_dout    ),
    .rd_vld     (divisor_FIFO_rd_vld  )
  );

  always @(posedge clk) begin
    coef_FIFO_empty_reg <= coef_FIFO_empty;
  end

  assign subgraph_done        = (node_counter_reg == 0);
  assign div_subgraph_done    = (div_node_counter_reg == 0);
  assign subgraph_div_enable  = (!dividend_FIFO_empty) && ((!divisor_FIFO_empty) && (div_node_counter_reg == 0) || div_node_counter_reg != 0);

  //* ======================== exp & sum ==========================
  // -- coef from FIFO
  assign coef_FIFO_rd_vld   = (!coef_FIFO_empty) && sm_valid_i;

  // -- num_of_nodes from BRAM
  assign num_node_BRAM_addrb  = addr_reg;
  assign num_of_nodes         = subgraph_done ? num_node_BRAM_dout : num_of_nodes_reg;

  assign addr = (subgraph_done && sm_valid_i && coef_FIFO_rd_vld) ? (addr_reg + 1) : addr_reg;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      addr_reg <= '0;
    end else begin
      addr_reg <= addr;
    end
  end

  // -- compute 2^x
  assign exp = (coef_FIFO_dout == ZERO) ? 1 : (1 << coef_FIFO_dout);

  always @(*) begin
    sum           = sum_reg;
    node_counter  = node_counter_reg;

    if (coef_FIFO_rd_vld) begin
      if (node_counter_reg == num_of_nodes_reg - 1) begin
        node_counter  = '0;
      end else begin
        node_counter  = node_counter_reg + 1;
      end

      if (node_counter_reg == 0) begin
        sum = exp;
      end else begin
        sum = sum_reg + exp;
      end
    end else begin
      if (node_counter_reg == 0) begin
        sum = '0;
      end
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      exp_reg           <= '0;
      sum_reg           <= '0;
      num_of_nodes_reg  <= '0;
      node_counter_reg  <= '0;
    end else begin
      exp_reg           <= exp;
      sum_reg           <= sum;
      num_of_nodes_reg  <= num_of_nodes;
      node_counter_reg  <= node_counter;
    end
  end
  //* ==============================================================


  //* ===================== push data to FIFO ======================
  // -- dividend
  assign dividend_FIFO_din    = exp;
  assign dividend_FIFO_wr_vld = coef_FIFO_rd_vld && (!dividend_FIFO_full);

  // -- divisor
  assign divisor_FIFO_din     = { num_of_nodes_reg, sum_reg };
  assign divisor_FIFO_wr_vld  = subgraph_done && (!divisor_FIFO_full) && (sum_reg != 0) && (!coef_FIFO_empty_reg);
  //* ==============================================================


  //* ===================== get data from FIFO =====================
  // -- dividend
  assign dividend_FIFO_rd_vld = subgraph_div_enable && (!dividend_FIFO_empty);
  assign dividend             = dividend_FIFO_dout;

  // -- divisor
  assign divisor_FIFO_rd_vld            = div_subgraph_done && (!divisor_FIFO_empty);
  assign { div_num_of_nodes, divisor }  = divisor_FIFO_rd_vld ? divisor_FIFO_dout : { div_num_of_nodes_reg, divisor_reg };

  // -- vld signal
  assign div_valid = subgraph_div_enable;

  // -- node counter
  always @(*) begin
    div_node_counter = div_node_counter_reg;
    if (subgraph_div_enable) begin
      if (div_node_counter_reg == div_num_of_nodes_reg - 1) begin
        div_node_counter = '0;
      end else begin
        div_node_counter = div_node_counter_reg + 1;
      end
    end else begin
      div_node_counter = '0;
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      div_node_counter_reg <= '0;
      div_num_of_nodes_reg <= '0;
      divisor_reg          <= '0;
    end else begin
      div_node_counter_reg <= div_node_counter;
      div_num_of_nodes_reg <= div_num_of_nodes;
      divisor_reg          <= divisor;
    end
  end

  (* dont_touch = "yes" *)
  fxp_div_pipe #(
    .WIIA     (SM_DATA_WIDTH      ),
    .WIFA     (0                  ),
    .WIIB     (SM_SUM_DATA_WIDTH  ),
    .WIFB     (0                  ),
    .WOI      (WOI                ),
    .WOF      (WOF                ),
    .ROUND    (0                  )
  ) u_fxp_div_pipe (
    .clk      (clk                ),
    .rstn     (rst_n              ),
    .valid    (div_valid          ),
    .dividend (dividend           ),
    .divisor  (divisor            ),
    .ready    (div_ready          ),
    .out      (out                )
  );
  //* ==============================================================

  assign alpha_FIFO_din     = out;
  assign alpha_FIFO_wr_vld  = div_ready && (!alpha_FIFO_full);
  assign sm_ready_o         = div_ready && (!alpha_FIFO_full);
endmodule