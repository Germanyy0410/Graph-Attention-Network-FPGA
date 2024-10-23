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
  parameter BRAM_ADDR_WIDTH   = 32                                    ,
  // -- NUM_OF_NODES
  parameter NUM_OF_NODES      = 168                                   ,
  // -- a
  parameter A_SIZE            = 32                                    ,
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
)(
  input                             clk                         ,
  input                             rst_n                       ,

  input   [COL_IDX_WIDTH-1:0]       H_col_idx_BRAM_din          ,
  input                             H_col_idx_BRAM_ena          ,
  input                             H_col_idx_BRAM_wea          ,
  input   [BRAM_ADDR_WIDTH-1:0]     H_col_idx_BRAM_addra        ,
  output                            H_col_idx_BRAM_enb          ,
  output  [BRAM_ADDR_WIDTH-1:0]     H_col_idx_BRAM_addrb        ,
  input                             H_col_idx_BRAM_load_done    ,

  input   [VALUE_WIDTH-1:0]         H_value_BRAM_din            ,
  input                             H_value_BRAM_ena            ,
  input                             H_value_BRAM_wea            ,
  input   [BRAM_ADDR_WIDTH-1:0]     H_value_BRAM_addra          ,
  output                            H_value_BRAM_enb            ,
  output  [BRAM_ADDR_WIDTH-1:0]     H_value_BRAM_addrb          ,
  input                             H_value_BRAM_load_done      ,

  input   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_din        ,
  input                             H_node_info_BRAM_ena        ,
  input                             H_node_info_BRAM_wea        ,
  input   [BRAM_ADDR_WIDTH-1:0]     H_node_info_BRAM_addra      ,
  output                            H_node_info_BRAM_enb        ,
  output  [BRAM_ADDR_WIDTH-1:0]     H_node_info_BRAM_addrb      ,
  input                             H_node_info_BRAM_load_done  ,

  input   [DATA_WIDTH-1:0]          Weight_BRAM_din             ,
  input                             Weight_BRAM_ena             ,
  input                             Weight_BRAM_wea             ,
  input   [BRAM_ADDR_WIDTH-1:0]     Weight_BRAM_addra           ,
  output                            Weight_BRAM_enb             ,
  output  [BRAM_ADDR_WIDTH-1:0]     Weight_BRAM_addrb           ,
  input                             Weight_BRAM_load_done       ,

  output  [WH_BRAM_WIDTH-1:0]       WH_BRAM_din                 ,
  output                            WH_BRAM_ena                 ,
  output                            WH_BRAM_wea                 ,
  output  [BRAM_ADDR_WIDTH-1:0]     WH_BRAM_addra               ,
  output                            WH_BRAM_enb                 ,
  output  [BRAM_ADDR_WIDTH-1:0]     WH_BRAM_addrb               ,

  input   [DATA_WIDTH-1:0]          a_BRAM_din                  ,
  input                             a_BRAM_ena                  ,
  input                             a_BRAM_wea                  ,
  input   [BRAM_ADDR_WIDTH-1:0]     a_BRAM_addra                ,
  output                            a_BRAM_enb                  ,
  output  [BRAM_ADDR_WIDTH-1:0]     a_BRAM_addrb                ,
  input                             a_BRAM_load_done
);
  wire    [VALUE_WIDTH-1:0]         H_value_BRAM_dout           ;
  wire    [COL_IDX_WIDTH-1:0]       H_col_idx_BRAM_dout         ;
  wire    [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout       ;
  wire    [DATA_WIDTH-1:0]          Weight_BRAM_dout            ;
  wire    [WH_BRAM_WIDTH-1:0]       WH_BRAM_dout                ;
  wire    [DATA_WIDTH-1:0]          a_BRAM_dout                 ;

  H_col_idx_BRAM_wrapper u_H_col_idx_BRAM (
    .clka  (clk                   ),
    .dina  (H_col_idx_BRAM_din    ),
    .ena   (H_col_idx_BRAM_ena    ),
    .wea   (H_col_idx_BRAM_wea    ),
    .addra (H_col_idx_BRAM_addra  ),
    .clkb  (clk                   ),
    .doutb (H_col_idx_BRAM_dout   ),
    .addrb (H_col_idx_BRAM_addrb  ),
    .enb   (H_col_idx_BRAM_enb    )
  );

  H_value_BRAM_wrapper u_H_value_BRAM (
    .clka  (clk                 ),
    .dina  (H_value_BRAM_din    ),
    .ena   (H_value_BRAM_ena    ),
    .wea   (H_value_BRAM_wea    ),
    .addra (H_value_BRAM_addra  ),
    .clkb  (clk                 ),
    .doutb (H_value_BRAM_dout   ),
    .addrb (H_value_BRAM_addrb  ),
    .enb   (H_value_BRAM_enb    )
  );

  H_node_info_BRAM_wrapper u_H_node_info_BRAM (
    .clka  (clk                     ),
    .dina  (H_node_info_BRAM_din    ),
    .ena   (H_node_info_BRAM_ena    ),
    .wea   (H_node_info_BRAM_wea    ),
    .addra (H_node_info_BRAM_addra  ),
    .clkb  (clk                     ),
    .doutb (H_node_info_BRAM_dout   ),
    .addrb (H_node_info_BRAM_addrb  ),
    .enb   (H_node_info_BRAM_enb    )
  );

  Weight_BRAM_wrapper u_Weight_BRAM (
    .clka  (clk                 ),
    .dina  (Weight_BRAM_din     ),
    .ena   (Weight_BRAM_ena     ),
    .wea   (Weight_BRAM_wea     ),
    .addra (Weight_BRAM_addra   ),
    .clkb  (clk                 ),
    .doutb (Weight_BRAM_dout    ),
    .addrb (Weight_BRAM_addrb   ),
    .enb   (Weight_BRAM_enb     )
  );

  WH_BRAM_wrapper u_WH_BRAM (
    .clka  (clk           ),
    .dina  (WH_BRAM_din   ),
    .ena   (WH_BRAM_ena   ),
    .wea   (WH_BRAM_wea   ),
    .addra (WH_BRAM_addra ),
    .clkb  (clk           ),
    .doutb (WH_BRAM_dout  ),
    .enb   (WH_BRAM_enb   ),
    .addrb (WH_BRAM_addrb )
  );

  a_BRAM_wrapper u_a_BRAM (
    .clka  (clk           ),
    .dina  (a_BRAM_din    ),
    .ena   (a_BRAM_ena    ),
    .wea   (a_BRAM_wea    ),
    .addra (a_BRAM_addra  ),
    .clkb  (clk           ),
    .doutb (a_BRAM_dout   ),
    .addrb (a_BRAM_addrb  ),
    .enb   (a_BRAM_enb    )
  );

  scheduler #(
    .DATA_WIDTH       (DATA_WIDTH       ),

    .H_NUM_OF_COLS    (H_NUM_OF_COLS    ),
    .H_NUM_OF_ROWS    (H_NUM_OF_ROWS    ),

    .W_NUM_OF_ROWS    (W_NUM_OF_ROWS    ),
    .W_NUM_OF_COLS    (W_NUM_OF_COLS    ),

    .BRAM_ADDR_WIDTH  (BRAM_ADDR_WIDTH  ),
    .NUM_OF_NODES     (NUM_OF_NODES     ),

    .WH_BRAM_WIDTH    (WH_BRAM_WIDTH    ),
    .A_SIZE           (A_SIZE           )
  ) u_scheduler (
    .clk                        (clk                        ),
    .rst_n                      (rst_n                      ),

    .H_col_idx_BRAM_dout        (H_col_idx_BRAM_dout        ),
    .H_col_idx_BRAM_enb         (H_col_idx_BRAM_enb         ),
    .H_col_idx_BRAM_addrb       (H_col_idx_BRAM_addrb       ),
    .H_col_idx_BRAM_load_done   (H_col_idx_BRAM_load_done   ),

    .H_value_BRAM_dout          (H_value_BRAM_dout          ),
    .H_value_BRAM_enb           (H_value_BRAM_enb           ),
    .H_value_BRAM_addrb         (H_value_BRAM_addrb         ),
    .H_value_BRAM_load_done     (H_value_BRAM_load_done     ),

    .H_node_info_BRAM_dout      (H_node_info_BRAM_dout      ),
    .H_node_info_BRAM_enb       (H_node_info_BRAM_enb       ),
    .H_node_info_BRAM_addrb     (H_node_info_BRAM_addrb     ),
    .H_node_info_BRAM_load_done (H_node_info_BRAM_load_done ),

    .Weight_BRAM_dout           (Weight_BRAM_dout           ),
    .Weight_BRAM_enb            (Weight_BRAM_enb            ),
    .Weight_BRAM_addrb          (Weight_BRAM_addrb          ),
    .Weight_BRAM_load_done      (Weight_BRAM_load_done      ),

    .a_BRAM_dout                (a_BRAM_dout                ),
    .a_BRAM_enb                 (a_BRAM_enb                 ),
    .a_BRAM_addrb               (a_BRAM_addrb               ),
    .a_BRAM_load_done           (a_BRAM_load_done           ),

    .WH_BRAM_din                (WH_BRAM_din                ),
    .WH_BRAM_ena                (WH_BRAM_ena                ),
    .WH_BRAM_wea                (WH_BRAM_wea                ),
    .WH_BRAM_addra              (WH_BRAM_addra              ),
    .WH_BRAM_dout               (WH_BRAM_dout               ),
    .WH_BRAM_enb                (WH_BRAM_enb                ),
    .WH_BRAM_addrb              (WH_BRAM_addrb              )
  );
endmodule