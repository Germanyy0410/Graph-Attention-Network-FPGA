`timescale 1ns / 1ps

module H_loader_tb #(
  //* ========== parameter ===========
  parameter DATA_WIDTH        = 8,
  parameter NUM_OF_COLS       = 5,
  parameter NUM_OF_ROWS       = 5,
  parameter COL_INDEX_SIZE    = 8,
  parameter VALUE_SIZE        = 8,
  parameter NODE_INFO_SIZE    = 5,

  //* ========= localparams ==========
  // -- inputs
  // -- -- col_idx
  parameter COL_IDX_WIDTH     = $clog2(NUM_OF_COLS),
  // -- -- value
  parameter VALUE_WIDTH       = DATA_WIDTH,
  // -- -- node_info = [idx, row_len, flag]
  parameter INDEX_WIDTH       = $clog2(COL_INDEX_SIZE),
  parameter ROW_LEN_WIDTH     = $clog2(NUM_OF_COLS),
  parameter NODE_INFO_WIDTH   = INDEX_WIDTH + ROW_LEN_WIDTH + 1,
  // -- outputs
  // -- -- row_info = [row_len, flag]
  parameter ROW_INFO_WIDTH    = ROW_LEN_WIDTH + 1
  )();
  logic clk;
  logic rst_n;

  logic                         sched_valid_i                                         ;
  logic [COL_IDX_WIDTH-1:0]     col_idx_i       [0:COL_INDEX_SIZE-1]                  ;
  logic [VALUE_WIDTH-1:0]       value_i         [0:VALUE_SIZE-1]                      ;
  logic [NODE_INFO_WIDTH-1:0]   node_info_i     [0:NODE_INFO_SIZE-1]                  ;

  logic                         sched_ready_o                                         ;
  logic [COL_IDX_WIDTH-1:0]     row_col_idx_o   [0:NUM_OF_ROWS-1] [0:NUM_OF_COLS-1]   ;
  logic [VALUE_WIDTH-1:0]       row_value_o     [0:NUM_OF_ROWS-1] [0:NUM_OF_COLS-1]   ;
  logic [ROW_INFO_WIDTH-1:0]    row_info_o      [0:NUM_OF_ROWS-1]                     ;

  H_loader dut (
    .*
  );

  always #10 clk = ~clk;

  initial begin
    clk = 1'b1;
    rst_n = 1'b0;
    #11.01;
    rst_n = 1'b1;
  end

  initial begin
    sched_valid_i = 1'b0;
    #20.10;
    sched_valid_i = 1'b1;
    col_idx_i     = { 8'd0, 8'd4, 8'd2, 8'd4, 8'd1, 8'd3, 8'd2, 8'd4 };
    value_i       = { 8'd2, 8'd9, 8'd7, 8'd8, 8'd6, 8'd5, 8'd3, 8'd1 };
    node_info_i   = { {3'd0, 3'd2, 1'd0}, {3'd2, 3'd2, 1'd0}, {3'd4, 3'd2, 1'd0}, {3'd6, 3'd1, 1'd0}, {3'd7, 3'd1, 1'd0} };

    #20.01;
    sched_valid_i = 1'b0;
    #5000;
    $finish();
  end

endmodule
