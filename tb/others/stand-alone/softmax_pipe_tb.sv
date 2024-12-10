`timescale 1ns / 1ps

module softmax_pipe_tb import params_pkg::*;
();
  logic                             clk                 ;
  logic                             rst_n               ;

  logic                             sm_valid_i          ;
  logic                             sm_ready_o          ;
  logic                             sm_pre_ready_o      ;

  logic [DATA_WIDTH-1:0]            coef_FIFO_din       ;
  logic                             coef_FIFO_wr_vld    ;
  logic [DATA_WIDTH-1:0]            coef_FIFO_dout      ;
  logic                             coef_FIFO_empty     ;
  logic                             coef_FIFO_full      ;
  logic                             coef_FIFO_rd_vld    ;

  logic [NUM_NODE_WIDTH-1:0]        e_node_FIFO_din     ;
  logic                             e_node_FIFO_wr_vld  ;
  logic [NUM_NODE_WIDTH-1:0]        e_node_FIFO_dout    ;
  logic                             e_node_FIFO_empty   ;
  logic                             e_node_FIFO_full    ;
  logic                             e_node_FIFO_rd_vld  ;

  logic [ALPHA_DATA_WIDTH-1:0]      alpha_FIFO_din      ;
  logic                             alpha_FIFO_empty    ;
  logic                             alpha_FIFO_full     ;
  logic                             alpha_FIFO_wr_vld   ;

  logic [NUM_NODE_WIDTH-1:0]        a_node_FIFO_din     ;
  logic                             a_node_FIFO_empty   ;
  logic                             a_node_FIFO_full    ;
  logic                             a_node_FIFO_wr_vld  ;

  softmax_pipe dut (.*);

  FIFO #(
    .DATA_WIDTH(DATA_WIDTH),
    .FIFO_DEPTH(100)
  ) u_coef_FIFO (
    .clk(clk),
    .rst_n(rst_n),
    .din(coef_FIFO_din),
    .wr_vld(coef_FIFO_wr_vld),
    .dout(coef_FIFO_dout),
    .empty(coef_FIFO_empty),
    .full(coef_FIFO_full),
    .rd_vld(coef_FIFO_rd_vld)
  );

  FIFO #(
    .DATA_WIDTH(NUM_NODE_WIDTH),
    .FIFO_DEPTH(100)
  ) u_e_node_FIFO (
    .clk(clk),
    .rst_n(rst_n),
    .din(e_node_FIFO_din),
    .wr_vld(e_node_FIFO_wr_vld),
    .dout(e_node_FIFO_dout),
    .empty(e_node_FIFO_empty),
    .full(e_node_FIFO_full),
    .rd_vld(e_node_FIFO_rd_vld)
  );

  always #10 clk = ~clk;

	initial begin
    clk = 1'b1;
    rst_n = 1'b0;
    #11.01;
    rst_n = 1'b1;
    #5000;
    $finish();
  end

  initial begin
    #40.01;
    coef_FIFO_wr_vld    = 1'b1;
    coef_FIFO_din       = 1;
    e_node_FIFO_din     = 3;
    e_node_FIFO_wr_vld  = 1'b1;
    #20.01;
    e_node_FIFO_wr_vld  = 1'b0;
    coef_FIFO_din       = 2;
    #20.01;
    coef_FIFO_din       = 3;

    #20.01;
    coef_FIFO_din       = 4;
    e_node_FIFO_din     = 2;
    e_node_FIFO_wr_vld  = 1'b1;
    #20.01;
    e_node_FIFO_wr_vld  = 1'b0;
    coef_FIFO_din       = 5;

    #20.01;
    coef_FIFO_wr_vld = 1'b0;
    #100.01;

    #20.01;
    coef_FIFO_wr_vld = 1'b1;
    e_node_FIFO_din     = 4;
    e_node_FIFO_wr_vld  = 1'b1;
    coef_FIFO_din       = 6;
    #20.01;
    e_node_FIFO_wr_vld  = 1'b0;
    coef_FIFO_din       = 7;
    #20.01;
    coef_FIFO_din       = 8;
    #20.01;
    coef_FIFO_din       = 9;

    #20.01;
    e_node_FIFO_din     = 3;
    e_node_FIFO_wr_vld  = 1'b1;
    coef_FIFO_din       = 10;
    #20.01;
    e_node_FIFO_wr_vld  = 1'b0;
    coef_FIFO_din       = 11;
    #20.01;
    coef_FIFO_din       = 12;
    #20.01;
    coef_FIFO_wr_vld    = 1'b0;
  end
endmodule