// =====================================================================
// File name  : fxp_zoom.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   : Bit width conversion for fixed-point combinational logic
// Author     : @Germanyy0410
// =====================================================================

module fxp_zoom #(
	parameter WII  = 8,
	parameter WIF  = 8,
	parameter WOI  = 8,
	parameter WOF  = 8,
	parameter ROUND= 1
)(
	input  logic [WII+WIF-1:0] in,
	output logic [WOI+WOF-1:0] out,
	output logic               overflow
);

	initial overflow = 1'b0;

	logic [WII+WOF-1:0] inr 	= 0;
	logic [WII-1:0] 		ini		= 0;
	logic [WOI-1:0] 		outi 	= 0;
	logic [WOF-1:0] 		outf 	= 0;

	generate
		if (WOF < WIF) begin
			if (ROUND == 0) begin
					always @(*) begin
						inr = in[WII+WIF-1:WIF-WOF];
					end
			end else if (WII + WOF >= 2) begin
					always @(*) begin
						inr = in[WII+WIF-1:WIF-WOF];
						if (in[WIF-WOF-1] & ~(~inr[WII+WOF-1] & (&inr[WII+WOF-2:0]))) begin
							inr = inr+1;
						end
					end
			end else begin
					always @(*) begin
						inr = in[WII+WIF-1:WIF-WOF];
						if (in[WIF-WOF-1] & inr[WII+WOF-1]) begin
							inr = inr + 1;
						end
					end
			end
		end else if (WOF == WIF) begin
				always @(*) begin
					inr[WII+WOF-1:WOF-WIF] = in;
				end
		end else begin
				always @(*) begin
						inr[WII+WOF-1:WOF-WIF] 	= in;
						inr[WOF-WIF-1:0] 				= 0;
				end
		end
	endgenerate

	generate
		if (WOI < WII) begin
			always @(*) begin
				{ini, outf} = inr;
				if ( ~ini[WII-1] & |ini[WII-2:WOI-1] ) begin
					overflow 		= 1'b1;
					outi 				= {WOI{1'b1}};
					outi[WOI-1] = 1'b0;
					outf 				= {WOF{1'b1}};
				end else if( ini[WII-1] & ~(&ini[WII-2:WOI-1]) ) begin
					overflow 		= 1'b1;
					outi 				= 0;
					outi[WOI-1] = 1'b1;
					outf 				= 0;
				end else begin
					overflow 	= 1'b0;
					outi 			= ini[WOI-1:0];
				end
			end
		end else begin
			always @(*) begin
				{ini, outf} 	= inr;
				overflow 			= 1'b0;
				outi 					= ini[WII-1] ? {WOI{1'b1}} : 0;
				outi[WII-1:0] = ini;
			end
		end
	endgenerate

	assign out = {outi, outf};
endmodule
