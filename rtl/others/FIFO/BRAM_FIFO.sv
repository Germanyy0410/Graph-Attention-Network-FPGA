module BRAM_FIFO #(
  parameter DATA_WIDTH = 40,
  parameter FIFO_DEPTH = 2708
)(
  input                           clk,
  input                           rst_n,
  input  logic [DATA_WIDTH-1:0]   din,
  input  logic                    wr_vld,
  input  logic                    rd_vld,
  output logic [DATA_WIDTH-1:0]   dout,
  output logic                    full,
  output logic                    empty
);
  localparam ADDR_W = $clog2(FIFO_DEPTH);

  logic [ADDR_W-1:0]      addra;
  logic [ADDR_W-1:0]      addra_reg;
  logic [ADDR_W-1:0]      addrb;
  logic [ADDR_W-1:0]      addrb_reg;
  logic [DATA_WIDTH-1:0]  data;

  logic [DATA_WIDTH-1:0]  memory [0:FIFO_DEPTH-1];

  assign full   = (addra == FIFO_DEPTH - 1);
  assign empty  = (addra == 0);
  assign dout   = data;

  always_comb begin
    addra = addra_reg;
    addrb = addrb_reg;

    if (wr_vld && (addra < FIFO_DEPTH - 1)) begin
      addra = addra_reg + 1;
    end else if (rd_vld && (addrb <= addra) && (addrb < FIFO_DEPTH - 1)) begin
      addrb = addrb_reg + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (wr_vld) begin
      memory[addra_reg] <= din;
    end
    data <= memory[addrb_reg];
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      addra_reg <= 0;
      addrb_reg <= 0;
    end else begin
      addra_reg <= addra;
      addrb_reg <= addrb;
    end
  end
endmodule