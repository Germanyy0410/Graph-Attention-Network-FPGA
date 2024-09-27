`timescale 1ns / 1ps

module scheduler_tb #(
  parameter NUM_OF_COLS     = 5,
  parameter NUM_OF_ROWS     = 5,

  parameter ROW_LEN_WIDTH   = 8,
  parameter INDEX_WIDTH     = 8,

  parameter COL_IDX_WIDTH   = 8,
  parameter VALUE_WIDTH     = 8,
  parameter NODE_INFO_WIDTH = ROW_LEN_WIDTH + INDEX_WIDTH + 1,

  parameter COL_INDEX_SIZE  = 8,
  parameter VALUE_SIZE      = 8,
  parameter NODE_INFO_SIZE  = 5,

  parameter ROW_INFO_WIDTH  = ROW_LEN_WIDTH + 1
  )();
  reg                   clk;
  reg                   rst_n;

  reg                   sched_valid;
  wire                  sched_ready;

  reg [COL_IDX_WIDTH-1:0]   col_idx_i      [0:COL_INDEX_SIZE-1];
  reg [VALUE_WIDTH-1:0]     value_i        [0:VALUE_SIZE-1];
  reg [NODE_INFO_WIDTH-1:0] node_info_i    [0:NODE_INFO_SIZE-1];

  reg [COL_IDX_WIDTH-1:0]   row_col_idx  [0:NUM_OF_ROWS-1] [0:NUM_OF_COLS-1];
  reg [VALUE_WIDTH-1:0]     row_value    [0:NUM_OF_ROWS-1] [0:NUM_OF_COLS-1];
  reg [ROW_INFO_WIDTH-1:0]  row_info     [0:NUM_OF_ROWS-1];

  scheduler dut (
    .clk(clk),
    .rst_n(rst_n),
    .sched_valid(sched_valid),
    .sched_ready(sched_ready),
    .col_idx_i(col_idx_i),
    .value_i(value_i),
    .node_info_i(node_info_i),
    .row_col_idx(row_col_idx),
    .row_value(row_value),
    .row_info(row_info)
  );

  always #10 clk = ~clk;

  initial begin
    clk = 1'b1;
    rst_n = 1'b0;
    #11.01;
    rst_n = 1'b1;
  end

  initial begin
    sched_valid = 1'b0;
    #20.10;
    sched_valid = 1'b1;
    col_idx_i     = { 8'd0, 8'd4, 8'd2, 8'd4, 8'd1, 8'd3, 8'd2, 8'd4};
    value_i       = { 8'd2, 8'd9, 8'd7, 8'd8, 8'd6, 8'd5, 8'd3, 8'd1};
    node_info_i   = { {8'd0, 8'd2, 1'd0}, {8'd2, 8'd2, 1'd0}, {8'd4, 8'd2, 1'd0}, {8'd6, 8'd1, 1'd0}, {8'd7, 8'd1, 1'd0} };

    #20.01;
    sched_valid = 1'b0;
    #5000;
    $finish();
  end

endmodule
