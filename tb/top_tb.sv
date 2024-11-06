`timescale 1ns / 1ps

module top_tb #(
  //* ========== parameter ===========
  parameter DATA_WIDTH        = 8,
  // -- H
  parameter H_NUM_OF_ROWS			= 10,
  parameter H_NUM_OF_COLS			= 4,
  // -- W
  parameter W_NUM_OF_ROWS			= 4,
  parameter W_NUM_OF_COLS			= 4,
  // -- BRAM
  parameter COL_IDX_DEPTH     = 100,
  parameter VALUE_DEPTH       = 100,
  parameter NODE_INFO_DEPTH   = 30,
  parameter WEIGHT_DEPTH      = W_NUM_OF_COLS * W_NUM_OF_ROWS,
  parameter WH_DEPTH          = 100,
  parameter A_DEPTH			= 8,
  // -- NUM_OF_NODES
  parameter NUM_OF_NODES			= 5,

  //* ========= localparams ==========
  // -- col_idx
  parameter COL_IDX_WIDTH     = $clog2(H_NUM_OF_COLS)                 ,
  parameter COL_IDX_ADDR_W    = $clog2(COL_IDX_DEPTH)                 ,
  // -- value
  parameter VALUE_WIDTH       = DATA_WIDTH                            ,
  parameter VALUE_ADDR_W      = $clog2(VALUE_DEPTH)                   ,
  // -- node_info = [row_len, num_nodes, flag]
  parameter ROW_LEN_WIDTH     = $clog2(H_NUM_OF_COLS) + 1             ,
  parameter NUM_NODE_WIDTH    = $clog2(NUM_OF_NODES) + 1              ,
  parameter NODE_INFO_WIDTH   = ROW_LEN_WIDTH + NUM_NODE_WIDTH + 1    ,
  parameter NODE_INFO_ADDR_W  = $clog2(NODE_INFO_DEPTH)               ,
  // -- Weight
  parameter WEIGHT_ADDR_W     = $clog2(WEIGHT_DEPTH)                  ,
  // -- WH_BRAM
  parameter WH_WIDTH          = DATA_WIDTH * 5 + NUM_NODE_WIDTH + 1  ,
  parameter WH_ADDR_W         = $clog2(WH_DEPTH)                      ,
  // -- a
  parameter A_ADDR_W          = $clog2(A_DEPTH)
) ();

  logic                             clk                         ;
  logic                             rst_n                       ;

  logic   [COL_IDX_WIDTH-1:0]       H_col_idx_BRAM_din          ;
  logic                             H_col_idx_BRAM_ena          ;
  logic   [COL_IDX_ADDR_W-1:0]      H_col_idx_BRAM_addra        ;
  logic                             H_col_idx_BRAM_enb          ;
  logic   [COL_IDX_ADDR_W-1:0]      H_col_idx_BRAM_addrb        ;
  logic                             H_col_idx_BRAM_load_done    ;

  logic   [VALUE_WIDTH-1:0]         H_value_BRAM_din            ;
  logic                             H_value_BRAM_ena            ;
  logic   [VALUE_ADDR_W-1:0]        H_value_BRAM_addra          ;
  logic                             H_value_BRAM_enb            ;
  logic   [VALUE_ADDR_W-1:0]        H_value_BRAM_addrb          ;
  logic                             H_value_BRAM_load_done      ;

  logic   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_din        ;
  logic                             H_node_info_BRAM_ena        ;
  logic   [NODE_INFO_ADDR_W-1:0]    H_node_info_BRAM_addra      ;
  logic                             H_node_info_BRAM_enb        ;
  logic   [NODE_INFO_ADDR_W-1:0]    H_node_info_BRAM_addrb      ;
  logic                             H_node_info_BRAM_load_done  ;

  logic   [DATA_WIDTH-1:0]          Weight_BRAM_din             ;
  logic                             Weight_BRAM_ena             ;
  logic   [WEIGHT_ADDR_W-1:0]       Weight_BRAM_addra           ;
  logic                             Weight_BRAM_enb             ;
  logic   [WEIGHT_ADDR_W-1:0]       Weight_BRAM_addrb           ;
  logic                             Weight_BRAM_load_done       ;

  logic   [WH_WIDTH-1:0]            WH_BRAM_din                 ;
  logic                             WH_BRAM_ena                 ;
  logic   [WH_ADDR_W-1:0]           WH_BRAM_addra               ;
  logic                             WH_BRAM_enb                 ;
  logic   [WH_ADDR_W-1:0]           WH_BRAM_addrb               ;

  logic   [DATA_WIDTH-1:0]          a_BRAM_din                  ;
  logic                             a_BRAM_ena                  ;
  logic   [A_ADDR_W-1:0]            a_BRAM_addra                ;
  logic                             a_BRAM_enb                  ;
  logic   [A_ADDR_W-1:0]            a_BRAM_addrb                ;
  logic                             a_BRAM_load_done            ;

  top #(
    .DATA_WIDTH       (DATA_WIDTH       ),
    .H_NUM_OF_ROWS    (H_NUM_OF_ROWS    ),
    .H_NUM_OF_COLS    (H_NUM_OF_COLS    ),
    .W_NUM_OF_ROWS    (W_NUM_OF_ROWS    ),
    .W_NUM_OF_COLS    (W_NUM_OF_COLS    ),
    .COL_IDX_DEPTH    (COL_IDX_DEPTH    ),
    .VALUE_DEPTH      (VALUE_DEPTH      ),
    .NODE_INFO_DEPTH  (NODE_INFO_DEPTH  ),
    .WEIGHT_DEPTH     (WEIGHT_DEPTH     ),
    .WH_DEPTH         (WH_DEPTH         ),
    .A_DEPTH          (A_DEPTH          ),
    .NUM_OF_NODES     (NUM_OF_NODES     )
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

  // ---------------- Input ----------------
	initial begin
		H_col_idx_BRAM_ena = 1'b1;
		H_col_idx_BRAM_load_done = 1'b0;
		H_value_BRAM_ena = 1'b1;
		H_value_BRAM_load_done = 1'b0;

		H_col_idx_BRAM_din = 3;
		H_value_BRAM_din = 1;
		H_col_idx_BRAM_addra = 0;
		H_value_BRAM_addra = 0;

		#20.01;
		H_col_idx_BRAM_din = 1;
		H_value_BRAM_din = 2;
		H_col_idx_BRAM_addra = 1;
		H_value_BRAM_addra = 1;

		#20.01;
		H_col_idx_BRAM_din = 2;
		H_value_BRAM_din = 1;
		H_col_idx_BRAM_addra = 2;
		H_value_BRAM_addra = 2;

		#20.01;
		H_col_idx_BRAM_din = 1;
		H_value_BRAM_din = 5;
		H_col_idx_BRAM_addra = 3;
		H_value_BRAM_addra = 3;

		#20.01;
		H_col_idx_BRAM_din = 2;
		H_value_BRAM_din = 3;
		H_col_idx_BRAM_addra = 4;
		H_value_BRAM_addra = 4;

		#20.01;
		H_col_idx_BRAM_din = 0;
		H_value_BRAM_din = 2;
		H_col_idx_BRAM_addra = 5;
		H_value_BRAM_addra = 5;

		#20.01;
		H_col_idx_BRAM_din = 2;
		H_value_BRAM_din = 1;
		H_col_idx_BRAM_addra = 6;
		H_value_BRAM_addra = 6;

		#20.01;
		H_col_idx_BRAM_din = 3;
		H_value_BRAM_din = 2;
		H_col_idx_BRAM_addra = 7;
		H_value_BRAM_addra = 7;

		#20.01;
		H_col_idx_BRAM_din = 0;
		H_value_BRAM_din = 3;
		H_col_idx_BRAM_addra = 8;
		H_value_BRAM_addra = 8;

		#20.01;
		H_col_idx_BRAM_din = 0;
		H_value_BRAM_din = 5;
		H_col_idx_BRAM_addra = 9;
		H_value_BRAM_addra = 9;

		#20.01;
		H_col_idx_BRAM_din = 1;
		H_value_BRAM_din = 4;
		H_col_idx_BRAM_addra = 10;
		H_value_BRAM_addra = 10;

		#20.01;
		H_col_idx_BRAM_din = 2;
		H_value_BRAM_din = 5;
		H_col_idx_BRAM_addra = 11;
		H_value_BRAM_addra = 11;

		#20.01;
		H_col_idx_BRAM_din = 0;
		H_value_BRAM_din = 1;
		H_col_idx_BRAM_addra = 12;
		H_value_BRAM_addra = 12;

		#20.01;
		H_col_idx_BRAM_din = 1;
		H_value_BRAM_din = 3;
		H_col_idx_BRAM_addra = 13;
		H_value_BRAM_addra = 13;

		#20.01;
		H_col_idx_BRAM_din = 2;
		H_value_BRAM_din = 2;
		H_col_idx_BRAM_addra = 14;
		H_value_BRAM_addra = 14;

		#20.01;
		H_col_idx_BRAM_din = 3;
		H_value_BRAM_din = 3;
		H_col_idx_BRAM_addra = 15;
		H_value_BRAM_addra = 15;

		#20.01;
		H_col_idx_BRAM_din = 0;
		H_value_BRAM_din = 1;
		H_col_idx_BRAM_addra = 16;
		H_value_BRAM_addra = 16;

		#20.01;
		H_col_idx_BRAM_din = 1;
		H_value_BRAM_din = 2;
		H_col_idx_BRAM_addra = 17;
		H_value_BRAM_addra = 17;

		#20.01;
		H_col_idx_BRAM_din = 2;
		H_value_BRAM_din = 2;
		H_col_idx_BRAM_addra = 18;
		H_value_BRAM_addra = 18;

		#20.01;
		H_col_idx_BRAM_din = 1;
		H_value_BRAM_din = 4;
		H_col_idx_BRAM_addra = 19;
		H_value_BRAM_addra = 19;

		#20.01;
		H_col_idx_BRAM_ena = 1'b0;
		H_col_idx_BRAM_load_done = 1'b1;
		H_value_BRAM_ena = 1'b0;
		H_value_BRAM_load_done = 1'b1;
	end

	initial begin
		H_node_info_BRAM_ena = 1'b1;
		H_node_info_BRAM_load_done = 1'b0;

		H_node_info_BRAM_din = 7'b0011011;
		H_node_info_BRAM_addra = 0;

		#20.01;
		H_node_info_BRAM_din = 7'b0101010;
		H_node_info_BRAM_addra = 1;

		#20.01;
		H_node_info_BRAM_din = 7'b0101010;
		H_node_info_BRAM_addra = 2;

		#20.01;
		H_node_info_BRAM_din = 7'b0111010;
		H_node_info_BRAM_addra = 3;

		#20.01;
		H_node_info_BRAM_din = 7'b0011010;
		H_node_info_BRAM_addra = 4;

		#20.01;
		H_node_info_BRAM_din = 7'b0011011;
		H_node_info_BRAM_addra = 5;

		#20.01;
		H_node_info_BRAM_din = 7'b0101010;
		H_node_info_BRAM_addra = 6;

		#20.01;
		H_node_info_BRAM_din = 7'b1001010;
		H_node_info_BRAM_addra = 7;

		#20.01;
		H_node_info_BRAM_din = 7'b0111010;
		H_node_info_BRAM_addra = 8;

		#20.01;
		H_node_info_BRAM_din = 7'b0011010;
		H_node_info_BRAM_addra = 9;

		#20.01;
		H_node_info_BRAM_ena = 1'b0;
		H_node_info_BRAM_load_done = 1'b1;
	end

	initial begin
		Weight_BRAM_ena = 1'b1;
		Weight_BRAM_load_done = 1'b0;

		Weight_BRAM_din = 3;
		Weight_BRAM_addra = 0;

		#20.01;
		Weight_BRAM_din = 2;
		Weight_BRAM_addra = 1;

		#20.01;
		Weight_BRAM_din = 2;
		Weight_BRAM_addra = 2;

		#20.01;
		Weight_BRAM_din = 5;
		Weight_BRAM_addra = 3;

		#20.01;
		Weight_BRAM_din = 4;
		Weight_BRAM_addra = 4;

		#20.01;
		Weight_BRAM_din = 1;
		Weight_BRAM_addra = 5;

		#20.01;
		Weight_BRAM_din = 5;
		Weight_BRAM_addra = 6;

		#20.01;
		Weight_BRAM_din = 4;
		Weight_BRAM_addra = 7;

		#20.01;
		Weight_BRAM_din = 3;
		Weight_BRAM_addra = 8;

		#20.01;
		Weight_BRAM_din = 3;
		Weight_BRAM_addra = 9;

		#20.01;
		Weight_BRAM_din = 5;
		Weight_BRAM_addra = 10;

		#20.01;
		Weight_BRAM_din = 5;
		Weight_BRAM_addra = 11;

		#20.01;
		Weight_BRAM_din = 2;
		Weight_BRAM_addra = 12;

		#20.01;
		Weight_BRAM_din = 5;
		Weight_BRAM_addra = 13;

		#20.01;
		Weight_BRAM_din = 3;
		Weight_BRAM_addra = 14;

		#20.01;
		Weight_BRAM_din = 4;
		Weight_BRAM_addra = 15;

		#20.01;
		Weight_BRAM_ena = 1'b0;
		Weight_BRAM_load_done = 1'b1;
	end
	initial begin
		a_BRAM_ena = 1'b1;
		a_BRAM_load_done = 1'b0;

		a_BRAM_din = 1;
		a_BRAM_addra = 0;

		#20.01;
		a_BRAM_din = 1;
		a_BRAM_addra = 1;

		#20.01;
		a_BRAM_din = 1;
		a_BRAM_addra = 2;

		#20.01;
		a_BRAM_din = 1;
		a_BRAM_addra = 3;

		#20.01;
		a_BRAM_din = 2;
		a_BRAM_addra = 4;

		#20.01;
		a_BRAM_din = 2;
		a_BRAM_addra = 5;

		#20.01;
		a_BRAM_din = 2;
		a_BRAM_addra = 6;

		#20.01;
		a_BRAM_din = 2;
		a_BRAM_addra = 7;

		#20.01;
		a_BRAM_ena = 1'b0;
		a_BRAM_load_done = 1'b1;
	end
	// ---------------------------------------
endmodule


