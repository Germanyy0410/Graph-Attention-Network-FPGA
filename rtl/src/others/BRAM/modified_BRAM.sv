// ===================================================================
// File name  : modified_BRAM.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   :
// -- Block RAM supporting three types of latency
// -- Be able to retrieve the next read data via "dout_nxt" port
// Author     : @Germanyy0410
// ===================================================================

module modified_BRAM #(
  //* ========== parameter ===========
  parameter DATA_WIDTH      = 20            ,
  parameter DEPTH           = 13264         ,
  parameter CLK_LATENCY     = 1             ,

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
  output  [DATA_WIDTH-1:0]        dout          ,
  output  [DATA_WIDTH-1:0]        dout_nxt
);
  logic [DATA_WIDTH-1:0]    memory      [0:DEPTH-1]   ;
  logic [DATA_WIDTH-1:0]    data                      ;
  logic [DATA_WIDTH-1:0]    data_q1                   ;
  logic [DATA_WIDTH-1:0]    data_nxt                  ;
  logic [DATA_WIDTH-1:0]    data_nxt_q1               ;

  generate
    if (CLK_LATENCY == 0) begin
      assign dout     = memory[addrb];
      assign dout_nxt = (addrb < DEPTH - 1) ? memory[addrb+1] : data;
    end else if (CLK_LATENCY == 1) begin
      assign dout     = data;
      assign dout_nxt = (addrb < DEPTH - 1) ? data_nxt : data;
    end else if (CLK_LATENCY == 2) begin
      assign dout     = data_q1;
      assign dout_nxt = (addrb < DEPTH - 1) ? data_nxt_q1 : data;
    end
  endgenerate

  always_ff @(posedge clk) begin
    if (ena && wea) begin
      memory[addra] <= din;
    end
    data        <= memory[addrb];
    data_nxt    <= memory[addrb+1];
    data_q1     <= data;
    data_nxt_q1 <= data_nxt;
  end
endmodule