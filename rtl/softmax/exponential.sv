module exponential #(
  parameter IN_DATA_WIDTH   = 8,
  parameter OUT_DATA_WIDTH  = 184,

	parameter EXP_WIDTH  			= 40,
  parameter INT_BIT         = IN_DATA_WIDTH,
  parameter FRAC_BIT        = EXP_WIDTH - INT_BIT,
	parameter NUM_STAGES      = 23
)(
  input                       clk   ,
  input                       rst_n ,

  input                       valid ,
  output                      ready ,

  input  [IN_DATA_WIDTH-1:0]  din   ,
  output [OUT_DATA_WIDTH-1:0] dout
);

  logic [NUM_STAGES-1:0] [EXP_WIDTH-1:0]			k_LUT									;
  logic [EXP_WIDTH-1:0]  											din_scaled						;
  logic [EXP_WIDTH-1:0]  											din_scaled_reg				;

	logic                       								pipe_valid						;
	logic [NUM_STAGES-1:0]											pipe_valid_shift_reg	;
	logic                                       ready_reg							;

	logic [NUM_STAGES-1:0] [EXP_WIDTH-1:0] 			pipe_exp							;
	logic [NUM_STAGES:0] [EXP_WIDTH-1:0] 				pipe_exp_reg					;

	logic [NUM_STAGES-1:0] [OUT_DATA_WIDTH-1:0] pipe_result						;
	logic [NUM_STAGES:0] [OUT_DATA_WIDTH-1:0] 	pipe_result_reg				;

	genvar i;

	assign k_LUT[0]  = 40'b00001101_00101011011101111100011101100101;  /* 13.169796431 */
	assign k_LUT[1]  = 40'b00001100_01111010000001011010111101101101;  /* 12.476649250 */
	assign k_LUT[2]  = 40'b00001011_11001000100100111001011101110101;  /* 11.783502070 */
	assign k_LUT[3]  = 40'b00001011_00010111001000010111111101111101;  /* 11.090354889 */
	assign k_LUT[4]  = 40'b00001010_01100101101011110110011110000101;  /* 10.397207708 */
	assign k_LUT[5]  = 40'b00001001_10110100001111010100111110001101;  /*  9.704060528 */
	assign k_LUT[6]  = 40'b00001001_00000010110010110011011110010110;  /*  9.010913347 */
	assign k_LUT[7]  = 40'b00001000_01010001010110010001111110011110;  /*  8.317766167 */
	assign k_LUT[8]  = 40'b00000111_10011111111001110000011110100110;  /*  7.624618986 */
	assign k_LUT[9]  = 40'b00000110_11101110011101001110111110101110;  /*  6.931471806 */
	assign k_LUT[10] = 40'b00000110_00111101000000101101011110110110;  /*  6.238324625 */
	assign k_LUT[11] = 40'b00000101_10001011100100001011111110111111;  /*  5.545177444 */
	assign k_LUT[12] = 40'b00000100_11011010000111101010011111000111;  /*  4.852030264 */
	assign k_LUT[13] = 40'b00000100_00101000101011001000111111001111;  /*  4.158883083 */
	assign k_LUT[14] = 40'b00000011_01110111001110100111011111010111;  /*  3.465735903 */
	assign k_LUT[15] = 40'b00000010_11000101110010000101111111011111;  /*  2.772588722 */
	assign k_LUT[16] = 40'b00000010_00010100010101100100011111100111;  /*  2.079441542 */
	assign k_LUT[17] = 40'b00000001_01100010111001000010111111110000;  /*  1.386294361 */
	assign k_LUT[18] = 40'b00000000_10110001011100100001011111111000;  /*  0.693147181 */
	assign k_LUT[19] = 40'b00000000_01100111110011001000111110110011;  /*  0.405465108 */
	assign k_LUT[20] = 40'b00000000_00111001000111111110111110001111;  /*  0.223143551 */
	assign k_LUT[21] = 40'b00000000_00011110001001110000011101101110;  /*  0.117783036 */
	assign k_LUT[22] = 40'b00000000_00001111100001010001100001100000;  /*  0.060624622 */

	assign dout 	= pipe_result_reg[NUM_STAGES];
	assign ready 	= ready_reg;

  assign din_scaled = valid ? ($signed(din) * (1 << FRAC_BIT)) : '0;

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			din_scaled_reg <= '0;
		end else begin
			din_scaled_reg <= din_scaled;
		end
	end

	always_ff @(posedge clk) begin
		pipe_valid <= valid;
	end

	generate
		for (i = 0; i < NUM_STAGES; i = i + 1) begin
			if (i == 0) begin
				assign pipe_exp[i] 		= (pipe_valid && (din_scaled_reg > k_LUT[i])) ? (din_scaled_reg - k_LUT[i]) : din_scaled_reg;
				assign pipe_result[i] = (pipe_valid && (din_scaled_reg > k_LUT[i])) ? (1 << (19 - i)) : '0;
			end else if (i < 19) begin
				assign pipe_exp[i]    = (pipe_exp_reg[i] > k_LUT[i]) ? (pipe_exp_reg[i] - k_LUT[i]) : pipe_exp_reg[i];
				assign pipe_result[i] = (pipe_exp_reg[i] > k_LUT[i]) ? (pipe_result_reg[i] * (1 << (19 - i))) : pipe_result_reg[i];
			end else begin
				assign pipe_exp[i]    = (pipe_exp_reg[i] > k_LUT[i]) ? (pipe_exp_reg[i] - k_LUT[i]) : pipe_exp_reg[i];
				assign pipe_result[i] = (pipe_exp_reg[i] > k_LUT[i]) ? (pipe_result_reg[i] + (pipe_result_reg[i] >> (i - 18))) : pipe_result_reg[i];
			end
		end
	endgenerate

	generate
		for (i = 0; i < NUM_STAGES; i = i + 1) begin
			always_ff @(posedge clk or negedge rst_n) begin
				if (!rst_n) begin
					pipe_exp_reg[i+1] 		<= '0;
					pipe_result_reg[i+1] 	<= '0;
				end else begin
					pipe_exp_reg[i+1]			<= pipe_exp[i];
					pipe_result_reg[i+1]	<= pipe_result[i];
				end
			end
		end
	endgenerate

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			pipe_valid_shift_reg	<= '0;
		end else begin
			pipe_valid_shift_reg	<= { pipe_valid_shift_reg[NUM_STAGES-2:0], pipe_valid };
			ready_reg            	<= pipe_valid_shift_reg[NUM_STAGES-1];
		end
	end

endmodule