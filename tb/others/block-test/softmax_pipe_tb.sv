`timescale 1ns / 1ps

module softmax_pipe_tb import params_pkg::*;
();
  logic                             clk                 ;
  logic                             rst_n               ;

  logic                             sm_valid_i          ;
  logic                             sm_ready_o          ;
  logic                             sm_pre_ready_o      ;

  logic [DATA_WIDTH-1:0]            coef_ff_din       ;
  logic                             coef_ff_wr_vld    ;
  logic [DATA_WIDTH-1:0]            coef_ff_dout      ;
  logic                             coef_ff_empty     ;
  logic                             coef_ff_full      ;
  logic                             coef_ff_rd_vld    ;

  logic [NUM_NODE_WIDTH-1:0]        num_node_bram_din   ;
  logic [NUM_NODE_ADDR_W-1:0]       num_node_bram_addra ;
  logic                             num_node_bram_ena   ;
  logic [NUM_NODE_ADDR_W-1:0]       num_node_bram_addrb ;
  logic [NUM_NODE_WIDTH-1:0]        num_node_bram_dout  ;

  logic [ALPHA_DATA_WIDTH-1:0]      alpha_ff_din      ;
  logic                             alpha_ff_empty    ;
  logic                             alpha_ff_full     ;
  logic                             alpha_ff_wr_vld   ;

  logic [NUM_NODE_WIDTH-1:0]        a_node_ff_din     ;
  logic                             a_node_ff_empty   ;
  logic                             a_node_ff_full    ;
  logic                             a_node_ff_wr_vld  ;

  softmax_pipe dut (.*);

  ff #(
    .DATA_WIDTH (DATA_WIDTH ),
    .ff_DEPTH (100        )
  ) u_coef_ff (
    .clk    (clk              ),
    .rst_n  (rst_n            ),
    .din    (coef_ff_din    ),
    .wr_vld (coef_ff_wr_vld ),
    .dout   (coef_ff_dout   ),
    .empty  (coef_ff_empty  ),
    .full   (coef_ff_full   ),
    .rd_vld (coef_ff_rd_vld )
  );

  bram #(
    .DATA_WIDTH   (NUM_NODE_WIDTH ),
    .DEPTH        (NUM_NODES_DEPTH),
    .CLK_LATENCY  (1              )
  ) u_num_node_bram (
    .clk      (clk                  ),
    .rst_n    (rst_n                ),
    .din      (num_node_bram_din    ),
    .addra    (num_node_bram_addra  ),
    .ena      (num_node_bram_ena    ),
    .dout     (num_node_bram_dout   ),
    .addrb    (num_node_bram_addrb  )
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
    coef_ff_wr_vld    = 1'b1;
    coef_ff_din       = 1;
    #20.01;
    coef_ff_din       = 2;
    #20.01;
    coef_ff_din       = 3;

    #20.01;
    coef_ff_din       = 4;
    #20.01;
    coef_ff_din       = 5;

    #20.01;
    coef_ff_wr_vld    = 1'b0;
    #100.01;

    #20.01;
    coef_ff_wr_vld    = 1'b1;
    coef_ff_din       = 6;
    #20.01;
    coef_ff_din       = 7;
    #20.01;
    coef_ff_din       = 8;
    #20.01;
    coef_ff_din       = 9;

    #20.01;
    coef_ff_wr_vld    = 1'b0;
    #100.01;

    #20.01;
    coef_ff_wr_vld    = 1'b1;
    coef_ff_din       = 10;
    #20.01;
    coef_ff_din       = 11;
    #20.01;
    coef_ff_din       = 12;
    #20.01;
    coef_ff_wr_vld    = 1'b0;
  end

  initial begin
    #20.01;
    num_node_bram_ena   = 1'b1;
    num_node_bram_addra = 0;
    num_node_bram_din   = 3;
    #20.01;
    num_node_bram_addra = 1;
    num_node_bram_din   = 2;
    #20.01;
    num_node_bram_addra = 2;
    num_node_bram_din   = 4;
    #20.01;
    num_node_bram_addra = 3;
    num_node_bram_din   = 3;
    #20.01;
    num_node_bram_ena   = 1'b0;
  end
endmodule