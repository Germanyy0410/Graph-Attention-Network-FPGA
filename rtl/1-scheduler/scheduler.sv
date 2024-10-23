module scheduler #(
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
  input clk,
  input rst_n,

  // -- H_col_idx BRAM
  input   [COL_IDX_WIDTH-1:0]       H_col_idx_BRAM_dout         ,
  output                            H_col_idx_BRAM_enb          ,
  output  [BRAM_ADDR_WIDTH-1:0]     H_col_idx_BRAM_addrb        ,
  input                             H_col_idx_BRAM_load_done    ,
  // -- H_value BRAM
  input   [VALUE_WIDTH-1:0]         H_value_BRAM_dout           ,
  output                            H_value_BRAM_enb            ,
  output  [BRAM_ADDR_WIDTH-1:0]     H_value_BRAM_addrb          ,
  input                             H_value_BRAM_load_done      ,
  // -- H_node_info BRAM
  input   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout       ,
  output                            H_node_info_BRAM_enb        ,
  output  [BRAM_ADDR_WIDTH-1:0]     H_node_info_BRAM_addrb      ,
  input                             H_node_info_BRAM_load_done  ,
  // -- Weight BRAM
  input   [DATA_WIDTH-1:0]          Weight_BRAM_dout            ,
  output                            Weight_BRAM_enb             ,
  output  [BRAM_ADDR_WIDTH-1:0]     Weight_BRAM_addrb           ,
  input                             Weight_BRAM_load_done       ,
  // -- a BRAM
  input   [DATA_WIDTH-1:0]          a_BRAM_dout                 ,
  output                            a_BRAM_enb                  ,
  output  [BRAM_ADDR_WIDTH-1:0]     a_BRAM_addrb                ,
  input                             a_BRAM_load_done            ,
  // -- WH BRAM
  output  [WH_BRAM_WIDTH-1:0]       WH_BRAM_din                 ,
  output                            WH_BRAM_ena                 ,
  output                            WH_BRAM_wea                 ,
  output  [BRAM_ADDR_WIDTH-1:0]     WH_BRAM_addra               ,
  input   [WH_BRAM_WIDTH-1:0]       WH_BRAM_dout                ,
  output                            WH_BRAM_enb                 ,
  output  [BRAM_ADDR_WIDTH-1:0]     WH_BRAM_addrb
);
  //* ========== wire declaration ===========
  wire  [H_INDEX_WIDTH-1:0]     num_of_nodes                                                          ;
  wire                          h_ready                                                               ;
  // -- W_loader
  wire  [DATA_WIDTH-1:0]        multi_weight_BRAM_dout      [0:W_NUM_OF_COLS-1]                       ;
  wire                          multi_weight_BRAM_enb       [0:W_NUM_OF_COLS-1]                       ;
  wire  [BRAM_ADDR_WIDTH-1:0]   multi_weight_BRAM_addrb     [0:W_NUM_OF_COLS-1]                       ;
  wire                          w_ready                                                               ;
  // -- a_loader
  wire  [DATA_WIDTH-1:0]        a                           [0:A_SIZE-1]                              ;
  wire                          a_ready                                                               ;
  // -- SPMM
  wire                          spmm_valid                                                            ;
  wire  [W_NUM_OF_COLS-1:0]     pe_ready                                                              ;
  // -- coefficient
  wire  [DATA_WIDTH-1:0]        coef                        [0:NUM_OF_NODES-1]                        ;
  //* =======================================


  //* =========== reg declaration ===========
  reg [H_INDEX_WIDTH-1:0]   H_counter       ;
  reg [H_INDEX_WIDTH-1:0]   H_counter_reg   ;

  reg [COL_IDX_WIDTH-1:0]   W_counter       ;
  reg [COL_IDX_WIDTH-1:0]   W_counter_reg   ;
  //* =======================================

  genvar i;
  assign spmm_valid = (H_col_idx_BRAM_load_done && H_value_BRAM_load_done && H_node_info_BRAM_load_done);


  W_loader #(
    .DATA_WIDTH       (DATA_WIDTH       ),
    .W_NUM_OF_COLS    (W_NUM_OF_COLS    ),
    .W_NUM_OF_ROWS    (W_NUM_OF_ROWS    ),
    .BRAM_ADDR_WIDTH  (BRAM_ADDR_WIDTH  )
  ) u_W_loader (
    .clk                      (clk                    ),
    .rst_n                    (rst_n                  ),

    .w_valid_i                (Weight_BRAM_load_done  ),
    .w_ready_o                (w_ready                ),

    .Weight_BRAM_dout         (Weight_BRAM_dout       ),
    .Weight_BRAM_enb          (Weight_BRAM_enb        ),
    .Weight_BRAM_addrb        (Weight_BRAM_addrb      ),

    .multi_weight_BRAM_dout   (multi_weight_BRAM_dout ),
    .multi_weight_BRAM_enb    (multi_weight_BRAM_enb  ),
    .multi_weight_BRAM_addrb  (multi_weight_BRAM_addrb)
  );

  a_loader #(
    .DATA_WIDTH       (DATA_WIDTH       ),
    .BRAM_ADDR_WIDTH  (BRAM_ADDR_WIDTH  ),
    .A_SIZE           (A_SIZE           )
  ) u_a_loader (
    .clk                      (clk                    ),
    .rst_n                    (rst_n                  ),

    .a_valid_i                (a_BRAM_load_done       ),
    .a_ready_o                (a_ready                ),

    .a_BRAM_dout              (a_BRAM_dout            ),
    .a_BRAM_enb               (a_BRAM_enb             ),
    .a_BRAM_addrb             (a_BRAM_addrb           ),

    .a_o                      (a                      )
  );

  SPMM #(
    .DATA_WIDTH       (DATA_WIDTH       ),
    .DOT_PRODUCT_SIZE (H_NUM_OF_COLS    ),

    .H_NUM_OF_COLS    (H_NUM_OF_COLS    ),
    .H_NUM_OF_ROWS    (H_NUM_OF_ROWS    ),

    .W_NUM_OF_ROWS    (W_NUM_OF_ROWS    ),
    .W_NUM_OF_COLS    (W_NUM_OF_COLS    ),
    .NUM_OF_NODES     (NUM_OF_NODES     ),

    .WH_BRAM_WIDTH    (WH_BRAM_WIDTH    )
  ) u_SPMM (
    .clk                        (clk                        ),
    .rst_n                      (rst_n                      ),

    .H_col_idx_BRAM_dout        (H_col_idx_BRAM_dout        ),
    .H_col_idx_BRAM_enb         (H_col_idx_BRAM_enb         ),
    .H_col_idx_BRAM_addrb       (H_col_idx_BRAM_addrb       ),

    .H_value_BRAM_dout          (H_value_BRAM_dout          ),
    .H_value_BRAM_enb           (H_value_BRAM_enb           ),
    .H_value_BRAM_addrb         (H_value_BRAM_addrb         ),

    .H_node_info_BRAM_dout      (H_node_info_BRAM_dout      ),
    .H_node_info_BRAM_enb       (H_node_info_BRAM_enb       ),
    .H_node_info_BRAM_addrb     (H_node_info_BRAM_addrb     ),

    .multi_weight_BRAM_dout     (multi_weight_BRAM_dout     ),
    .multi_weight_BRAM_enb      (multi_weight_BRAM_enb      ),
    .multi_weight_BRAM_addrb    (multi_weight_BRAM_addrb    ),

    .spmm_valid_i               (spmm_valid                 ),
    .pe_ready_o                 (pe_ready                   ),

    .WH_BRAM_din                (WH_BRAM_din                ),
    .WH_BRAM_ena                (WH_BRAM_ena                ),
    .WH_BRAM_wea                (WH_BRAM_wea                ),
    .WH_BRAM_addra              (WH_BRAM_addra              )
  );

  DMVM #(
    .A_SIZE           (A_SIZE           ),
    .DATA_WIDTH       (DATA_WIDTH       ),
    .BRAM_ADDR_WIDTH  (BRAM_ADDR_WIDTH  ),
    .NUM_OF_NODES     (H_NUM_OF_ROWS    )
  ) u_DMVM (
    .clk              (clk              ),
    .rst_n            (rst_n            ),

    .a_valid_i        (a_BRAM_load_done ),

    .WH_BRAM_dout     (WH_BRAM_dout     ),
    .WH_BRAM_enb      (WH_BRAM_enb      ),
    .WH_BRAM_addrb    (WH_BRAM_addrb    ),

    .a_i              (a                )
  );
endmodule


