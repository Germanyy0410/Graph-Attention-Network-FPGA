`include "./../others/pkgs/params_pkg.sv"

module SPMM import params_pkg::*;
(
  input                                                 clk                       ,
  input                                                 rst_n                     ,

  input                                                 spmm_valid_i              ,
  output  [W_NUM_OF_COLS-1:0]                           pe_ready_o                ,
  // -- H_col_idx BRAM
  input   [COL_IDX_WIDTH-1:0]                           H_col_idx_BRAM_dout       ,
  output  [COL_IDX_ADDR_W-1:0]                          H_col_idx_BRAM_addrb      ,
  // -- H_value BRAM
  input   [VALUE_WIDTH-1:0]                             H_value_BRAM_dout         ,
  output  [VALUE_ADDR_W-1:0]                            H_value_BRAM_addrb        ,
  // -- H_node_info BRAM
  input   [NODE_INFO_WIDTH-1:0]                         H_node_info_BRAM_dout     ,
  input   [NODE_INFO_WIDTH-1:0]                         H_node_info_BRAM_dout_nxt ,
  output  [NODE_INFO_ADDR_W-1:0]                        H_node_info_BRAM_addrb    ,
  // -- Weight
  input   [W_NUM_OF_COLS-1:0] [DATA_WIDTH-1:0]          mult_weight_dout          ,
  output  [W_NUM_OF_COLS-1:0] [MULT_WEIGHT_ADDR_W-1:0]  mult_weight_addrb         ,
  // -- WH
  output  [WH_WIDTH-1:0]                                WH_1_BRAM_din             ,
  output                                                WH_1_BRAM_ena             ,
  output  [WH_1_ADDR_W-1:0]                             WH_1_BRAM_addra           ,

  output  [WH_WIDTH-1:0]                                WH_2_BRAM_din             ,
  output                                                WH_2_BRAM_ena             ,
  output  [WH_2_ADDR_W-1:0]                             WH_2_BRAM_addra
);

  //* ======== internal declaration =========
  logic                                           new_row_enable            ;
  logic [ROW_LEN_WIDTH-1:0]                       row_counter               ;
  logic [ROW_LEN_WIDTH-1:0]                       row_counter_reg           ;

  // -- Address for H_BRAM
  logic [COL_IDX_ADDR_W-1:0]                      data_addr                 ;
  logic [COL_IDX_ADDR_W-1:0]                      data_addr_reg             ;
  logic [NODE_INFO_ADDR_W-1:0]                    node_info_addr            ;
  logic [NODE_INFO_ADDR_W-1:0]                    node_info_addr_reg        ;

  // -- current data from BRAM
  logic [COL_IDX_WIDTH-1:0]                       col_idx                   ;
  logic [VALUE_WIDTH-1:0]                         value                     ;
  logic [ROW_LEN_WIDTH-1:0]                       row_length                ;
  logic                                           source_node_flag          ;
  logic [NUM_NODE_WIDTH-1:0]                      num_of_nodes              ;

  // -- next data from BRAM
  logic [ROW_LEN_WIDTH-1:0]                       row_length_nxt            ;
  logic                                           source_node_flag_nxt      ;
  logic [NUM_NODE_WIDTH-1:0]                      num_of_nodes_nxt          ;

  // -- FIFO
  node_info_t                                     ff_data_i                 ;
  node_info_t                                     ff_data_o                 ;
  logic                                           ff_empty                  ;
  logic                                           ff_full                   ;
  logic                                           ff_wr_valid               ;
  logic                                           ff_rd_valid               ;
  node_info_t                                     ff_node_info              ;
  node_info_t                                     ff_node_info_reg          ;

  // -- data from FIFO
  logic [ROW_LEN_WIDTH-1:0]                       ff_row_length             ;
  logic [ROW_LEN_WIDTH-1:0]                       ff_row_length_reg         ;
  logic                                           ff_source_node_flag       ;
  logic                                           ff_source_node_flag_reg   ;
  logic [NUM_NODE_WIDTH-1:0]                      ff_num_of_nodes           ;
  logic [NUM_NODE_WIDTH-1:0]                      ff_num_of_nodes_reg       ;

  // -- SP-PE valid signal
  logic                                           pe_valid                  ;
  logic                                           pe_valid_reg              ;
  logic                                           spmm_valid_q1             ;

  // -- SP-PE results
  logic [WH_RESULT_WIDTH-1:0]                     result_cat                ;
  logic [W_NUM_OF_COLS-1:0] [WH_DATA_WIDTH-1:0]   result                    ;
  WH_t                                            WH_data_i                 ;
  logic [WH_1_ADDR_W-1:0]                         WH_1_addr                 ;
  logic [WH_1_ADDR_W-1:0]                         WH_1_addr_reg             ;
  logic [WH_2_ADDR_W-1:0]                         WH_2_addr                 ;
  logic [WH_2_ADDR_W-1:0]                         WH_2_addr_reg             ;
  //* =======================================

  genvar i, k;
  integer x, y;

  //* ============ instantiation ============
  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      SP_PE u_SP_PE (
        .clk                (clk                        ),
        .rst_n              (rst_n                      ),

        .pe_valid_i         (pe_valid                   ),
        .pe_ready_o         (pe_ready_o[i]              ),

        .col_idx_i          (col_idx                    ),
        .value_i            (value                      ),
        .row_length_i       (ff_row_length              ),

        .weight_addrb       (mult_weight_addrb[i]       ),
        .weight_dout        (mult_weight_dout[i]        ),
        .result_o           (result[i]                  )
      );
    end
  endgenerate

  fifo #(
    .DATA_WIDTH (NODE_INFO_WIDTH  ),
    .FIFO_DEPTH (300              )
  ) node_info_FIFO (
    .clk        (clk                    ),
    .rst_n      (rst_n                  ),

    .data_i     (H_node_info_BRAM_dout  ),
    .data_o     (ff_data_o              ),

    .wr_valid_i (ff_wr_valid            ),
    .rd_valid_i (ff_rd_valid            ),

    .empty_o    (ff_empty               ),
    .full_o     (ff_full                )
  );
  //* =======================================


  //* ====== assign result to WH BRAM =======
  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      assign result_cat[WH_DATA_WIDTH*(i+1)-1-:WH_DATA_WIDTH] = result[W_NUM_OF_COLS-1-i];
    end
  endgenerate

  assign WH_data_i        = { result_cat, ff_num_of_nodes_reg, ff_source_node_flag_reg };

  assign WH_1_BRAM_din    = WH_data_i;
  assign WH_1_BRAM_ena    = (&pe_ready_o);
  assign WH_1_BRAM_addra  = WH_1_addr_reg;

  assign WH_2_BRAM_din    = WH_data_i;
  assign WH_2_BRAM_ena    = (&pe_ready_o);
  assign WH_2_BRAM_addra  = WH_2_addr_reg;

  assign WH_1_addr = (&pe_ready_o) ? ((WH_1_addr_reg < WH_1_DEPTH - 1) ? (WH_1_addr_reg + 1) : 0) : WH_1_addr_reg;
  assign WH_2_addr = (&pe_ready_o) ? (WH_2_addr_reg + 1) : WH_2_addr_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      WH_1_addr_reg <= 0;
      WH_2_addr_reg <= 0;
    end else begin
      WH_1_addr_reg <= WH_1_addr;
      WH_2_addr_reg <= WH_2_addr;
    end
  end
  //* =======================================


  //* ======== pe_valid for SP-PE ===========
  always_comb begin
    pe_valid = pe_valid_reg;

    if (spmm_valid_q1) begin
      if (data_addr_reg == 1) begin
        pe_valid = 1'b1;
      end else begin
        pe_valid = &pe_ready_o;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pe_valid_reg <= 1'b0;
    end else begin
      pe_valid_reg <= pe_valid;
    end
  end

  always_ff @(posedge clk) begin
    spmm_valid_q1 <= spmm_valid_i;
  end
  //* =======================================


  //* ======== Pop data into SP-PE ==========
  assign new_row_enable = ((row_counter_reg == 1 && row_length >= 2) || (row_length == 1)) && spmm_valid_q1;

  assign row_counter    = (((row_counter_reg == row_length - 1 && row_length > 1) || (row_counter_reg == 0 && row_length_nxt == 1)) && spmm_valid_q1)
                          || (row_counter_reg == 0 && row_length == 1 && (spmm_valid_i ^ spmm_valid_q1))
                          ? 0
                          : ((((row_counter_reg < row_length - 1) && (row_length > 1)) || (row_length == 1 && row_length_nxt > 1)) && spmm_valid_i)
                            ? (row_counter_reg + 1)
                            : row_counter_reg;

  assign data_addr      = (spmm_valid_q1 && data_addr_reg < {COL_IDX_ADDR_W{1'b1}})
                          ? (data_addr_reg + 1)
                          : data_addr_reg;

  assign node_info_addr = (((row_counter_reg == 0 && row_length >= 2) || (row_length == 1)) && spmm_valid_q1 && (node_info_addr_reg < {NODE_INFO_ADDR_W{1'b1}}))
                          ? (node_info_addr_reg + 1)
                          : node_info_addr_reg;

  // -- col_idx
  assign col_idx                = H_col_idx_BRAM_dout;
  assign H_col_idx_BRAM_addrb   = data_addr_reg;

  // -- value
  assign value                  = H_value_BRAM_dout;
  assign H_value_BRAM_addrb     = data_addr_reg;

  // -- node_info
  assign { row_length, num_of_nodes, source_node_flag } = H_node_info_BRAM_dout;
  assign H_node_info_BRAM_addrb                         = node_info_addr;

  // -- next data
  assign { row_length_nxt, num_of_nodes_nxt, source_node_flag_nxt } = H_node_info_BRAM_dout_nxt;

  // -- fifo
  assign ff_wr_valid  = new_row_enable;
  assign ff_rd_valid  = (&pe_ready_o || data_addr_reg == 1) && !ff_empty;

  // -- -- data_o
  assign ff_node_info                                             = (ff_rd_valid) ? ff_data_o : ff_node_info_reg;
  assign { ff_row_length, ff_num_of_nodes, ff_source_node_flag }  = ff_node_info;
  assign { ff_row_length_reg, ff_num_of_nodes_reg, ff_source_node_flag_reg } = ff_node_info_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      row_counter_reg     <= 0;
      data_addr_reg       <= 0;
      node_info_addr_reg  <= 0;
      ff_node_info_reg    <= 0;
    end else begin
      row_counter_reg     <= row_counter;
      data_addr_reg       <= data_addr;
      node_info_addr_reg  <= node_info_addr;
      ff_node_info_reg    <= ff_node_info;
    end
  end
  //* =======================================
endmodule