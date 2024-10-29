module W_loader_tb #(
  //* ========== parameter ===========
  parameter DATA_WIDTH        = 8,
  parameter W_NUM_OF_ROWS     = 5,
  parameter W_NUM_OF_COLS     = 5,
  parameter BRAM_ADDR_WIDTH   = 32
) ();
  logic clk;
  logic rst_n;

  logic                             w_valid_i                                           ;

  logic   [DATA_WIDTH-1:0]          Weight_BRAM_dout                                    ;
  logic                             Weight_BRAM_enb                                     ;
  logic   [BRAM_ADDR_WIDTH-1:0]     Weight_BRAM_addrb                                   ;

  logic   [DATA_WIDTH-1:0]          multi_weight_BRAM_dout        [0:W_NUM_OF_COLS-1]   ;
  logic                             multi_weight_BRAM_enb         [0:W_NUM_OF_COLS-1]   ;
  logic   [BRAM_ADDR_WIDTH-1:0]     multi_weight_BRAM_addrb       [0:W_NUM_OF_COLS-1]   ;
  logic                             w_ready_o                                           ;

  logic   [DATA_WIDTH-1:0]          Weight_BRAM_din             ;
  logic                             Weight_BRAM_ena             ;
  logic                             Weight_BRAM_wea             ;
  logic   [BRAM_ADDR_WIDTH-1:0]     Weight_BRAM_addra           ;

  Weight_BRAM_wrapper u_Weight_BRAM_wrapper (
    .clka   (clk                ),
    .dina   (Weight_BRAM_din    ),
    .ena    (Weight_BRAM_ena    ),
    .wea    (Weight_BRAM_wea    ),
    .addra  (Weight_BRAM_addra  ),
    .clkb   (clk                ),
    .doutb  (Weight_BRAM_dout   ),
    .enb    (Weight_BRAM_enb    ),
    .addrb  (Weight_BRAM_addrb  )
  );

  W_loader #(
    .DATA_WIDTH       (DATA_WIDTH       ),
    .W_NUM_OF_COLS    (W_NUM_OF_COLS    ),
    .W_NUM_OF_ROWS    (W_NUM_OF_ROWS    ),
    .BRAM_ADDR_WIDTH  (BRAM_ADDR_WIDTH  )
  ) dut (.*);

  always #10 clk = ~clk;

  initial begin
    clk       = 1'b1;
    rst_n     = 1'b0;
    #22.01;
    rst_n     = 1'b1;
		#5000;
    $finish();
  end

  initial begin
    w_valid_i = 1'b0;
    #40.01;
    Weight_BRAM_ena = 1'b1;
    Weight_BRAM_wea = 1'b1;
    for (integer i = 0; i < 25; i = i + 1) begin
      Weight_BRAM_din   = i + 1;
      Weight_BRAM_addra = i;
      #20.01;
    end
    Weight_BRAM_ena = 1'b0;
    Weight_BRAM_wea = 1'b0;
    #80.01;
    w_valid_i = 1'b1;

    #400.01;
    for (integer i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      multi_weight_BRAM_enb[0]   = 1'b1;
      multi_weight_BRAM_enb[1]   = 1'b1;
      multi_weight_BRAM_enb[2]   = 1'b1;
      multi_weight_BRAM_enb[3]   = 1'b1;
      multi_weight_BRAM_enb[4]   = 1'b1;
      multi_weight_BRAM_addrb[0] = i;
      multi_weight_BRAM_addrb[1] = i;
      multi_weight_BRAM_addrb[2] = i;
      multi_weight_BRAM_addrb[3] = i;
      multi_weight_BRAM_addrb[4] = i;
      #20.01;
    end
  end

endmodule