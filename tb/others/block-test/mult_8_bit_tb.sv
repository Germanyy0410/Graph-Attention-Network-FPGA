`timescale 1ns / 1ps

module mult_8_bit_tb #(
  parameter MULT_MODE       = 0,
  parameter IN_DATA_WIDTH   = 8,
  parameter OUT_DATA_WIDTH  = 12
)();

  logic                               clk;
  logic signed  [IN_DATA_WIDTH-1:0]   a_i;
  logic signed  [IN_DATA_WIDTH-1:0]   b_i;
  logic signed  [OUT_DATA_WIDTH-1:0]  p_o;

  mult_8_bit dut(.*);

  always #10 clk = ~clk;

	initial begin
    clk   = 1'b1;
    #5000;
    $finish();
  end

	initial begin
		#40.01;
    a_i  = 'd4;
    b_i  = 'd8;
    #20.01;
    a_i  = 'd5;
    b_i  = 'd10;
    #20.01;
    a_i  = 8'b11111001;
    b_i  = 'd15;
    #20.01;
    a_i  = 'd12;
    b_i  = 8'b11111110;
	end

endmodule
