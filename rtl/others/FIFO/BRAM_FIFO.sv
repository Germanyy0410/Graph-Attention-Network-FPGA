module BRAM_FIFO #(
  parameter DATA_WIDTH = 40,
  parameter FIFO_DEPTH = 2708
)(
  input                           clk,
  input  logic [DATA_WIDTH-1:0]   din,
  input  logic                    wr_vld,
  input  logic                    rd_vld,
  output logic [DATA_WIDTH-1:0]   dout,
  output logic                    full,
  output logic                    empty
);
  localparam ADDR_W = $clog2(FIFO_DEPTH);

  logic [ADDR_W-1:0]      addra;
  logic [ADDR_W-1:0]      addrb;
  logic [DATA_WIDTH-1:0]  memory [0:FIFO_DEPTH-1];

  assign full   = (addra == FIFO_DEPTH - 1);
  assign empty  = (addra == 0);

  always_ff @(posedge clk) begin
    if (wr_vld && (addra < FIFO_DEPTH - 1)) begin
      memory[addra] <= din;
      addra         <= addra + 1;
    end else if (rd_vld && (addrb <= addra) && (addrb < FIFO_DEPTH - 1)) begin
      dout  <= memory[addrb];
      addrb <= addrb + 1;
    end
  end
endmodule