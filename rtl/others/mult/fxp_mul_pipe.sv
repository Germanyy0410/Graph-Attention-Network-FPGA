module fxp_mul_pipe # (
  parameter WIIA  = 12,
  parameter WIFA  = 0,
  parameter WIIB  = 1,
  parameter WIFB  = 31,
  parameter WOI   = 8,
  parameter WOF   = 32,
  parameter ROUND = 1
)(
  input  logic                  rstn,
  input  logic                  clk,
  input  logic  [WIIA+WIFA-1:0] ina,
  input  logic  [WIIB+WIFB-1:0] inb,
  input  logic                  valid,
  output logic                  ready,
  output logic  [WOI+WOF-1:0]   out,
  output logic                  overflow
);

  // localparam DELAY_LENGTH = 1;
	// logic [DELAY_LENGTH-1:0] valid_shift_reg;

	// always @(posedge clk or negedge rstn) begin
	// 	if (!rstn) begin
	// 		valid_shift_reg <= '0;
	// 		ready 					<= 1'b0;
	// 	end else begin
	// 		valid_shift_reg <= {valid_shift_reg[DELAY_LENGTH-2:0], valid};
	// 		ready 					<= valid_shift_reg[DELAY_LENGTH-1];
	// 	end
	// end

  initial { out, overflow } = 0;

  localparam WRI = WIIA + WIIB;
  localparam WRF = WIFA + WIFB;

  logic [WOI+WOF-1:0]   outc;
  logic                 overflowc;

  logic signed [WRI+WRF-1:0] res = 0;

  always @ (posedge clk or negedge rstn) begin
    if (~rstn) begin
      res <= 0;
    end else begin
      res <= $signed(ina) * $signed(inb);
    end
  end

  fxp_zoom # (
    .WII      ( WRI            ),
    .WIF      ( WRF            ),
    .WOI      ( WOI            ),
    .WOF      ( WOF            ),
    .ROUND    ( ROUND          )
  ) res_zoom (
    .in       ( $unsigned(res) ),
    .out      ( outc           ),
    .overflow ( overflowc      )
  );

  always @ (posedge clk or negedge rstn) begin
    if (~rstn) begin
        out      <= 0;
        overflow <= 1'b0;
    end else begin
        out      <= outc;
        overflow <= overflowc;
    end
  end
endmodule