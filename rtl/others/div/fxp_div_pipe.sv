
//--------------------------------------------------------------------------------------------------------
// Module  : fxp_div_pipe
// Type    : synthesizable
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: division
//           pipeline stage = WOI+WOF+3
//--------------------------------------------------------------------------------------------------------

module fxp_div_pipe #(
	parameter WIIA 	= 256,
	parameter WIFA 	= 0,
	parameter WIIB 	= 256,
	parameter WIFB 	= 0,
	parameter WOI  	= 1,
	parameter WOF  	= 255,
	parameter ROUND	= 1
)(
    input  logic                 rstn,
    input  logic                 clk,
    input  logic [WIIA+WIFA-1:0] dividend,
    input  logic [WIIB+WIFB-1:0] divisor,
    output logic [WOI +WOF -1:0] out,
    output logic                 overflow
);

	initial {out, overflow} = 0;

	localparam WRI = WOI+WIIB > WIIA ? WOI+WIIB : WIIA;
	localparam WRF = WOF+WIFB > WIFA ? WOF+WIFB : WIFA;

	logic [WRI+WRF-1:0]  	divd, divr;
	logic [WOI+WOF-1:0] 	roundedres 	= 0;
	logic               	rsign 			= 1'b0;
	logic                	sign 	[WOI+WOF:0];
	logic [WRI+WRF-1:0]  	acc  	[WOI+WOF:0];
	logic [WRI+WRF-1:0] 	divdp [WOI+WOF:0];
	logic [WRI+WRF-1:0] 	divrp [WOI+WOF:0];
	logic [WOI+WOF-1:0]  	res  	[WOI+WOF:0];
	localparam  [WOI+WOF-1:0] ONEO = 1;

	integer i, ii;

	// initialize all regs
	initial begin
		for(ii = 0; ii <= WOI+WOF; ii = ii+1) begin
			res  [ii] = 0;
			divrp[ii] = 0;
			divdp[ii] = 0;
			acc  [ii] = 0;
			sign [ii] = 1'b0;
		end
	end

	logic [WIIA+WIFA-1:0] ONEA = 1;
	logic [WIIB+WIFB-1:0] ONEB = 1;

	// convert dividend and divisor to positive number
	logic [WIIA+WIFA-1:0] udividend = dividend[WIIA+WIFA-1] ? (~dividend) + ONEA 	: dividend;
	logic [WIIB+WIFB-1:0]	udivisor 	= divisor[WIIB+WIFB-1] 	? (~divisor) + ONEB 	: divisor ;

	fxp_zoom #(
		.WII      ( WIIA      ),
		.WIF      ( WIFA      ),
		.WOI      ( WRI       ),
		.WOF      ( WRF       ),
		.ROUND    ( 0         )
	) dividend_zoom (
		.in       ( udividend ),
		.out      ( divd      ),
		.overflow (           )
	);

	fxp_zoom #(
		.WII      ( WIIB      ),
		.WIF      ( WIFB      ),
		.WOI      ( WRI       ),
		.WOF      ( WRF       ),
		.ROUND    ( 0         )
	)  divisor_zoom (
		.in       ( udivisor  ),
		.out      ( divr      ),
		.overflow (           )
	);

	// 1st pipeline stage: convert dividend and divisor to positive number
	always @(posedge clk or negedge rstn) begin
		if (~rstn) begin
			res[0]   <= 0;
			acc[0]   <= 0;
			divdp[0] <= 0;
			divrp[0] <= 0;
			sign [0] <= 1'b0;
		end else begin
			res[0]   <= 0;
			acc[0]   <= 0;
			divdp[0] <= divd;
			divrp[0] <= divr;
			sign [0] <= dividend[WIIA+WIFA-1] ^ divisor[WIIB+WIFB-1];
		end
	end

	logic [WRI+ WRF-1:0] tmp;

	// from 2nd to WOI+WOF+1 pipeline stages: calculate division
	always @(posedge clk or negedge rstn) begin
		if (~rstn) begin
			for(i = 0; i < WOI+WOF; i = i + 1) begin
				res  [i+1] <= 0;
				divrp[i+1] <= 0;
				divdp[i+1] <= 0;
				acc  [i+1] <= 0;
				sign [i+1] <= 1'b0;
			end
		end else begin
			for(i = 0; i < WOI+WOF; i = i + 1) begin
				res  [i+1] <= res[i];
				divdp[i+1] <= divdp[i];
				divrp[i+1] <= divrp[i];
				sign [i+1] <= sign [i];

				if (i < WOI) begin
					tmp = acc[i] + (divrp[i] << (WOI-1-i));
				end else begin
					tmp = acc[i] + (divrp[i] >> (1+i-WOI));
				end

				if (tmp < divdp[i]) begin
						acc[i+1] <= tmp;
						res[i+1][WOF+WOI-1-i] <= 1'b1;
				end else begin
						acc[i+1] <= acc[i];
						res[i+1][WOF+WOI-1-i] <= 1'b0;
				end
			end
		end
	end

	// next pipeline stage: process round
	always @(posedge clk or negedge rstn) begin
		if (~rstn) begin
			roundedres <= 0;
			rsign      <= 1'b0;
		end else begin
			if (ROUND && ~(&res[WOI+WOF]) && (acc[WOI+WOF]+(divrp[WOI+WOF]>>(WOF))-divdp[WOI+WOF]) < (divdp[WOI+WOF]-acc[WOI+WOF])) begin
				roundedres <= res[WOI+WOF] + ONEO;
			end else begin
				roundedres <= res[WOI+WOF];
			end
			rsign <= sign[WOI+WOF];
		end
	end
	// the last pipeline stage: process roof and output
	always @(posedge clk or negedge rstn) begin
		if (~rstn) begin
			overflow 	<= 1'b0;
			out 			<= 0;
		end else begin
			overflow 	<= 1'b0;

			if (rsign) begin
				if (roundedres[WOI+WOF-1]) begin
					if (|roundedres[WOI+WOF-2:0]) begin
						overflow <= 1'b1;
					end
					out[WOI+WOF-1] 		<= 1'b1;
					out[WOI+WOF-2:0] 	<= 0;
				end else begin
					out <= (~roundedres) + ONEO;
				end
			end else begin
				if (roundedres[WOI+WOF-1]) begin
					overflow 					<= 1'b1;
					out[WOI+WOF-1] 		<= 1'b0;
					out[WOI+WOF-2:0] 	<= {(WOI+WOF){1'b1}};
				end else begin
					out <= roundedres;
				end
			end
		end
	end
endmodule
