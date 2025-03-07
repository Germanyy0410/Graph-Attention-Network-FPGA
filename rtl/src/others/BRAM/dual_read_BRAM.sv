// ===================================================================
// File name  : dual_read_BRAM.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   :
// -- Block RAM supporting three types of latency
// -- Dual read ports
// Author     : @Germanyy0410
// ===================================================================

module dual_read_BRAM #(
  //* ========== parameter ===========
  parameter DATA_WIDTH      = 201           ,
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
  output  [DATA_WIDTH-1:0]        doutb         ,

  input   [DATA_ADDR_W-1:0]       addrc         ,
  output  [DATA_WIDTH-1:0]        doutc
);
  logic [DATA_WIDTH-1:0]    memory      [0:DEPTH-1]       ;
  logic [DATA_WIDTH-1:0]    data_b                        ;
  logic [DATA_WIDTH-1:0]    data_b_q1                     ;
  logic [DATA_WIDTH-1:0]    data_c                        ;
  logic [DATA_WIDTH-1:0]    data_c_q1                     ;

  generate
    if (CLK_LATENCY == 1) begin
      assign doutb = data_b;
      assign doutc = data_c;
    end else if (CLK_LATENCY == 2) begin
      assign doutb = data_b_q1;
      assign doutc = data_c_q1;
    end
  endgenerate

  always_ff @(posedge clk) begin
    if (ena && wea) begin
      memory[addra] <= din;
    end
    data_b    <= memory[addrb];
    data_c    <= memory[addrc];
    data_b_q1 <= data_b;
    data_c_q1 <= data_c;
  end
endmodule