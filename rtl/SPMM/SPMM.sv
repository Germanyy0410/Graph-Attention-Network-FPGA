`include "./../others/pkgs/params_pkg.sv"

module SPMM import params_pkg::*;
(
  input                                                 clk                       ,
  input                                                 rst_n                     ,

  input                                                 spmm_valid_i              ,
  output                                                spmm_ready_o              ,

  // -- H_data BRAM
  input   [H_DATA_WIDTH-1:0]                            H_data_BRAM_dout          ,
  output  [H_DATA_ADDR_W-1:0]                           H_data_BRAM_addrb         ,

  // -- H_node_info BRAM
  input   [NODE_INFO_WIDTH-1:0]                         H_node_info_BRAM_dout     ,
  input   [NODE_INFO_WIDTH-1:0]                         H_node_info_BRAM_dout_nxt ,
  output  [NODE_INFO_ADDR_W-1:0]                        H_node_info_BRAM_addrb    ,

  // -- Weight
  input   [W_NUM_OF_COLS-1:0] [DATA_WIDTH-1:0]          mult_weight_dout          ,
  output  [W_NUM_OF_COLS-1:0] [MULT_WEIGHT_ADDR_W-1:0]  mult_weight_addrb         ,

  // -- DMVM
  output  [WH_WIDTH-1:0]                                WH_data_o                 ,

  // -- num_of_nodes
  output  [NUM_NODE_WIDTH-1:0]                          num_node_BRAM_din         ,
  output                                                num_node_BRAM_ena         ,
  output  [NUM_NODE_ADDR_W-1:0]                         num_node_BRAM_addra       ,

  output  WH_t                                          WH_BRAM_din               ,
  output                                                WH_BRAM_ena               ,
  output  [WH_ADDR_W-1:0]                               WH_BRAM_addra
);

  //* ======== internal declaration =========
  logic                                           new_row_enable            ;
  logic [ROW_LEN_WIDTH-1:0]                       row_counter               ;
  logic [ROW_LEN_WIDTH-1:0]                       row_counter_reg           ;

  // -- Address for H_BRAM
  logic [H_DATA_ADDR_W-1:0]                       data_addr                 ;
  logic [H_DATA_ADDR_W-1:0]                       data_addr_reg             ;
  logic [NODE_INFO_ADDR_W-1:0]                    node_info_addr            ;
  logic [NODE_INFO_ADDR_W-1:0]                    node_info_addr_reg        ;

  // -- current data from BRAM
  logic [COL_IDX_WIDTH-1:0]                       col_idx                   ;
  logic [DATA_WIDTH-1:0]                          value                     ;
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
  logic [W_NUM_OF_COLS-1:0]                       pe_ready_o                ;

  // -- SP-PE results
  logic [WH_RESULT_WIDTH-1:0]                     result_cat                ;
  logic [W_NUM_OF_COLS-1:0] [WH_DATA_WIDTH-1:0]   result                    ;
  WH_t                                            WH_data_i                 ;
  logic [WH_ADDR_W-1:0]                           WH_addr                   ;
  logic [WH_ADDR_W-1:0]                           WH_addr_reg               ;

  // -- output
  logic [WH_WIDTH-1:0]                            WH_data                   ;
  logic [WH_WIDTH-1:0]                            WH_data_reg               ;


  // -- num_of_nodes BRAM
  logic [NUM_NODE_ADDR_W-1:0]                     addr                      ;
  logic [NUM_NODE_ADDR_W-1:0]                     addr_reg                  ;

  logic [NUM_NODE_WIDTH-1:0]                      num_of_nodes_reg          ;

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
  assign spmm_ready_o = &pe_ready_o;
  assign WH_data_o    = WH_data;
  //* =======================================


  //* ============ instantiation ============
  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      (* dont_touch = "yes" *)
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

  FIFO #(
    .DATA_WIDTH (NODE_INFO_WIDTH  ),
    .FIFO_DEPTH (100              )
  ) node_info_FIFO (
    .clk        (clk                    ),
    .rst_n      (rst_n                  ),

    .din        (H_node_info_BRAM_dout  ),
    .dout       (ff_data_o              ),

    .wr_vld     (ff_wr_valid            ),
    .rd_vld     (ff_rd_valid            ),

    .empty      (ff_empty               ),
    .full       (ff_full                )
  );
  //* =======================================


  //* ====== assign result to WH BRAM =======
  generate
    for (i = 0; i < W_NUM_OF_COLS; i = i + 1) begin
      assign result_cat[WH_DATA_WIDTH*(i+1)-1-:WH_DATA_WIDTH] = result[W_NUM_OF_COLS-1-i];
    end
  endgenerate

  // -- output from SP-PE
  assign WH_data_i  = { result_cat, ff_num_of_nodes_reg, ff_source_node_flag_reg };

  // -- WH BRAM
  assign WH_BRAM_din    = { result_cat, ff_num_of_nodes_reg, ff_source_node_flag_reg };
  assign WH_BRAM_ena    = (&pe_ready_o);
  assign WH_BRAM_addra  = WH_addr_reg;

  // -- WH BRAM addr
  assign WH_addr = (&pe_ready_o) ? (WH_addr_reg + 1) : WH_addr_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      WH_addr_reg <= 0;
    end else begin
      WH_addr_reg <= WH_addr;
    end
  end
  //* =======================================


  //* ============== WH output ==============
  assign WH_data = (&pe_ready_o) ? { result_cat, ff_num_of_nodes_reg, ff_source_node_flag_reg } : WH_data_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      WH_data_reg <= 0;
    end else begin
      WH_data_reg <= WH_data;
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

  assign data_addr      = (spmm_valid_q1) ? (data_addr_reg + 1) : data_addr_reg;

  assign node_info_addr = (((row_counter_reg == 0 && row_length >= 2) || (row_length == 1)) && spmm_valid_q1 && (node_info_addr_reg < {NODE_INFO_ADDR_W{1'b1}}))
                          ? (node_info_addr_reg + 1)
                          : node_info_addr_reg;

  // -- col_idx & value
  assign { col_idx, value } = H_data_BRAM_dout;
  assign H_data_BRAM_addrb  = data_addr_reg;

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


  //* ========== num_of_nodes BRAM ==========
  // push to BRAM
  assign num_node_BRAM_din   = num_of_nodes_reg;
  assign num_node_BRAM_ena   = nn_ena_reg;
  assign num_node_BRAM_addra = addr_reg;

  assign addr_en  = (node_info_addr != node_info_addr_reg);
  assign nn_ena   = ((cpt_nf_addr_reg == node_info_addr_reg) && (node_info_addr_reg > 0)) || (addr_en_reg && node_info_addr_reg == 1);

  always_comb begin
    cpt_nf_addr = cpt_nf_addr_reg;
    addr        = addr_reg;

    if (addr_en_reg) begin
      if ((source_node_flag && node_info_addr_reg > 1) || (~source_node_flag && node_info_addr_reg == 1)) begin
        cpt_nf_addr = cpt_nf_addr_reg + num_of_nodes;
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
      num_of_nodes_reg  <= 'b0;
    end else begin
      addr_reg          <= addr;
      nn_ena_reg        <= nn_ena;
      addr_en_reg       <= addr_en;
      cpt_nf_addr_reg   <= cpt_nf_addr;
      num_of_nodes_reg  <= num_of_nodes;
    end
  end
  //* =======================================
endmodule