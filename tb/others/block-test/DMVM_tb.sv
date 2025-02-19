`timescale 1ns / 1ps

module DMVM_tb #(
  //* ========== parameter ===========
  parameter A_SIZE            = 32                                      ,
  parameter DATA_WIDTH        = 8                                       ,
  parameter bram_ADDR_WIDTH   = 32                                      ,
  parameter NUM_OF_NODES      = 168                                     ,

  //* ========= localparams ==========
  parameter INDEX_WIDTH       = $clog2(A_SIZE)                          ,
  parameter HALF_A_SIZE       = A_SIZE / 2                              ,
  parameter MAX_VALUE         = {DATA_WIDTH{1'b1}}                      ,
  parameter NUM_NODE_WIDTH    = $clog2(NUM_OF_NODES)                    ,
  parameter WH_bram_WIDTH     = DATA_WIDTH * 16 + NUM_NODE_WIDTH + 1
) ();
  logic clk;
  logic rst_n;

  logic                             pe_ready_i                                ;
  // -- WH bram
  logic   [WH_bram_WIDTH-1:0]       WH_bram_din                               ;
  logic                             WH_bram_ena                               ;
  logic   [bram_ADDR_WIDTH-1:0]     WH_bram_addra                             ;
  logic   [WH_bram_WIDTH-1:0]       WH_bram_dout                              ;
  logic                             WH_bram_enb                               ;
  logic   [bram_ADDR_WIDTH-1:0]     WH_bram_addrb                             ;
  // -- a
  logic   [DATA_WIDTH-1:0]          a_i             [0:A_SIZE-1]              ;
  // -- logic
  logic   [DATA_WIDTH-1:0]          coef_o          [0:NUM_OF_NODES-1]        ;
  logic                             dmvm_ready_o                              ;

  DMVM #(
    .A_SIZE(A_SIZE),
    .DATA_WIDTH(DATA_WIDTH),
    .bram_ADDR_WIDTH(bram_ADDR_WIDTH),
    .NUM_OF_NODES(NUM_OF_NODES)
  ) dut (.*);

  dual_read_bram #(
    .DATA_WIDTH   (WH_WIDTH             ),
    .DEPTH        (WH_DEPTH             ),
    .CLK_LATENCY  (1                    )
  ) u_WH_bram (
    .clk   (clk           ),
    .dina  (WH_bram_din   ),
    .ena   (WH_bram_ena   ),
    .addra (WH_bram_addra ),
    .doutb (WH_bram_dout  ),
    .enb   (WH_bram_enb   ),
    .addrb (WH_bram_addrb )
  );

  always #10 clk = ~clk;

  initial begin
    clk       = 1'b1;
    rst_n     = 1'b0;
    #300.01;
    rst_n     = 1'b1;
    pe_ready_i = 1'b1;
		#5000;
    $finish();
  end

  initial begin
    WH_bram_ena = 1'b1;
    a_i = {8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3};

    WH_bram_din = {8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd5, 1'd1};
    WH_bram_addra = 32'd0;
    #20.01;
    WH_bram_din = {8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd5, 1'd0};
    WH_bram_addra = 32'd1;
    #20.01;
    WH_bram_din = {8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd5, 1'd0};
    WH_bram_addra = 32'd2;
    #20.01;
    WH_bram_din = {8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd5, 1'd0};
    WH_bram_addra = 32'd3;
    #20.01;
    WH_bram_din = {8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 1'd0};
    WH_bram_addra = 32'd4;
    #20.01;
    // END //
    WH_bram_din = {8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd5, 1'd1};
    WH_bram_addra = 32'd5;
    #20.01;
    WH_bram_din = {8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd5, 1'd0};
    WH_bram_addra = 32'd6;
    #20.01;
    WH_bram_din = {8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd5, 1'd0};
    WH_bram_addra = 32'd7;
    #20.01;
    WH_bram_din = {8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd4, 8'd5, 1'd0};
    WH_bram_addra = 32'd8;
    #20.01;
    WH_bram_din = {8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd1, 8'd5, 1'd0};
    WH_bram_addra = 32'd9;
    #20.01;
    WH_bram_ena = 1'b0;
  end

  initial begin

  end

endmodule