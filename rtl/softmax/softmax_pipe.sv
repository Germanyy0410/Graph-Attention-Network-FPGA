`include "./../others/pkgs/params_pkg.sv"

module softmax_pipe import params_pkg::*;
(
  input                               clk                 ,
  input                               rst_n               ,

  input                               sm_valid_i          ,
  output                              sm_ready_o          ,
  output                              sm_pre_ready_o      ,

  input   [DATA_WIDTH-1:0]            coef_FIFO_dout      ,
  input                               coef_FIFO_empty     ,
  input                               coef_FIFO_full      ,
  output                              coef_FIFO_rd_vld    ,

  input   [NUM_NODE_WIDTH-1:0]        e_node_FIFO_dout    ,
  input                               e_node_FIFO_empty   ,
  input                               e_node_FIFO_full    ,
  output                              e_node_FIFO_rd_vld  ,

  output  [ALPHA_DATA_WIDTH-1:0]      alpha_FIFO_din      ,
  input                               alpha_FIFO_empty    ,
  input                               alpha_FIFO_full     ,
  output                              alpha_FIFO_wr_vld   ,

  output  [NUM_NODE_WIDTH-1:0]        a_node_FIFO_din     ,
  input                               a_node_FIFO_empty   ,
  input                               a_node_FIFO_full    ,
  output                              a_node_FIFO_wr_vld
);

  localparam DIVISOR_FF_WIDTH = NUM_NODE_WIDTH + SM_SUM_DATA_WIDTH;

  logic                         subgraph_done         ;
  logic                         div_subgraph_done     ;
  logic                         coef_FIFO_empty_reg   ;

  // -- handshake
  logic                         div_valid             ;
  logic                         div_ready             ;

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

  logic [DIVISOR_FF_WIDTH-1:0]  divisor_FIFO_din      ;
  logic                         divisor_FIFO_wr_vld   ;
  logic                         divisor_FIFO_full     ;
  logic                         divisor_FIFO_empty    ;
  logic [DIVISOR_FF_WIDTH-1:0]  divisor_FIFO_dout     ;
  logic                         divisor_FIFO_rd_vld   ;
  logic [SM_SUM_DATA_WIDTH-1:0] divisor               ;
  logic [SM_SUM_DATA_WIDTH-1:0] divisor_reg           ;

  logic [ALPHA_DATA_WIDTH-1:0]  out                   ;

  FIFO #(
    .DATA_WIDTH (SM_DATA_WIDTH        ),
    .FIFO_DEPTH (TOTAL_NODES          )
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
    .FIFO_DEPTH (NUM_SUBGRAPHS        )
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

  always_ff @(posedge clk) begin
    coef_FIFO_empty_reg <= coef_FIFO_empty;
  end

  assign subgraph_done        = (node_counter_reg == 0);
  assign div_subgraph_done    = (div_node_counter_reg == 0);
  assign subgraph_div_enable  = (!dividend_FIFO_empty) && ((!divisor_FIFO_empty) && (div_node_counter_reg == 0) || div_node_counter_reg != 0);

  //* ======================== exp & sum ==========================

  // -- get inputs from FIFO
  assign coef_FIFO_rd_vld   = (!coef_FIFO_empty);
  assign e_node_FIFO_rd_vld = (!e_node_FIFO_empty && subgraph_done) ? 1'b1 : 1'b0;

  assign num_of_nodes = e_node_FIFO_rd_vld ? e_node_FIFO_dout : num_of_nodes_reg;

  // -- compute 2^x
  assign exp = (coef_FIFO_dout == ZERO) ? 1 : (1 << coef_FIFO_dout);

  always_comb begin
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
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
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

  // -- push data to FIFO
  assign dividend_FIFO_din    = exp;
  assign dividend_FIFO_wr_vld = coef_FIFO_rd_vld && (!dividend_FIFO_full);

  assign divisor_FIFO_din     = { num_of_nodes_reg, sum_reg };
  assign divisor_FIFO_wr_vld  = subgraph_done && (!divisor_FIFO_full) && (sum_reg != 0) && (!coef_FIFO_empty_reg);
  //* ==============================================================

  // -- get data from FIFO
  assign dividend_FIFO_rd_vld = subgraph_div_enable;
  assign dividend             = dividend_FIFO_dout;

  assign divisor_FIFO_rd_vld            = div_subgraph_done && (!divisor_FIFO_empty);
  assign { div_num_of_nodes, divisor }  = divisor_FIFO_rd_vld ? divisor_FIFO_dout : { div_num_of_nodes_reg, divisor_reg };

  // -- vld signal
  assign div_valid = subgraph_div_enable;

  // -- node counter
  always_comb begin
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

  always_ff @(posedge clk) begin
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

  assign alpha_FIFO_din     = out;
  assign alpha_FIFO_wr_vld  = div_ready && (!alpha_FIFO_full);
endmodule