// ===================================================================
// File name  : fxp_div_pipe.sv
// Project    : Graph Attention Network Accelerator on FPGA
// Function   :
// -- Fixed-point multiplication computation
// -- Pipeline stage = 2
// Author     : @Germanyy0410
// ===================================================================

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
  input  logic                  vld,
  output logic                  rdy,
  output logic  [WOI+WOF-1:0]   out,
  output logic                  overflow
);

  /* DELAY LENGTH = 2 */
  logic vld_reg_q1;
  logic vld_reg_q2;

	always @(posedge clk or negedge rstn) begin
		if (!rstn) begin
			vld_reg_q1  <= 'b0;
			vld_reg_q2  <= 'b0;
      rdy         <= 'b0;
		end else begin
      vld_reg_q1  <= vld;
      vld_reg_q2  <= vld_reg_q1;
      rdy         <= vld_reg_q2;
		end
	end

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