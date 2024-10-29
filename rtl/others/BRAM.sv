module BRAM #(
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
  // -- Data Fetch
  input   [DATA_ADDR_W-1:0]       addrb         ,
  output  [DATA_WIDTH-1:0]        dout
);
  reg [DATA_WIDTH-1:0]    memory      [0:DEPTH-1]       ;
  reg [DATA_WIDTH-1:0]    data                          ;
  reg [DATA_WIDTH-1:0]    data_q1                       ;

  generate
    if (CLK_LATENCY == 0) begin
      assign dout = memory[addrb];
    end else if (CLK_LATENCY == 1) begin
      assign dout = data;
    end else if (CLK_LATENCY == 2) begin
      assign dout = data_q1;
    end
  endgenerate

  always @(posedge clk) begin
    if (ena) begin
      memory[addra] <= din;
    end
    data    <= memory[addrb];
    data_q1 <= data;
  end
endmodule