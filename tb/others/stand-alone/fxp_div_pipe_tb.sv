module fxp_div_pipe_tb #(
  parameter WIIA 	= 8,
	parameter WIFA 	= 0,
	parameter WIIB 	= 8,
	parameter WIFB 	= 0,
	parameter WOI  	= 4,
	parameter WOF  	= 8,
	parameter ROUND	= 1
)();

  logic                 rstn;
	logic                 clk;
	logic                 valid;
	logic [WIIA+WIFA-1:0] dividend;
	logic [WIIB+WIFB-1:0] divisor;
	logic                 ready;
	logic [WOI +WOF -1:0] out;
	logic                 overflow;

  fxp_div_pipe #(
    .WIIA(WIIA),
    .WIFA(WIFA),
    .WIIB(WIIB),
    .WIFB(WIFB),
    .WOI(WOI),
    .WOF(WOF),
    .ROUND(ROUND)
  ) dut(.*);

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
    dividend  = 15;
    divisor   = 3;
    valid     = 1'b1;
    #20.01;
    dividend  = 4;
    divisor   = 10;
    #20.01;
    valid     = 1'b0;
	end
endmodule
