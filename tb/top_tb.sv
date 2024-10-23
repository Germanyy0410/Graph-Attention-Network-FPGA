`timescale 1ns / 1ps

module top_tb #(
  //* ========== parameter ===========
  parameter DATA_WIDTH        = 8                                     ,
  // -- H
  parameter H_NUM_OF_ROWS     = 5                                  ,
  parameter H_NUM_OF_COLS     = 5                                  ,
  // -- W
  parameter W_NUM_OF_ROWS     = 5                                  ,
  parameter W_NUM_OF_COLS     = 5                                    ,
  // -- BRAM
  parameter BRAM_ADDR_WIDTH   = 32                                    ,
  // -- NUM_OF_NODES
  parameter NUM_OF_NODES      = 5                                   ,
  // -- a
  parameter A_SIZE            = 10                                  ,
  //* ========= localparams ==========
  parameter H_INDEX_WIDTH     = $clog2(H_NUM_OF_ROWS)                 ,
  // -- inputs
  // -- -- col_idx
  parameter COL_IDX_WIDTH     = $clog2(H_NUM_OF_COLS)                 ,
  // -- -- value
  parameter VALUE_WIDTH       = DATA_WIDTH                            ,
  // -- -- node_info = [row_len, flag]
  parameter ROW_LEN_WIDTH     = $clog2(H_NUM_OF_COLS)                 ,
  parameter NUM_NODE_WIDTH    = $clog2(NUM_OF_NODES)                  ,
  parameter NODE_INFO_WIDTH   = ROW_LEN_WIDTH + NUM_NODE_WIDTH + 1    ,
  // -- -- WH_BRAM
  parameter WH_BRAM_WIDTH     = DATA_WIDTH * 16 + NUM_NODE_WIDTH + 1
) ();

  logic                             clk                     ;
  logic                             rst_n                   ;

  logic   [COL_IDX_WIDTH-1:0]       H_col_idx_BRAM_din      ;
  logic                             H_col_idx_BRAM_ena      ;
  logic                             H_col_idx_BRAM_wea      ;
  logic   [BRAM_ADDR_WIDTH-1:0]     H_col_idx_BRAM_addra    ;
  logic   [COL_IDX_WIDTH-1:0]       H_col_idx_BRAM_dout     ;
  logic                             H_col_idx_BRAM_enb      ;
  logic   [BRAM_ADDR_WIDTH-1:0]     H_col_idx_BRAM_addrb    ;
  logic                             H_col_idx_BRAM_load_done;

  logic   [VALUE_WIDTH-1:0]         H_value_BRAM_din        ;
  logic                             H_value_BRAM_ena        ;
  logic                             H_value_BRAM_wea        ;
  logic   [BRAM_ADDR_WIDTH-1:0]     H_value_BRAM_addra      ;
  logic   [VALUE_WIDTH-1:0]         H_value_BRAM_dout       ;
  logic                             H_value_BRAM_enb        ;
  logic   [BRAM_ADDR_WIDTH-1:0]     H_value_BRAM_addrb      ;
  logic                             H_value_BRAM_load_done  ;

  logic   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_din    ;
  logic                             H_node_info_BRAM_ena    ;
  logic                             H_node_info_BRAM_wea    ;
  logic   [BRAM_ADDR_WIDTH-1:0]     H_node_info_BRAM_addra  ;
  logic   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout   ;
  logic                             H_node_info_BRAM_enb    ;
  logic   [BRAM_ADDR_WIDTH-1:0]     H_node_info_BRAM_addrb  ;
  logic                             H_node_info_BRAM_load_done;

  logic   [DATA_WIDTH-1:0]          Weight_BRAM_din         ;
  logic                             Weight_BRAM_ena         ;
  logic                             Weight_BRAM_wea         ;
  logic   [BRAM_ADDR_WIDTH-1:0]     Weight_BRAM_addra       ;
  logic   [DATA_WIDTH-1:0]          Weight_BRAM_dout        ;
  logic                             Weight_BRAM_enb         ;
  logic   [BRAM_ADDR_WIDTH-1:0]     Weight_BRAM_addrb       ;
  logic                             Weight_BRAM_load_done   ;

  logic   [DATA_WIDTH-1:0]          a_BRAM_din              ;
  logic                             a_BRAM_ena              ;
  logic                             a_BRAM_wea              ;
  logic   [BRAM_ADDR_WIDTH-1:0]     a_BRAM_addra            ;
  logic   [DATA_WIDTH-1:0]          a_BRAM_dout             ;
  logic                             a_BRAM_enb              ;
  logic   [BRAM_ADDR_WIDTH-1:0]     a_BRAM_addrb            ;
  logic                             a_BRAM_load_done        ;

  logic   [DATA_WIDTH-1:0]          WH_BRAM_din             ;
  logic                             WH_BRAM_ena             ;
  logic                             WH_BRAM_wea             ;
  logic   [BRAM_ADDR_WIDTH-1:0]     WH_BRAM_addra           ;
  logic   [DATA_WIDTH-1:0]          WH_BRAM_dout            ;
  logic                             WH_BRAM_enb             ;
  logic   [BRAM_ADDR_WIDTH-1:0]     WH_BRAM_addrb           ;


  top #(
    .DATA_WIDTH       (DATA_WIDTH       ),
    .H_NUM_OF_ROWS    (H_NUM_OF_ROWS    ),
    .H_NUM_OF_COLS    (H_NUM_OF_COLS    ),
    .W_NUM_OF_ROWS    (W_NUM_OF_ROWS    ),
    .W_NUM_OF_COLS    (W_NUM_OF_COLS    ),
    .BRAM_ADDR_WIDTH  (BRAM_ADDR_WIDTH  ),
    .NUM_OF_NODES     (NUM_OF_NODES     ),
    .A_SIZE           (A_SIZE           )
  ) dut (.*);

  ////////////////////////////////////////////
  always #10 clk = ~clk;
  initial begin
    clk       = 1'b1;
    rst_n     = 1'b0;
    #31.01;
    rst_n     = 1'b1;
  end
  ////////////////////////////////////////////

  initial begin
    H_col_idx_BRAM_ena        = 1'b1;
    H_col_idx_BRAM_wea        = 1'b1;
    H_col_idx_BRAM_load_done  = 1'b0;
    H_value_BRAM_ena          = 1'b1;
    H_value_BRAM_wea          = 1'b1;
    H_value_BRAM_load_done    = 1'b0;

    H_col_idx_BRAM_din        = 0;
    H_col_idx_BRAM_addra      = 0;
    H_value_BRAM_din          = 2;
    H_value_BRAM_addra        = 0;

    #20.01;
    H_col_idx_BRAM_din        = 4;
    H_col_idx_BRAM_addra      = 1;
    H_value_BRAM_din          = 9;
    H_value_BRAM_addra        = 1;

    #20.01;
    H_col_idx_BRAM_din        = 2;
    H_col_idx_BRAM_addra      = 2;
    H_value_BRAM_din          = 7;
    H_value_BRAM_addra        = 2;

    #20.01;
    H_col_idx_BRAM_din        = 4;
    H_col_idx_BRAM_addra      = 3;
    H_value_BRAM_din          = 8;
    H_value_BRAM_addra        = 3;

    #20.01;
    H_col_idx_BRAM_din        = 1;
    H_col_idx_BRAM_addra      = 4;
    H_value_BRAM_din          = 6;
    H_value_BRAM_addra        = 4;

    #20.01;
    H_col_idx_BRAM_din        = 3;
    H_col_idx_BRAM_addra      = 5;
    H_value_BRAM_din          = 5;
    H_value_BRAM_addra        = 5;

    #20.01;
    H_col_idx_BRAM_din        = 2;
    H_col_idx_BRAM_addra      = 6;
    H_value_BRAM_din          = 3;
    H_value_BRAM_addra        = 6;

    #20.01;
    H_col_idx_BRAM_din        = 4;
    H_col_idx_BRAM_addra      = 7;
    H_value_BRAM_din          = 1;
    H_value_BRAM_addra        = 7;

    #20.01;
    H_col_idx_BRAM_ena        = 1'b0;
    H_col_idx_BRAM_wea        = 1'b0;
    H_col_idx_BRAM_load_done  = 1'b1;
    H_value_BRAM_ena          = 1'b0;
    H_value_BRAM_wea          = 1'b0;
    H_value_BRAM_load_done    = 1'b1;
  end

  initial begin
    H_node_info_BRAM_ena        = 1'b1;
    H_node_info_BRAM_wea        = 1'b1;
    H_node_info_BRAM_load_done  = 1'b0;

    H_node_info_BRAM_din    = {3'd2, 3'd5, 1'd1};
    H_node_info_BRAM_addra  = 0;

    #20.01;
    H_node_info_BRAM_din    = {3'd2, 3'd5, 1'd0};
    H_node_info_BRAM_addra  = 1;

    #20.01;
    H_node_info_BRAM_din    = {3'd2, 3'd5, 1'd0};
    H_node_info_BRAM_addra  = 2;

    #20.01;
    H_node_info_BRAM_din    = {3'd1, 3'd5, 1'd0};
    H_node_info_BRAM_addra  = 3;

    #20.01;
    H_node_info_BRAM_din    = {3'd1, 3'd5, 1'd0};
    H_node_info_BRAM_addra  = 4;

    #20.01;
    H_node_info_BRAM_ena        = 1'b0;
    H_node_info_BRAM_wea        = 1'b0;
    H_node_info_BRAM_load_done  = 1'b1;
  end

  initial begin
    Weight_BRAM_ena       = 1'b1;
    Weight_BRAM_wea       = 1'b1;
    Weight_BRAM_load_done = 1'b0;

    for (integer i = 0; i < 25; i = i + 1) begin
      Weight_BRAM_din   = i % 5 + 1;
      Weight_BRAM_addra = i;
      #20.01;
    end

    Weight_BRAM_ena       = 1'b0;
    Weight_BRAM_wea       = 1'b0;
    Weight_BRAM_load_done = 1'b1;
  end

  initial begin
    a_BRAM_ena        = 1'b1;
    a_BRAM_wea        = 1'b1;
    a_BRAM_load_done  = 1'b0;

    for (integer i = 0; i < 10; i = i + 1) begin
      if (i < 5) begin
        a_BRAM_din = 1;
      end else begin
        a_BRAM_din = 2;
      end
      // a_BRAM_din = i + 1;
      a_BRAM_addra = i;
      #20.01;
    end

    a_BRAM_ena        = 1'b0;
    a_BRAM_wea        = 1'b0;
    a_BRAM_load_done  = 1'b1;
  end
endmodule