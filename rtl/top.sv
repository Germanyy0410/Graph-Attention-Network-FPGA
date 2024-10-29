module top #(
  //* ========== parameter ===========
  parameter DATA_WIDTH        = 8                                     ,
  // -- H
  parameter H_NUM_OF_ROWS     = 2708                                  ,
  parameter H_NUM_OF_COLS     = 1433                                  ,
  // -- W
  parameter W_NUM_OF_ROWS     = 1433                                  ,
  parameter W_NUM_OF_COLS     = 16                                    ,
  // -- BRAM
  parameter COL_IDX_DEPTH     = 242101                                ,
  parameter VALUE_DEPTH       = 242101                                ,
  parameter NODE_INFO_DEPTH   = 13264                                 ,
  parameter WEIGHT_DEPTH      = 22928                                 ,
  parameter WH_DEPTH          = 242101                                ,
  parameter A_DEPTH           = 32                                    ,
  // -- NUM_OF_NODES
  parameter NUM_OF_NODES      = 168                                   ,

  //* ========= localparams ==========
  // -- col_idx
  parameter COL_IDX_WIDTH     = $clog2(H_NUM_OF_COLS)                 ,
  parameter COL_IDX_ADDR_W    = $clog2(COL_IDX_DEPTH)                 ,
  // -- value
  parameter VALUE_WIDTH       = DATA_WIDTH                            ,
  parameter VALUE_ADDR_W      = $clog2(VALUE_DEPTH)                   ,
  // -- node_info = [row_len, num_nodes, flag]
  parameter ROW_LEN_WIDTH     = $clog2(H_NUM_OF_COLS)                 ,
  parameter NUM_NODE_WIDTH    = $clog2(NUM_OF_NODES)                  ,
  parameter NODE_INFO_WIDTH   = ROW_LEN_WIDTH + 1 + NUM_NODE_WIDTH + 1,
  parameter NODE_INFO_ADDR_W  = $clog2(NODE_INFO_DEPTH)               ,
  // -- Weight
  parameter WEIGHT_ADDR_W     = $clog2(WEIGHT_DEPTH)                  ,
  // -- WH_BRAM
  parameter WH_WIDTH          = DATA_WIDTH * W_NUM_OF_COLS + NUM_NODE_WIDTH + 1   ,
  parameter WH_ADDR_W         = $clog2(WH_DEPTH)                      ,
  // -- a
  parameter A_ADDR_W          = $clog2(A_DEPTH)
)(
  input                             clk                         ,
  input                             rst_n                       ,

  input   [COL_IDX_WIDTH-1:0]       H_col_idx_BRAM_din          ,
  input                             H_col_idx_BRAM_ena          ,
  input   [COL_IDX_ADDR_W-1:0]      H_col_idx_BRAM_addra        ,
  output  [COL_IDX_ADDR_W-1:0]      H_col_idx_BRAM_addrb        ,
  input                             H_col_idx_BRAM_load_done    ,

  input   [VALUE_WIDTH-1:0]         H_value_BRAM_din            ,
  input                             H_value_BRAM_ena            ,
  input   [VALUE_ADDR_W-1:0]        H_value_BRAM_addra          ,
  output  [VALUE_ADDR_W-1:0]        H_value_BRAM_addrb          ,
  input                             H_value_BRAM_load_done      ,

  input   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_din        ,
  input                             H_node_info_BRAM_ena        ,
  input   [NODE_INFO_ADDR_W-1:0]    H_node_info_BRAM_addra      ,
  output  [NODE_INFO_ADDR_W-1:0]    H_node_info_BRAM_addrb      ,
  input                             H_node_info_BRAM_load_done  ,

  input   [DATA_WIDTH-1:0]          Weight_BRAM_din             ,
  input                             Weight_BRAM_ena             ,
  input   [WEIGHT_ADDR_W-1:0]       Weight_BRAM_addra           ,
  output  [WEIGHT_ADDR_W-1:0]       Weight_BRAM_addrb           ,
  input                             Weight_BRAM_load_done       ,

  output  [WH_WIDTH-1:0]            WH_BRAM_din                 ,
  output                            WH_BRAM_ena                 ,
  output  [WH_ADDR_W-1:0]           WH_BRAM_addra               ,
  output  [WH_ADDR_W-1:0]           WH_BRAM_addrb               ,

  input   [DATA_WIDTH-1:0]          a_BRAM_din                  ,
  input                             a_BRAM_ena                  ,
  input   [A_ADDR_W-1:0]            a_BRAM_addra                ,
  output  [A_ADDR_W-1:0]            a_BRAM_addrb                ,
  input                             a_BRAM_load_done
);
  wire    [VALUE_WIDTH-1:0]         H_value_BRAM_dout           ;
  wire    [COL_IDX_WIDTH-1:0]       H_col_idx_BRAM_dout         ;
  wire    [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout       ;
  wire    [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout_nxt   ;
  wire    [DATA_WIDTH-1:0]          Weight_BRAM_dout            ;
  wire    [WH_WIDTH-1:0]            WH_BRAM_doutb               ;
  wire    [WH_WIDTH-1:0]            WH_BRAM_doutc               ;
  wire    [DATA_WIDTH-1:0]          a_BRAM_dout                 ;

  BRAM #(
    .DATA_WIDTH   (COL_IDX_WIDTH        ),
    .DEPTH        (COL_IDX_DEPTH        ),
    .CLK_LATENCY  (1                    )
  ) u_H_col_idx_BRAM (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (H_col_idx_BRAM_din   ),
    .addra        (H_col_idx_BRAM_addra ),
    .ena          (H_col_idx_BRAM_ena   ),
    .addrb        (H_col_idx_BRAM_addrb ),
    .dout         (H_col_idx_BRAM_dout  )
  );

  BRAM #(
    .DATA_WIDTH   (VALUE_WIDTH          ),
    .DEPTH        (VALUE_DEPTH          ),
    .CLK_LATENCY  (1                    )
  ) u_H_value_BRAM (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (H_value_BRAM_din     ),
    .addra        (H_value_BRAM_addra   ),
    .ena          (H_value_BRAM_ena     ),
    .addrb        (H_value_BRAM_addrb   ),
    .dout         (H_value_BRAM_dout    )
  );

  modified_BRAM #(
    .DATA_WIDTH   (NODE_INFO_WIDTH          ),
    .DEPTH        (NODE_INFO_DEPTH          ),
    .CLK_LATENCY  (1                        )
  ) u_H_node_info_BRAM (
    .clk          (clk                      ),
    .rst_n        (rst_n                    ),
    .din          (H_node_info_BRAM_din     ),
    .addra        (H_node_info_BRAM_addra   ),
    .ena          (H_node_info_BRAM_ena     ),
    .addrb        (H_node_info_BRAM_addrb   ),
    .dout         (H_node_info_BRAM_dout    ),
    .dout_nxt     (H_node_info_BRAM_dout_nxt)
  );

  BRAM #(
    .DATA_WIDTH   (DATA_WIDTH           ),
    .DEPTH        (WEIGHT_DEPTH         ),
    .CLK_LATENCY  (1                    )
  ) u_Weight_BRAM (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (Weight_BRAM_din      ),
    .addra        (Weight_BRAM_addra    ),
    .ena          (Weight_BRAM_ena      ),
    .addrb        (Weight_BRAM_addrb    ),
    .dout         (Weight_BRAM_dout     )
  );

  dual_read_BRAM #(
    .DATA_WIDTH   (WH_WIDTH             ),
    .DEPTH        (WH_DEPTH             ),
    .CLK_LATENCY  (1                    )
  ) u_WH_BRAM (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (WH_BRAM_din          ),
    .addra        (WH_BRAM_addra        ),
    .ena          (WH_BRAM_ena          ),
    .addrb        (WH_BRAM_addrb        ),
    .doutb        (WH_BRAM_doutb        ),
    .addrc        (WH_BRAM_addrc        ),
    .doutc        (WH_BRAM_doutc        )
  );

  BRAM #(
    .DATA_WIDTH   (DATA_WIDTH           ),
    .DEPTH        (A_DEPTH              ),
    .CLK_LATENCY  (1                    )
  ) u_a_BRAM (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (a_BRAM_din           ),
    .addra        (a_BRAM_addra         ),
    .ena          (a_BRAM_ena           ),
    .addrb        (a_BRAM_addrb         ),
    .dout         (a_BRAM_dout          )
  );

  scheduler #(
    .DATA_WIDTH       (DATA_WIDTH       ),

    .H_NUM_OF_COLS    (H_NUM_OF_COLS    ),
    .H_NUM_OF_ROWS    (H_NUM_OF_ROWS    ),

    .W_NUM_OF_ROWS    (W_NUM_OF_ROWS    ),
    .W_NUM_OF_COLS    (W_NUM_OF_COLS    ),

    .COL_IDX_DEPTH    (COL_IDX_DEPTH    ),
    .VALUE_DEPTH      (VALUE_DEPTH      ),
    .NODE_INFO_DEPTH  (NODE_INFO_DEPTH  ),
    .WEIGHT_DEPTH     (WEIGHT_DEPTH     ),
    .WH_DEPTH         (WH_DEPTH         ),
    .A_DEPTH          (A_DEPTH          ),

    .NUM_OF_NODES     (NUM_OF_NODES     )
  ) u_scheduler (
    .clk                        (clk                        ),
    .rst_n                      (rst_n                      ),

    .H_col_idx_BRAM_dout        (H_col_idx_BRAM_dout        ),
    .H_col_idx_BRAM_addrb       (H_col_idx_BRAM_addrb       ),
    .H_col_idx_BRAM_load_done   (H_col_idx_BRAM_load_done   ),

    .H_value_BRAM_dout          (H_value_BRAM_dout          ),
    .H_value_BRAM_addrb         (H_value_BRAM_addrb         ),
    .H_value_BRAM_load_done     (H_value_BRAM_load_done     ),

    .H_node_info_BRAM_dout      (H_node_info_BRAM_dout      ),
    .H_node_info_BRAM_dout_nxt  (H_node_info_BRAM_dout_nxt  ),
    .H_node_info_BRAM_addrb     (H_node_info_BRAM_addrb     ),
    .H_node_info_BRAM_load_done (H_node_info_BRAM_load_done ),

    .Weight_BRAM_dout           (Weight_BRAM_dout           ),
    .Weight_BRAM_addrb          (Weight_BRAM_addrb          ),
    .Weight_BRAM_load_done      (Weight_BRAM_load_done      ),

    .a_BRAM_dout                (a_BRAM_dout                ),
    .a_BRAM_addrb               (a_BRAM_addrb               ),
    .a_BRAM_load_done           (a_BRAM_load_done           ),

    .WH_BRAM_din                (WH_BRAM_din                ),
    .WH_BRAM_ena                (WH_BRAM_ena                ),
    .WH_BRAM_wea                (WH_BRAM_wea                ),
    .WH_BRAM_addra              (WH_BRAM_addra              ),
    .WH_BRAM_doutb              (WH_BRAM_doutb              ),
    .WH_BRAM_doutc              (WH_BRAM_doutc              ),
    .WH_BRAM_addrb              (WH_BRAM_addrb              )
  );
endmodule