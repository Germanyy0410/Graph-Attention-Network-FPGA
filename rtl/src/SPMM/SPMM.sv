module SPMM import gat_pkg::*;
(
  input                                                 clk                       ,
  input                                                 rst_n                     ,

  input                                                 spmm_vld_i                ,
  output                                                spmm_rdy_o                ,

  // -- h_data BRAM
  input   [H_DATA_WIDTH-1:0]                            h_data_bram_dout          ,
  output  [H_DATA_ADDR_W-1:0]                           h_data_bram_addrb         ,

  // -- h_node_info BRAM
  input   [NODE_INFO_WIDTH-1:0]                         h_node_info_bram_dout     ,
  input   [NODE_INFO_WIDTH-1:0]                         h_node_info_bram_dout_nxt ,
  output  [NODE_INFO_ADDR_W-1:0]                        h_node_info_bram_addrb    ,

  // -- Weight
  input   [W_NUM_OF_COLS-1:0] [DATA_WIDTH-1:0]          mult_wgt_dout             ,
  output  [W_NUM_OF_COLS-1:0] [MULT_WEIGHT_ADDR_W-1:0]  mult_wgt_addrb            ,

  // -- DMVM
  output  [WH_WIDTH-1:0]                                wh_data_o                 ,

  // -- num_node
  output  [NUM_NODE_WIDTH-1:0]                          num_node_bram_din         ,
  output                                                num_node_bram_ena         ,
  output  [NUM_NODE_ADDR_W-1:0]                         num_node_bram_addra       ,

  output  wh_t                                          wh_bram_din               ,
  output                                                wh_bram_ena               ,
  output  [WH_ADDR_W-1:0]                               wh_bram_addra
);

  //* ======== internal declaration =========
  logic                                           new_row_en                ;
  logic [ROW_LEN_WIDTH-1:0]                       row_cnt                   ;
  logic [ROW_LEN_WIDTH-1:0]                       row_cnt_reg               ;

  // -- Address for H_bram
  logic [H_DATA_ADDR_W-1:0]                       data_addr                 ;
  logic [H_DATA_ADDR_W-1:0]                       data_addr_reg             ;
  logic [NODE_INFO_ADDR_W-1:0]                    node_info_addr            ;
  logic [NODE_INFO_ADDR_W-1:0]                    node_info_addr_reg        ;

  // -- current data from bram
  logic [COL_IDX_WIDTH-1:0]                       col_idx                   ;
  logic [DATA_WIDTH-1:0]                          val                       ;
  logic [ROW_LEN_WIDTH-1:0]                       row_len                   ;
  logic                                           src_flag                  ;
  logic [NUM_NODE_WIDTH-1:0]                      num_node                  ;

  // -- next data from bram
  logic [ROW_LEN_WIDTH-1:0]                       row_len_nxt               ;
  logic                                           src_flag_nxt              ;
  logic [NUM_NODE_WIDTH-1:0]                      num_node_nxt              ;

  // -- ff
  node_info_t                                     ff_data_i                 ;
  node_info_t                                     ff_data_o                 ;
  logic                                           ff_empty                  ;
  logic                                           ff_full                   ;
  logic                                           ff_wr_vld                 ;
  logic                                           ff_rd_vld                 ;
  node_info_t                                     ff_node_info              ;
  node_info_t                                     ff_node_info_reg          ;

  // -- data from ff
  logic [ROW_LEN_WIDTH-1:0]                       ff_row_len                ;
  logic [ROW_LEN_WIDTH-1:0]                       ff_row_len_reg            ;
  logic                                           ff_src_flag               ;
  logic                                           ff_src_flag_reg           ;
  logic [NUM_NODE_WIDTH-1:0]                      ff_num_node               ;
  logic [NUM_NODE_WIDTH-1:0]                      ff_num_node_reg           ;

  // -- SP-PE valid signal
  logic                                           pe_vld                    ;
  logic                                           pe_vld_reg                ;
  logic                                           spmm_vld_q1               ;
  logic [W_NUM_OF_COLS-1:0]                       pe_rdy_o                  ;

  // -- SP-PE results
  logic [WH_RESULT_WIDTH-1:0]                     sppe_cat                  ;
  logic [W_NUM_OF_COLS-1:0] [WH_DATA_WIDTH-1:0]   sppe                      ;
  wh_t                                            wh_data_i                 ;
  logic [WH_ADDR_W-1:0]                           wh_addr                   ;
  logic [WH_ADDR_W-1:0]                           wh_addr_reg               ;

  // -- output
  logic [WH_WIDTH-1:0]                            wh_data                   ;
  logic [WH_WIDTH-1:0]                            wh_data_reg               ;


  // -- num_node bram
  logic [NUM_NODE_ADDR_W-1:0]                     addr                      ;
  logic [NUM_NODE_ADDR_W-1:0]                     addr_reg                  ;

  logic [NUM_NODE_WIDTH-1:0]                      num_node_reg              ;

  logic [NODE_INFO_ADDR_W-1:0]                    cpt_nf_addr               ;
  logic [NODE_INFO_ADDR_W-1:0]                    cpt_nf_addr_reg           ;

  logic                                           nn_ena                    ;
  logic                                           nn_ena_reg                ;

  logic                                           addr_en                   ;
  logic                                           addr_en_reg               ;
  //* =======================================

  genvar i, k;
  integer x, y;


  //* ========== output assignment ==========
  assign spmm_rdy_o = &pe_rdy_o;
  assign wh_data_o  = wh_data;
  //* =======================================


  //* ============ instantiation ============
  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      SP_PE u_SP_PE (
        .clk          (clk                  ),
        .rst_n        (rst_n                ),

        .pe_vld_i     (pe_vld               ),
        .pe_rdy_o     (pe_rdy_o[i]          ),

        .col_idx_i    (col_idx              ),
        .val_i        (val                  ),
        .row_len_i    (ff_row_len           ),

        .wgt_addrb    (mult_wgt_addrb[i]    ),
        .wgt_dout     (mult_wgt_dout[i]     ),
        .res_o        (sppe[i]              )
      );
    end
  endgenerate

  FIFO #(
    .DATA_WIDTH (NODE_INFO_WIDTH  ),
    .FIFO_DEPTH (100              )
  ) node_info_fifo (
    .clk        (clk                    ),
    .rst_n      (rst_n                  ),

    .din        (h_node_info_bram_dout  ),
    .dout       (ff_data_o              ),

    .wr_vld     (ff_wr_vld              ),
    .rd_vld     (ff_rd_vld              ),

    .empty      (ff_empty               ),
    .full       (ff_full                )
  );
  //* =======================================


  //* ====== assign sppe to WH bram =======
  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      assign sppe_cat[WH_DATA_WIDTH*(i+1)-1-:WH_DATA_WIDTH] = sppe[W_NUM_OF_COLS-1-i];
    end
  endgenerate

  // -- output from SP-PE
  assign wh_data_i  = { sppe_cat, ff_num_node_reg, ff_src_flag_reg };

  // -- WH bram
  assign wh_bram_din    = { sppe_cat, ff_num_node_reg, ff_src_flag_reg };
  assign wh_bram_ena    = (&pe_rdy_o);
  assign wh_bram_addra  = wh_addr_reg;

  // -- WH bram addr
  assign wh_addr = (&pe_rdy_o) ? (wh_addr_reg + 1) : wh_addr_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wh_addr_reg <= 0;
    end else begin
      wh_addr_reg <= wh_addr;
    end
  end
  //* =======================================


  //* ============== WH output ==============
  assign wh_data = (&pe_rdy_o) ? { sppe_cat, ff_num_node_reg, ff_src_flag_reg } : wh_data_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wh_data_reg <= 0;
    end else begin
      wh_data_reg <= wh_data;
    end
  end
  //* =======================================


  //* ======== pe_vld for SP-PE ===========
  always_comb begin
    pe_vld = pe_vld_reg;

    if (spmm_vld_q1) begin
      if (data_addr_reg == 1) begin
        pe_vld = 1'b1;
      end else begin
        pe_vld = &pe_rdy_o;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pe_vld_reg <= 1'b0;
    end else begin
      pe_vld_reg <= pe_vld;
    end
  end

  always_ff @(posedge clk) begin
    spmm_vld_q1 <= spmm_vld_i;
  end
  //* =======================================


  //* ======== Pop data into SP-PE ==========
  assign new_row_en = ((row_cnt_reg == 1 && row_len >= 2) || (row_len == 1)) && spmm_vld_q1;

  assign row_cnt    = (((row_cnt_reg == row_len - 1 && row_len > 1) || (row_cnt_reg == 0 && row_len_nxt == 1)) && spmm_vld_q1)
                          || (row_cnt_reg == 0 && row_len == 1 && (spmm_vld_i ^ spmm_vld_q1))
                          ? 0
                          : ((((row_cnt_reg < row_len - 1) && (row_len > 1)) || (row_len == 1 && row_len_nxt > 1)) && spmm_vld_i)
                            ? (row_cnt_reg + 1)
                            : row_cnt_reg;

  assign data_addr      = (spmm_vld_q1) ? (data_addr_reg + 1) : data_addr_reg;

  assign node_info_addr = (((row_cnt_reg == 0 && row_len >= 2) || (row_len == 1)) && spmm_vld_q1 && (node_info_addr_reg < {NODE_INFO_ADDR_W{1'b1}}))
                          ? (node_info_addr_reg + 1)
                          : node_info_addr_reg;

  // -- col_idx & val
  assign { col_idx, val }   = h_data_bram_dout;
  assign h_data_bram_addrb  = data_addr_reg;

  // -- node_info
  assign { row_len, num_node, src_flag }  = h_node_info_bram_dout;
  assign h_node_info_bram_addrb           = node_info_addr;

  // -- next data
  assign { row_len_nxt, num_node_nxt, src_flag_nxt } = h_node_info_bram_dout_nxt;

  // -- ff
  assign ff_wr_vld  = new_row_en;
  assign ff_rd_vld  = (&pe_rdy_o || data_addr_reg == 1) && !ff_empty;

  // -- -- data_o
  assign ff_node_info                                         = (ff_rd_vld)   ? ff_data_o : ff_node_info_reg;
  assign { ff_row_len, ff_num_node, ff_src_flag }             = ff_node_info;
  assign { ff_row_len_reg, ff_num_node_reg, ff_src_flag_reg } = ff_node_info_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      row_cnt_reg     <= 0;
      data_addr_reg       <= 'b0;
      node_info_addr_reg  <= 'b0;
      ff_node_info_reg    <= 'b0;
    end else begin
      row_cnt_reg     <= row_cnt;
      data_addr_reg       <= data_addr;
      node_info_addr_reg  <= node_info_addr;
      ff_node_info_reg    <= ff_node_info;
    end
  end
  //* =======================================


  //* ========== num_node bram ==========
  // push to bram
  assign num_node_bram_din   = num_node_reg;
  assign num_node_bram_ena   = nn_ena_reg;
  assign num_node_bram_addra = addr_reg;

  assign addr_en  = (node_info_addr != node_info_addr_reg);
  assign nn_ena   = ((cpt_nf_addr_reg == node_info_addr_reg) && (node_info_addr_reg > 0)) || (addr_en_reg && node_info_addr_reg == 1);

  always_comb begin
    cpt_nf_addr = cpt_nf_addr_reg;
    addr        = addr_reg;

    if (addr_en_reg) begin
      if ((src_flag && node_info_addr_reg > 1) || (~src_flag && node_info_addr_reg == 1)) begin
        cpt_nf_addr = cpt_nf_addr_reg + num_node;
      end
    end

    if (nn_ena_reg && (node_info_addr_reg > 0)) begin
      addr = addr_reg + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      addr_en_reg       <= 'b0;
      addr_reg          <= 'b0;
      nn_ena_reg        <= 'b0;
      cpt_nf_addr_reg   <= 'b0;
      num_node_reg      <= 'b0;
    end else begin
      addr_reg          <= addr;
      nn_ena_reg        <= nn_ena;
      addr_en_reg       <= addr_en;
      cpt_nf_addr_reg   <= cpt_nf_addr;
      num_node_reg      <= num_node;
    end
  end
  //* =======================================
endmodule