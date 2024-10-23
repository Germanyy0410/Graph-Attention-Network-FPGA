module SPMM #(
  //* ========== parameter ===========
  parameter DATA_WIDTH        = 8,
  parameter DOT_PRODUCT_SIZE  = 1433,
  // -- H
  parameter H_NUM_OF_COLS     = DOT_PRODUCT_SIZE,
  parameter H_NUM_OF_ROWS     = 2708,
  // -- W
  parameter W_NUM_OF_ROWS     = DOT_PRODUCT_SIZE,
  parameter W_NUM_OF_COLS     = 16,
  // -- BRAM
  parameter BRAM_ADDR_WIDTH   = 32,
// -- NUM_OF_NODES
  parameter NUM_OF_NODES      = 168,

  //* ========= localparams ==========
  // -- col_idx
  parameter COL_IDX_WIDTH     = $clog2(H_NUM_OF_COLS),
  // -- value
  parameter VALUE_WIDTH       = DATA_WIDTH,
  // -- row_info
  parameter ROW_LEN_WIDTH     = $clog2(H_NUM_OF_COLS),
  parameter NUM_NODE_WIDTH    = $clog2(NUM_OF_NODES),
  parameter NODE_INFO_WIDTH   = ROW_LEN_WIDTH + NUM_NODE_WIDTH + 1,
  parameter FF_DATA_WIDTH     = COL_IDX_WIDTH + VALUE_WIDTH,

  parameter WH_COL_WIDTH      = $clog2(H_NUM_OF_ROWS),
  parameter WH_ROW_WIDTH      = $clog2(W_NUM_OF_COLS),

  parameter WH_BRAM_WIDTH     = DATA_WIDTH * 16 + NUM_NODE_WIDTH + 1
)(
  input                           clk                                                   ,
  input                           rst_n                                                 ,

  input                           spmm_valid_i                                            ,
  output  [W_NUM_OF_COLS-1:0]     pe_ready_o                                            ,
  // -- H_col_idx BRAM
  input   [COL_IDX_WIDTH-1:0]     H_col_idx_BRAM_dout                                   ,
  output                          H_col_idx_BRAM_enb                                    ,
  output  [BRAM_ADDR_WIDTH-1:0]   H_col_idx_BRAM_addrb                                  ,
  // -- H_value BRAM
  input   [VALUE_WIDTH-1:0]       H_value_BRAM_dout                                     ,
  output                          H_value_BRAM_enb                                      ,
  output  [BRAM_ADDR_WIDTH-1:0]   H_value_BRAM_addrb                                    ,
  // -- H_node_info BRAM
  input   [NODE_INFO_WIDTH-1:0]   H_node_info_BRAM_dout                                 ,
  output                          H_node_info_BRAM_enb                                  ,
  output  [BRAM_ADDR_WIDTH-1:0]   H_node_info_BRAM_addrb                                ,
  // -- Weight
  input   [DATA_WIDTH-1:0]        multi_weight_BRAM_dout        [0:W_NUM_OF_COLS-1]     ,
  output                          multi_weight_BRAM_enb         [0:W_NUM_OF_COLS-1]     ,
  output  [BRAM_ADDR_WIDTH-1:0]   multi_weight_BRAM_addrb       [0:W_NUM_OF_COLS-1]     ,
  // -- WH
  output  [DATA_WIDTH*16:0]       WH_BRAM_din                                           ,
  output                          WH_BRAM_ena                                           ,
  output                          WH_BRAM_wea                                           ,
  output  [BRAM_ADDR_WIDTH-1:0]   WH_BRAM_addra
);
  //* ========== wire declaration ===========
  wire    [DATA_WIDTH-1:0]        result          [0:W_NUM_OF_COLS-1]     ;
  wire    [BRAM_ADDR_WIDTH-1:0]   WH_addr                                 ;

  wire    [COL_IDX_WIDTH-1:0]     col_idx                                 ;

  wire    [VALUE_WIDTH-1:0]       value                                   ;

  wire    [ROW_LEN_WIDTH-1:0]     row_length                              ;
  wire                            source_node_flag                        ;
  wire    [NUM_NODE_WIDTH-1:0]    num_of_nodes                            ;

  wire    [7:0]                   row_counter                             ;
  //* =======================================


  //* ========== reg declaration ============
  reg     [7:0]                   row_counter_reg                         ;

  reg     [BRAM_ADDR_WIDTH-1:0]   data_addr                               ;
  reg     [BRAM_ADDR_WIDTH-1:0]   data_addr_reg                           ;
  reg     [BRAM_ADDR_WIDTH-1:0]   node_info_addr                          ;
  reg     [BRAM_ADDR_WIDTH-1:0]   node_info_addr_reg                      ;

  reg     [BRAM_ADDR_WIDTH-1:0]   WH_addr_reg                             ;
  reg     [WH_COL_WIDTH-1:0]      col_counter                             ;
  reg     [WH_COL_WIDTH-1:0]      col_counter_reg                         ;

  reg                             pe_valid                                ;
  reg                             pe_valid_reg                            ;
  reg                             spmm_valid_q1                           ;
  reg                             spmm_valid_q2                           ;
  reg                             spmm_valid_q3                           ;
  //* =======================================


  //* ========= internal declaration ========
  genvar i, k;
  integer x, y;
  //* =======================================


  //* ============ instantiation ============
  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      SP_PE #(
        .DATA_WIDTH       (DATA_WIDTH       ),
        .DOT_PRODUCT_SIZE (DOT_PRODUCT_SIZE )
      ) u_SP_PE (
        .clk                (clk                        ),
        .rst_n              (rst_n                      ),

        .pe_valid_i         (pe_valid_reg               ),
        .pe_ready_o         (pe_ready_o[i]              ),

        .col_idx_i          (col_idx                    ),
        .value_i            (value                      ),
        .row_length_i       (row_length                 ),

        .Weight_BRAM_dout   (multi_weight_BRAM_dout[i]  ),
        .Weight_BRAM_enb    (multi_weight_BRAM_enb[i]   ),
        .Weight_BRAM_addrb  (multi_weight_BRAM_addrb[i] ),

        .result_o           (result[i]                  )
      );
    end
  endgenerate
  //* =======================================


  //* ====== assign result to WH BRAM =======
  assign WH_BRAM_din = { result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7], result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15], num_of_nodes, source_node_flag };

  assign WH_BRAM_ena    = (&pe_ready_o);
  assign WH_BRAM_wea    = (&pe_ready_o);
  assign WH_BRAM_addra  = WH_addr_reg;

  assign WH_addr = (&pe_ready_o) ? (WH_addr_reg + 1) : WH_addr_reg;

  always @(posedge clk) begin
    if (!rst_n) begin
      WH_addr_reg <= 0;
    end else begin
      WH_addr_reg <= WH_addr;
    end
  end
  //* =======================================


  //* ======== pe_valid for SP-PE ===========
  always @(*) begin
    pe_valid = pe_valid_reg;

    if (spmm_valid_q3) begin
      if (data_addr_reg == 0 && node_info_addr_reg == 0) begin
        pe_valid = 1'b1;
      end else if (row_counter_reg == 0) begin
        pe_valid = 1'b1;
      end else begin
        pe_valid = 1'b0;
      end
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      pe_valid_reg <= 1'b0;
    end else begin
      pe_valid_reg <= pe_valid;
    end
  end
  //* =======================================


  //* ======== Pop data into SP-PE ==========
  always @(posedge clk) begin
    spmm_valid_q1 <= spmm_valid_i;
    spmm_valid_q2 <= spmm_valid_q1;
    spmm_valid_q3 <= spmm_valid_q2;
  end

  assign row_counter    = (row_counter_reg == row_length - 1 && spmm_valid_q2) ? 0 : ((row_counter_reg < row_length - 1 && spmm_valid_q2) ? (row_counter_reg + 1) : row_counter_reg);
  assign data_addr      = spmm_valid_q2 ? (data_addr_reg + 1) : data_addr_reg;
  assign node_info_addr = (row_counter_reg == row_length - 1 && spmm_valid_i) ? (node_info_addr_reg + 1) : node_info_addr_reg;

  // -- col_idx
  assign col_idx                = H_col_idx_BRAM_dout;
  assign H_col_idx_BRAM_addrb   = data_addr_reg;
  assign H_col_idx_BRAM_enb     = spmm_valid_q2;

  // -- value
  assign value                  = H_value_BRAM_dout;
  assign H_value_BRAM_addrb     = data_addr_reg;
  assign H_value_BRAM_enb       = spmm_valid_q2;

  // -- node_info
  assign { row_length, num_of_nodes, source_node_flag } = H_node_info_BRAM_dout;
  assign H_node_info_BRAM_addrb                         = node_info_addr_reg;
  assign H_node_info_BRAM_enb                           = spmm_valid_i;

  always @(posedge clk) begin
    if (!rst_n) begin
      row_counter_reg     <= 0;
      data_addr_reg       <= 0;
      node_info_addr_reg  <= 0;
    end else begin
      row_counter_reg     <= row_counter;
      data_addr_reg       <= data_addr;
      node_info_addr_reg  <= node_info_addr;
    end
  end
  //* =======================================
endmodule