`timescale 1ns / 1ps

module SP_PE_tb #(
  parameter DATA_WIDTH          = 8,
  parameter DOT_PRODUCT_SIZE    = 5,

  //* ========= params declaration ==========
  localparam ARR_SIZE_WIDTH     = $clog2(DOT_PRODUCT_SIZE),
  localparam COL_IDX_WIDTH      = $clog2(DOT_PRODUCT_SIZE),
  localparam NODE_INFO_WIDTH    = $clog2(DOT_PRODUCT_SIZE) + 1,
  // -- max value
  localparam MAX_VALUE          = {DATA_WIDTH{1'b1}}
)();
  logic                         clk                                 ;
  logic                         rst_n                               ;
  // -- inputs
  logic                         pe_valid_i                          ;
  // -- -- H
  logic [COL_IDX_WIDTH-1:0]     col_idx_i   [0:DOT_PRODUCT_SIZE-1]  ;
  logic [DATA_WIDTH-1:0]        value_i     [0:DOT_PRODUCT_SIZE-1]  ;
  logic [NODE_INFO_WIDTH-1:0]   node_info_i                         ;
  // -- -- W
  logic [DATA_WIDTH-1:0]        weight_i    [0:DOT_PRODUCT_SIZE-1]  ;
  // -- outputs
  logic                         pe_ready_o                          ;
  logic [DATA_WIDTH-1:0]        result_o                            ;

  SP_PE dut (
    .*
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
    col_idx_i     = { 3'd0, 3'd3, 3'd4, 3'd0, 3'd0 };
    value_i       = { 8'd1, 8'd1, 8'd1, 8'd1, 8'd1 };
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