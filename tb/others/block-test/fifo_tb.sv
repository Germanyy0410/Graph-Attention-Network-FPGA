module ff_tb #(
  parameter DATA_WIDTH = 8,
  parameter ff_DEPTH = 3
)();

  logic                                 clk;
  logic                                 rst_n;

  logic     [DATA_WIDTH-1:0]            data_i;
  logic    [DATA_WIDTH-1:0]            data_o;

  logic                                 wr_valid_i;
  logic                                 rd_valid_i;

  logic                                almost_empty_o;
  logic                                empty_o;
  logic                                almost_full_o;
  logic                                full_o;

  ff dut(.*);

  always #10 clk = ~clk;

	initial begin
    clk   = 1'b1;

    rst_n = 1'b0;
    #11.01;
    rst_n = 1'b1;

    #5000;
    $finish();
  end

	initial begin
		#40.01;
    for (integer i = 0; i < 200; i = i + 1) begin
      data_i = i;
      wr_valid_i = 1'b1;
      #20.01;
      wr_valid_i = 1'b0;
      rd_valid_i = 1'b1;
      #20.01;
      rd_valid_i = 1'b0;
      #40.01;
    end
	end
endmodule
