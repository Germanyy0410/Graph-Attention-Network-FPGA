// ===================================================================
// File name  : URAM.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   : Ultra RAM supporting three types of latency
// Author     : @Germanyy0410
// ===================================================================

module URAM #(
  //* ========== parameter ===========
  parameter DATA_WIDTH      = 128,
  parameter DEPTH           = 2708,
  parameter CLK_LATENCY     = 1,

  //* ========= localparams ==========
  parameter DATA_ADDR_W     = $clog2(DEPTH)
)(
  input                           clk           ,
  input                           rst_n         ,
  // -- Data Buffer
  input   [DATA_WIDTH-1:0]        din           ,
  input   [DATA_ADDR_W-1:0]       addra         ,
  input                           ena           ,
  input                           wea           ,
  // -- Data Fetch
  input   [DATA_ADDR_W-1:0]       addrb         ,
  output  [DATA_WIDTH-1:0]        dout
);

  (* ram_style = "ultra" *)
  logic [DATA_WIDTH-1:0]    memory    [0:DEPTH-1]         ;

  logic [DATA_WIDTH-1:0]    data                          ;
  logic [DATA_WIDTH-1:0]    data_q1                       ;

  generate
    if (CLK_LATENCY == 0) begin
      assign dout = memory[addrb];
    end else if (CLK_LATENCY == 1) begin
      assign dout = data;
    end else if (CLK_LATENCY == 2) begin
      assign dout = data_q1;
    end
  endgenerate

  always_ff @(posedge clk) begin
    if (ena && wea) begin
      memory[addra] <= din;
    end
    data    <= memory[addrb];
    data_q1 <= data;
  end
endmodule

