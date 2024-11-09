module scheduler #(
  //* ========== parameter ===========
  parameter DATA_WIDTH          = 8                                                 ,
  // -- H
  parameter H_NUM_OF_ROWS       = 13264                                             ,
  parameter H_NUM_OF_COLS       = 1433                                              ,
  // -- W
  parameter W_NUM_OF_ROWS       = 1433                                              ,
  parameter W_NUM_OF_COLS       = 16                                                ,
  // -- BRAM
  parameter COL_IDX_DEPTH       = 242101                                            ,
  parameter VALUE_DEPTH         = 242101                                            ,
  parameter NODE_INFO_DEPTH     = 13264                                             ,
  parameter WEIGHT_DEPTH        = 1433 * 16                                         ,
  parameter WH_DEPTH            = 242101                                            ,
  parameter A_DEPTH             = 2 * 16                                            ,
  // -- NUM_OF_NODES
  parameter NUM_OF_NODES        = 168                                               ,

  //* ========= localparams ==========
  // -- col_idx
  parameter COL_IDX_WIDTH       = $clog2(H_NUM_OF_COLS)                             ,
  parameter COL_IDX_ADDR_W      = $clog2(COL_IDX_DEPTH)                             ,
  // -- value
  parameter VALUE_WIDTH         = DATA_WIDTH                                        ,
  parameter VALUE_ADDR_W        = $clog2(VALUE_DEPTH)                               ,
  // -- node_info = [row_len, num_nodes, flag]
  parameter ROW_LEN_WIDTH       = $clog2(H_NUM_OF_COLS)                             ,
  parameter NUM_NODE_WIDTH      = $clog2(NUM_OF_NODES)                              ,
  parameter NODE_INFO_WIDTH     = ROW_LEN_WIDTH + NUM_NODE_WIDTH + 1                ,
  parameter NODE_INFO_ADDR_W    = $clog2(NODE_INFO_DEPTH)                           ,
  // -- Weight
  parameter WEIGHT_ADDR_W       = $clog2(WEIGHT_DEPTH)                              ,
  parameter MULT_WEIGHT_ADDR_W  = $clog2(W_NUM_OF_ROWS)                             ,
  // -- WH_BRAM
  parameter WH_WIDTH            = DATA_WIDTH * W_NUM_OF_COLS + NUM_NODE_WIDTH + 1   ,
  parameter WH_ADDR_W           = $clog2(WH_DEPTH)                                  ,
  // -- a
  parameter A_ADDR_W            = $clog2(A_DEPTH)                                   ,
  // -- softmax
  parameter SOFTMAX_WIDTH       = NUM_OF_NODES * DATA_WIDTH + NUM_NODE_WIDTH        ,
  parameter SOFTMAX_DEPTH       = NODE_INFO_DEPTH                                   ,
  parameter SOFTMAX_ADDR_W      = $clog2(SOFTMAX_DEPTH)                             ,

  parameter NUM_NODES_W         = $clog2(NUM_OF_NODES)
)(
  input clk,
  input rst_n,

  // -- H_col_idx BRAM
  input   [COL_IDX_WIDTH-1:0]       H_col_idx_BRAM_dout         ,
  output  [COL_IDX_ADDR_W-1:0]      H_col_idx_BRAM_addrb        ,
  input                             H_col_idx_BRAM_load_done    ,
  // -- H_value BRAM
  input   [VALUE_WIDTH-1:0]         H_value_BRAM_dout           ,
  output  [VALUE_ADDR_W-1:0]        H_value_BRAM_addrb          ,
  input                             H_value_BRAM_load_done      ,
  // -- H_node_info BRAM
  input   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout       ,
  input   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout_nxt   ,
  output  [NODE_INFO_ADDR_W-1:0]    H_node_info_BRAM_addrb      ,
  input                             H_node_info_BRAM_load_done  ,
  // -- Weight BRAM
  input   [DATA_WIDTH-1:0]          Weight_BRAM_dout            ,
  output  [WEIGHT_ADDR_W-1:0]       Weight_BRAM_addrb           ,
  input                             Weight_BRAM_load_done       ,
  // -- a BRAM
  input   [DATA_WIDTH-1:0]          a_BRAM_dout                 ,
  output  [A_ADDR_W-1:0]            a_BRAM_addrb                ,
  input                             a_BRAM_load_done            ,
  // -- WH BRAM
  output  [WH_WIDTH-1:0]            WH_BRAM_din                 ,
  output                            WH_BRAM_ena                 ,
  output                            WH_BRAM_wea                 ,
  output  [WH_ADDR_W-1:0]           WH_BRAM_addra               ,
  input   [WH_WIDTH-1:0]            WH_BRAM_doutb               ,
  input   [WH_WIDTH-1:0]            WH_BRAM_doutc               ,
  output  [WH_ADDR_W-1:0]           WH_BRAM_addrb
);
  //* ======== internal declaration =========
  logic [NUM_NODES_W-1:0]         num_of_nodes                                ;
  logic                           h_ready                                     ;

  // -- W_loader
  logic [MULT_WEIGHT_ADDR_W-1:0]  mult_weight_addrb   [0:W_NUM_OF_COLS-1]     ;
  logic [DATA_WIDTH-1:0]          mult_weight_dout    [0:W_NUM_OF_COLS-1]     ;
  logic                           w_ready                                     ;

  // -- a_loader
  logic [DATA_WIDTH-1:0]          a                   [0:A_DEPTH-1]           ;
  logic                           a_ready                                     ;

  // -- SPMM
  logic                           spmm_valid                                  ;
  logic [W_NUM_OF_COLS-1:0]       pe_ready                                    ;

  // -- DMVM
  logic                           dmvm_valid                                  ;
  logic                           dmvm_valid_reg                              ;
  logic                           dmvm_ready                                  ;
  logic                           sm_BRAM_ena                                 ;
  logic [SOFTMAX_ADDR_W-1:0]      sm_BRAM_addra                               ;
  logic [SOFTMAX_WIDTH-1:0]       sm_BRAM_dout                                ;
  logic [SOFTMAX_ADDR_W-1:0]      sm_BRAM_addrb                               ;
  // -- softmax
  logic [DATA_WIDTH-1:0]          coef                [0:NUM_OF_NODES-1]      ;
  logic [SOFTMAX_WIDTH-1:0]       coef_data_i                                 ;
  logic [SOFTMAX_WIDTH-1:0]       coef_data_o                                 ;
  logic                           coef_wr_valid                               ;
  logic                           coef_rd_valid                               ;
  logic                           coef_empty                                  ;
  logic                           coef_full                                   ;
  //* =======================================

  genvar i;

  W_loader #(
    .DATA_WIDTH       (DATA_WIDTH       ),
    .W_NUM_OF_COLS    (W_NUM_OF_COLS    ),
    .W_NUM_OF_ROWS    (W_NUM_OF_ROWS    )
  ) u_W_loader (
    .clk                      (clk                    ),
    .rst_n                    (rst_n                  ),

    .w_valid_i                (Weight_BRAM_load_done  ),
    .w_ready_o                (w_ready                ),

    .Weight_BRAM_dout         (Weight_BRAM_dout       ),
    .Weight_BRAM_enb          (Weight_BRAM_enb        ),
    .Weight_BRAM_addrb        (Weight_BRAM_addrb      ),

    .mult_weight_addrb        (mult_weight_addrb      ),
    .mult_weight_dout         (mult_weight_dout       )
  );

  a_loader #(
    .DATA_WIDTH       (DATA_WIDTH       ),
    .A_ADDR_W         (A_ADDR_W         ),
    .A_DEPTH          (A_DEPTH          )
  ) u_a_loader (
    .clk              (clk                    ),
    .rst_n            (rst_n                  ),

    .a_valid_i        (a_BRAM_load_done       ),
    .a_ready_o        (a_ready                ),

    .a_BRAM_dout      (a_BRAM_dout            ),
    .a_BRAM_enb       (a_BRAM_enb             ),
    .a_BRAM_addrb     (a_BRAM_addrb           ),

    .a_o              (a                      )
  );

  assign spmm_valid = (H_col_idx_BRAM_load_done && H_value_BRAM_load_done && H_node_info_BRAM_load_done && Weight_BRAM_load_done && w_ready);
  (* dont_touch = "yes" *)
  SPMM #(
    .DATA_WIDTH       (DATA_WIDTH       ),
    .DOT_PRODUCT_SIZE (H_NUM_OF_COLS    ),

    .H_NUM_OF_COLS    (H_NUM_OF_COLS    ),
    .H_NUM_OF_ROWS    (H_NUM_OF_ROWS    ),

    .W_NUM_OF_ROWS    (W_NUM_OF_ROWS    ),
    .W_NUM_OF_COLS    (W_NUM_OF_COLS    ),

    .COL_IDX_DEPTH    (COL_IDX_DEPTH    ),
    .VALUE_DEPTH      (VALUE_DEPTH      ),
    .NODE_INFO_DEPTH  (NODE_INFO_DEPTH  ),
    .WEIGHT_DEPTH     (WEIGHT_DEPTH     ),
    .WH_DEPTH         (WH_DEPTH         ),

    .NUM_OF_NODES     (NUM_OF_NODES     )
  ) u_SPMM (
    .clk                        (clk                        ),
    .rst_n                      (rst_n                      ),

    .H_col_idx_BRAM_dout        (H_col_idx_BRAM_dout        ),
    .H_col_idx_BRAM_addrb       (H_col_idx_BRAM_addrb       ),

    .H_value_BRAM_dout          (H_value_BRAM_dout          ),
    .H_value_BRAM_addrb         (H_value_BRAM_addrb         ),

    .H_node_info_BRAM_dout      (H_node_info_BRAM_dout      ),
    .H_node_info_BRAM_dout_nxt  (H_node_info_BRAM_dout_nxt  ),
    .H_node_info_BRAM_addrb     (H_node_info_BRAM_addrb     ),

    .mult_weight_addrb          (mult_weight_addrb          ),
    .mult_weight_dout           (mult_weight_dout           ),

    .spmm_valid_i               (spmm_valid                 ),
    .pe_ready_o                 (pe_ready                   ),

    .WH_BRAM_din                (WH_BRAM_din                ),
    .WH_BRAM_ena                (WH_BRAM_ena                ),
    .WH_BRAM_wea                (WH_BRAM_wea                ),
    .WH_BRAM_addra              (WH_BRAM_addra              )
  );

  assign dmvm_valid = (&pe_ready) ? 1'b1 : dmvm_valid_reg;
  always @(posedge clk) begin
    if (!rst_n) begin
      dmvm_valid_reg <= 1'b0;
    end else begin
      dmvm_valid_reg <= dmvm_valid;
    end
  end

  DMVM #(
    .A_DEPTH          (A_DEPTH          ),
    .DATA_WIDTH       (DATA_WIDTH       ),
    .WH_ADDR_W        (WH_ADDR_W        ),
    .NUM_OF_NODES     (NUM_OF_NODES     ),
    .W_NUM_OF_COLS    (W_NUM_OF_COLS    )
  ) u_DMVM (
    .clk              (clk              ),
    .rst_n            (rst_n            ),

    .dmvm_valid_i     (dmvm_valid_reg   ),
    .dmvm_ready_o     (dmvm_ready       ),

    .a_valid_i        (a_BRAM_load_done ),
    .a_i              (a                ),

    .WH_BRAM_doutb    (WH_BRAM_doutb    ),
    .WH_BRAM_addrb    (WH_BRAM_addrb    ),

    .coef_o           (coef             ),
    .num_of_nodes     (num_of_nodes     )
  );

  assign coef_data_i    = 0;
  assign coef_wr_valid  = dmvm_ready;

  fifo #(
    .DATA_WIDTH (SOFTMAX_WIDTH  ),
    .FIFO_DEPTH (100            )
  ) u_softmax_FIFO (
    .clk        (clk                    ),
    .rst_n      (rst_n                  ),

    .data_i     (coef_data_i            ),
    .data_o     (coef_data_o            ),

    .wr_valid_i (coef_wr_valid          ),
    .rd_valid_i (coef_rd_valid          ),

    .empty_o    (coef_empty             ),
    .full_o     (coef_full              )
  );
endmodule


