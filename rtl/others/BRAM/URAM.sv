// ===================================================================
// File name  : URAM.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   : Ultra RAM supporting three types of latency
// Author     : @Germanyy0410
// ===================================================================

module URAM #(
  //* ========== parameter ===========
  parameter DATA_WIDTH      = 19,
  parameter DEPTH           = 242101

  //* ========= localparams ==========
  parameter DATA_ADDR_W     = $clog2(DEPTH)
)(
  input                             clk           ,
  input                             rst_n         ,
  // -- Data Buffer
  input [DATA_WIDTH-1:0]            din           ,
  input [DATA_ADDR_W-1:0]           addra         ,
  input                             ena           ,
  input                             wea           ,
  // -- Data Fetch
  input [DATA_ADDR_W-1:0]           addrb         ,
  output logic  [DATA_WIDTH-1:0]    dout
);

  (* ram_style = "ultra" *)
  logic [DATA_WIDTH-1:0] memory [0:DEPTH-1];

  always_ff @(posedge clk) begin
    if (ena && wea) begin
      memory[addra] <= din;
    end
    dout <= memory[addrb];
  end
endmodule