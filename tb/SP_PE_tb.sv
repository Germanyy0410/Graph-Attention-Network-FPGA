`timescale 1ns / 1ps

module SP_PE_tb #(
  parameter DATA_WIDTH          = 8,
  parameter DOT_PRODUCT_SIZE    = 5,

  //* ========= params declaration ==========
  localparam ARR_SIZE_WIDTH     = $clog2(DOT_PRODUCT_SIZE),
  localparam COL_IDX_WIDTH      = $clog2(DOT_PRODUCT_SIZE),
  localparam NODE_INFO_WIDTH    = $clog2(DOT_PRODUCT_SIZE) + 1,
  // -- flattened params
  localparam COL_IDX_WIDTH_FLAT = COL_IDX_WIDTH * DOT_PRODUCT_SIZE,
  localparam DATA_WIDTH_FLAT    = DATA_WIDTH * DOT_PRODUCT_SIZE,
  // -- max value
  localparam MAX_VALUE          = {DATA_WIDTH{1'b1}}
)();
  reg clk;
  reg rst_n;

  reg pe_valid_i;

  reg [COL_IDX_WIDTH_FLAT-1:0]    col_idx_i     ;
  reg [DATA_WIDTH_FLAT-1:0]       value_i       ;
  reg [NODE_INFO_WIDTH-1:0]       node_info_i   ;

  reg [DATA_WIDTH_FLAT-1:0]       weight_i      ;

  SP_PE dut (
    .clk(clk),
    .rst_n(rst_n),
    .pe_valid_i(pe_valid_i),
    .pe_ready_o(pe_ready_o),
    .col_idx_i(col_idx_i),
    .value_i(value_i),
    .node_info_i(node_info_i),
    .weight_i(weight_i),
    .result_o(result_o)
  );

  always #10 clk = ~clk;
  initial begin
    clk   = 1'b1;
    rst_n = 1'b0;
    #11.01;
    rst_n = 1'b1;
    #5000;
    $finish();
  end

  initial begin
    pe_valid_i    = 1'b0;
    #20.10;
    pe_valid_i    = 1'b1;
    node_info_i   = { 8'd3, 1'b1 };
    col_idx_i     = { 3'd0, 3'd3, 3'd4 } << 6;
    value_i       = { 8'd1, 8'd1, 8'd1 } << 16;
    weight_i      = { 8'd1, 8'd2, 8'd3, 8'd4, 8'd5 };
    #20.10;
    pe_valid_i    = 1'b0;
    #120.10;
    pe_valid_i    = 1'b1;
    node_info_i   = { 8'd5, 1'd1 };
    col_idx_i     = { 3'd0, 3'd1, 3'd2, 3'd3, 3'd4 };
    value_i       = { 8'd1, 8'd11, 8'd21, 8'd1, 8'd100 };
    weight_i      = { 8'd10, 8'd2, 8'd3, 8'd4, 8'd5 };
    #20.10;
    pe_valid_i    = 1'b0;
  end
endmodule