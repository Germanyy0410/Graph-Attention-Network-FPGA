module FIFO #(
  parameter DATA_WIDTH = 40,
  parameter FIFO_DEPTH = 2708
)(
  input                                 clk,
  input                                 rst_n,

  input     [DATA_WIDTH-1:0]            din,
  output    [DATA_WIDTH-1:0]            dout,

  input                                 wr_vld,
  input                                 rd_vld,

  output                                almost_empty_o,
  output                                empty,
  output                                almost_full_o,
  output                                full
);

  localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);
  genvar addr;

  // ------------------ Internal signals ------------------
  logic [ADDR_WIDTH:0]        wr_addr_inc                   ;
  logic [ADDR_WIDTH-1:0]      wr_addr_map                   ;
  logic [ADDR_WIDTH:0]        rd_addr_inc                   ;
  logic [ADDR_WIDTH-1:0]      rd_addr_map                   ;
  logic [DATA_WIDTH-1:0]      buffer_nxt  [0:FIFO_DEPTH-1]  ;

  logic [DATA_WIDTH-1:0]      buffer      [0:FIFO_DEPTH-1]  ;
  logic [ADDR_WIDTH:0]        wr_addr                       ;
  logic [ADDR_WIDTH:0]        rd_addr                       ;
  // ------------------------------------------------------

  assign dout = buffer[rd_addr_map];

  assign wr_addr_inc  = wr_addr + 1'b1;
  assign rd_addr_inc  = rd_addr + 1'b1;
  assign wr_addr_map  = wr_addr[ADDR_WIDTH-1:0];
  assign rd_addr_map  = rd_addr[ADDR_WIDTH-1:0];

  assign empty          = (wr_addr == rd_addr);
  assign almost_empty_o = (rd_addr_inc == wr_addr);
  assign full           = (wr_addr_map == rd_addr_map) & (wr_addr[ADDR_WIDTH] ^ rd_addr[ADDR_WIDTH]);
  assign almost_full_o  = (wr_addr_map + 1'b1 == rd_addr_map);

  generate
    for (addr = 0; addr < FIFO_DEPTH; addr = addr + 1) begin
      assign buffer_nxt[addr] = (wr_addr_map == addr) ? din : buffer[addr];
    end
  endgenerate

  // ------------------ Flip-flop logic ------------------
  generate
    for (addr = 0; addr < FIFO_DEPTH; addr = addr + 1) begin
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          buffer[addr] <= {DATA_WIDTH{1'b0}};
        end
        else if (wr_vld & !full) begin
          buffer[addr] <= buffer_nxt[addr];
        end
      end
    end
  endgenerate

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_addr <= 1'b0;
    end
    else if (wr_vld & !full) begin
      wr_addr <= wr_addr_inc;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_addr <= 0;
    end
    else if (rd_vld & !empty) begin
      rd_addr <= rd_addr_inc;
    end
  end
  // -----------------------------------------------------

endmodule