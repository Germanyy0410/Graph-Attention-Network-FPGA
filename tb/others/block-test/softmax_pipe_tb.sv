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

  logic [NUM_NODE_WIDTH-1:0]        num_node_BRAM_din   ;
  logic [NUM_NODE_ADDR_W-1:0]       num_node_BRAM_addra ;
  logic                             num_node_BRAM_ena   ;
  logic [NUM_NODE_ADDR_W-1:0]       num_node_BRAM_addrb ;
  logic [NUM_NODE_WIDTH-1:0]        num_node_BRAM_dout  ;

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
    .DATA_WIDTH (DATA_WIDTH ),
    .FIFO_DEPTH (100        )
  ) u_coef_FIFO (
    .clk    (clk              ),
    .rst_n  (rst_n            ),
    .din    (coef_FIFO_din    ),
    .wr_vld (coef_FIFO_wr_vld ),
    .dout   (coef_FIFO_dout   ),
    .empty  (coef_FIFO_empty  ),
    .full   (coef_FIFO_full   ),
    .rd_vld (coef_FIFO_rd_vld )
  );

  BRAM #(
    .DATA_WIDTH   (NUM_NODE_WIDTH ),
    .DEPTH        (NUM_NODES_DEPTH),
    .CLK_LATENCY  (1              )
  ) u_num_node_BRAM (
    .clk      (clk                  ),
    .rst_n    (rst_n                ),
    .din      (num_node_BRAM_din    ),
    .addra    (num_node_BRAM_addra  ),
    .ena      (num_node_BRAM_ena    ),
    .dout     (num_node_BRAM_dout   ),
    .addrb    (num_node_BRAM_addrb  )
  );

  always #10 clk = ~clk;

	initial begin
    clk         = 1'b1;
    rst_n       = 1'b0;
    sm_valid_i  = 1'b0;
    #11.01;
    rst_n       = 1'b1;
  end

  initial begin
    #40.01;
    sm_valid_i          = 1'b1;
    coef_FIFO_wr_vld    = 1'b1;
    coef_FIFO_din       = 1;
    #20.01;
    coef_FIFO_din       = 2;
    #20.01;
    coef_FIFO_din       = 3;

    #20.01;
    coef_FIFO_din       = 4;
    #20.01;
    coef_FIFO_din       = 5;

    #20.01;
    coef_FIFO_wr_vld    = 1'b0;
    #100.01;

    #20.01;
    coef_FIFO_wr_vld    = 1'b1;
    coef_FIFO_din       = 6;
    #20.01;
    coef_FIFO_din       = 7;
    #20.01;
    coef_FIFO_din       = 8;
    #20.01;
    coef_FIFO_din       = 9;

    #20.01;
    coef_FIFO_wr_vld    = 1'b0;
    #100.01;

    #20.01;
    coef_FIFO_wr_vld    = 1'b1;
    coef_FIFO_din       = 10;
    #20.01;
    coef_FIFO_din       = 11;
    #20.01;
    coef_FIFO_din       = 12;
    #20.01;
    coef_FIFO_wr_vld    = 1'b0;
  end

  initial begin
    #20.01;
    num_node_BRAM_ena   = 1'b1;
    num_node_BRAM_addra = 0;
    num_node_BRAM_din   = 3;
    #20.01;
    num_node_BRAM_addra = 1;
    num_node_BRAM_din   = 2;
    #20.01;
    num_node_BRAM_addra = 2;
    num_node_BRAM_din   = 4;
    #20.01;
    num_node_BRAM_addra = 3;
    num_node_BRAM_din   = 3;
    #20.01;
    num_node_BRAM_ena   = 1'b0;
  end
endmodule