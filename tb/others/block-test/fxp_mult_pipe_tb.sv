module fxp_mul_pipe_tb # (
  parameter WIIA = 12,
  parameter WIFA = 0,
  parameter WIIB = 1,
  parameter WIFB = 31,
  parameter WOI  = 8,
  parameter WOF  = 32,
  parameter ROUND= 1
)();
  logic                  rstn;
  logic                  clk;
  logic  [WIIA+WIFA-1:0] ina;
  logic  [WIIB+WIFB-1:0] inb;
  logic                  valid;
  logic                  ready;
  logic  [WOI +WOF -1:0] out;
  logic                  overflow;

  fxp_mul_pipe #(
    .WIIA(WIIA),
    .WIFA(WIFA),
    .WIIB(WIIB),
    .WIFB(WIFB),
    .WOI(WOI),
    .WOF(WOF),
    .ROUND(ROUND)
  ) dut (.*);

  always #10 clk = ~clk;

	initial begin
    clk = 1'b1;
    rstn = 1'b0;
    #11.01;
    rstn = 1'b1;
    #5000;
    $finish();
  end

  initial begin
    #40.01;
    ina   = 12'b111111110001;
    inb   = 32'b01101000011011010011101001111100;
    valid = 1'b1;
    #20.01;
    ina   = 12'b000000101000;
    inb   = 32'b00011001101100111111111000101101;
    #20.01;
    valid = 1'b0;
  end

endmodule
