`include "./others/pkgs/params_pkg.sv"

module top import params_pkg::*;
(
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

  input   [DATA_WIDTH-1:0]          a_BRAM_din                  ,
  input                             a_BRAM_ena                  ,
  input   [A_ADDR_W-1:0]            a_BRAM_addra                ,
  output  [A_ADDR_W-1:0]            a_BRAM_addrb                ,
  input                             a_BRAM_load_done
);
  logic   [VALUE_WIDTH-1:0]         H_value_BRAM_dout           ;
  logic   [COL_IDX_WIDTH-1:0]       H_col_idx_BRAM_dout         ;
  logic   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout       ;
  logic   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout_nxt   ;
  logic   [DATA_WIDTH-1:0]          Weight_BRAM_dout            ;
  logic   [DATA_WIDTH-1:0]          a_BRAM_dout                 ;

  logic   [WH_WIDTH-1:0]            WH_1_BRAM_din               ;
  logic                             WH_1_BRAM_ena               ;
  logic   [WH_1_ADDR_W-1:0]         WH_1_BRAM_addra             ;
  logic   [WH_1_ADDR_W-1:0]         WH_1_BRAM_addrb             ;
  logic   [WH_WIDTH-1:0]            WH_1_BRAM_dout              ;

  logic   [WH_WIDTH-1:0]            WH_2_BRAM_din               ;
  logic                             WH_2_BRAM_ena               ;
  logic   [WH_2_ADDR_W-1:0]         WH_2_BRAM_addra             ;
  logic   [WH_2_ADDR_W-1:0]         WH_2_BRAM_addrb             ;
  logic   [WH_WIDTH-1:0]            WH_2_BRAM_dout              ;

  logic   [SOFTMAX_WIDTH-1:0]       softmax_FIFO_din            ;
  logic   [SOFTMAX_WIDTH-1:0]       softmax_FIFO_dout           ;
  logic                             softmax_FIFO_wr_valid       ;
  logic                             softmax_FIFO_rd_valid       ;
  logic                             softmax_FIFO_empty          ;
  logic                             softmax_FIFO_full           ;

  logic   [AGGR_WIDTH-1:0]          aggr_FIFO_din               ;
  logic   [AGGR_WIDTH-1:0]          aggr_FIFO_dout              ;
  logic                             aggr_FIFO_wr_valid          ;
  logic                             aggr_FIFO_rd_valid          ;
  logic                             aggr_FIFO_empty             ;
  logic                             aggr_FIFO_full              ;

  logic   [AGGR_WIDTH-1:0]          aggr_BRAM_din               ;
  logic                             aggr_BRAM_ena               ;
  logic   [AGGR_ADDR_W-1:0]         aggr_BRAM_addra             ;
  logic   [AGGR_WIDTH-1:0]          aggr_BRAM_dout              ;
  logic   [AGGR_ADDR_W-1:0]         aggr_BRAM_addrb             ;

  genvar i;

  //* ========================= MEMORY =========================
  (* dont_touch = "yes" *)
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

  (* dont_touch = "yes" *)
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

  (* dont_touch = "yes" *)
  modified_BRAM #(
    .DATA_WIDTH   (NODE_INFO_WIDTH            ),
    .DEPTH        (NODE_INFO_DEPTH            ),
    .CLK_LATENCY  (1                          )
  ) u_H_node_info_BRAM (
    .clk          (clk                        ),
    .rst_n        (rst_n                      ),
    .din          (H_node_info_BRAM_din       ),
    .addra        (H_node_info_BRAM_addra     ),
    .ena          (H_node_info_BRAM_ena       ),
    .addrb        (H_node_info_BRAM_addrb     ),
    .dout         (H_node_info_BRAM_dout      ),
    .dout_nxt     (H_node_info_BRAM_dout_nxt  )
  );

  (* dont_touch = "yes" *)
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

  (* dont_touch = "yes" *)
  BRAM #(
    .DATA_WIDTH   (WH_WIDTH             ),
    .DEPTH        (WH_1_DEPTH           ),
    .CLK_LATENCY  (1                    )
  ) u_WH_1_BRAM (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (WH_1_BRAM_din        ),
    .addra        (WH_1_BRAM_addra      ),
    .ena          (WH_1_BRAM_ena        ),
    .addrb        (WH_1_BRAM_addrb      ),
    .dout         (WH_1_BRAM_dout       )
  );

  (* dont_touch = "yes" *)
  BRAM #(
    .DATA_WIDTH   (WH_WIDTH             ),
    .DEPTH        (WH_2_DEPTH           ),
    .CLK_LATENCY  (1                    )
  ) u_WH_2_BRAM (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (WH_2_BRAM_din        ),
    .addra        (WH_2_BRAM_addra      ),
    .ena          (WH_2_BRAM_ena        ),
    .addrb        (WH_2_BRAM_addrb      ),
    .dout         (WH_2_BRAM_dout       )
  );

  (* dont_touch = "yes" *)
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

  (* dont_touch = "yes" *)
  fifo #(
    .DATA_WIDTH (SOFTMAX_WIDTH          ),
    .FIFO_DEPTH (20                     )
  ) u_softmax_FIFO (
    .clk        (clk                    ),
    .rst_n      (rst_n                  ),
    .data_i     (softmax_FIFO_din       ),
    .data_o     (softmax_FIFO_dout      ),
    .wr_valid_i (softmax_FIFO_wr_valid  ),
    .rd_valid_i (softmax_FIFO_rd_valid  ),
    .empty_o    (softmax_FIFO_empty     ),
    .full_o     (softmax_FIFO_full      )
  );

  (* dont_touch = "yes" *)
  fifo #(
    .DATA_WIDTH (AGGR_WIDTH             ),
    .FIFO_DEPTH (20                     )
  ) u_aggregator_FIFO (
    .clk        (clk                    ),
    .rst_n      (rst_n                  ),
    .data_i     (aggr_FIFO_din          ),
    .data_o     (aggr_FIFO_dout         ),
    .wr_valid_i (aggr_FIFO_wr_valid     ),
    .rd_valid_i (aggr_FIFO_rd_valid     ),
    .empty_o    (aggr_FIFO_empty        ),
    .full_o     (aggr_FIFO_full         )
  );
  //* ==========================================================


  //* ======================== scheduler =======================
  localparam MULT_WEIGHT_ADDR_W  = $clog2(W_NUM_OF_ROWS);

  logic [0:W_NUM_OF_COLS-1] [MULT_WEIGHT_ADDR_W-1:0]  mult_weight_addrb   ;
  logic [0:W_NUM_OF_COLS-1] [DATA_WIDTH-1:0]          mult_weight_dout    ;
  logic                                               w_ready             ;
  logic [0:A_DEPTH-1] [DATA_WIDTH-1:0]                a                   ;
  logic                                               a_ready             ;

  scheduler u_scheduler (
    .clk                        (clk                        ),
    .rst_n                      (rst_n                      ),

    .Weight_BRAM_dout           (Weight_BRAM_dout           ),
    .Weight_BRAM_addrb          (Weight_BRAM_addrb          ),
    .Weight_BRAM_load_done      (Weight_BRAM_load_done      ),
    .mult_weight_addrb          (mult_weight_addrb          ),
    .mult_weight_dout           (mult_weight_dout           ),
    .w_ready_o                  (w_ready                    ),

    .a_BRAM_dout                (a_BRAM_dout                ),
    .a_BRAM_addrb               (a_BRAM_addrb               ),
    .a_BRAM_load_done           (a_BRAM_load_done           ),
    .a                          (a                          ),
    .a_ready_o                  (a_ready                    )
  );
  //* ==========================================================


  //* ========================== SPMM ==========================
  logic                           spmm_valid  ;
  logic [W_NUM_OF_COLS-1:0]       pe_ready    ;

  assign spmm_valid = (H_col_idx_BRAM_load_done && H_value_BRAM_load_done && H_node_info_BRAM_load_done && Weight_BRAM_load_done && w_ready);

  (* dont_touch = "yes" *)
  SPMM u_SPMM (
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

    .WH_1_BRAM_din              (WH_1_BRAM_din              ),
    .WH_1_BRAM_ena              (WH_1_BRAM_ena              ),
    .WH_1_BRAM_addra            (WH_1_BRAM_addra            ),

    .WH_2_BRAM_din              (WH_2_BRAM_din              ),
    .WH_2_BRAM_ena              (WH_2_BRAM_ena              ),
    .WH_2_BRAM_addra            (WH_2_BRAM_addra            )
  );
  //* ==========================================================


  //* ========================== DMVM ==========================
  logic                                       dmvm_valid      ;
  logic                                       dmvm_valid_reg  ;
  logic                                       dmvm_ready      ;
  logic [NUM_OF_NODES-1:0] [DATA_WIDTH-1:0]   coef            ;
  logic [COEF_W-1:0]                          coef_cat        ;
  logic [NUM_NODE_WIDTH-1:0]                  num_of_nodes    ;

  assign dmvm_valid = (&pe_ready) ? 1'b1 : dmvm_valid_reg;
  always @(posedge clk) begin
    if (!rst_n) begin
      dmvm_valid_reg <= 1'b0;
    end else begin
      dmvm_valid_reg <= dmvm_valid;
    end
  end

  (* dont_touch = "yes" *)
  DMVM u_DMVM (
    .clk              (clk              ),
    .rst_n            (rst_n            ),

    .dmvm_valid_i     (dmvm_valid_reg   ),
    .dmvm_ready_o     (dmvm_ready       ),

    .a_valid_i        (a_BRAM_load_done ),
    .a_i              (a                ),

    .WH_BRAM_dout     (WH_1_BRAM_dout   ),
    .WH_BRAM_addrb    (WH_1_BRAM_addrb  ),

    .coef_o           (coef             ),
    .num_of_nodes_o   (num_of_nodes     )
  );

  generate
    for (i = 0; i < NUM_OF_NODES; i = i + 1) begin
      assign coef_cat[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = coef[NUM_OF_NODES-1-i];
    end
  endgenerate
  //* ==========================================================


  //* ======================== Softmax =========================
  // -- BRAM logic
  coef_t                                            sm_data_i               ;
  // -- 1st data available
  logic                                             first_sm                ;
  logic                                             first_sm_reg            ;
  // -- I/O
  logic                                             sm_valid                ;
  logic                                             sm_valid_reg            ;
  logic                                             sm_pre_ready            ;
  logic                                             sm_ready                ;
  logic [NUM_NODE_WIDTH-1:0]                        sm_num_of_nodes_i       ;
  logic [NUM_NODE_WIDTH-1:0]                        sm_num_of_nodes_i_reg   ;
  logic [NUM_OF_NODES-1:0] [DATA_WIDTH-1:0]         sm_coef                 ;
  logic [NUM_OF_NODES-1:0] [DATA_WIDTH-1:0]         sm_coef_reg             ;
  logic [NUM_OF_NODES-1:0] [ALPHA_DATA_WIDTH-1:0]   alpha                   ;
  logic [ALPHA_W-1:0]                               alpha_cat               ;
  logic [NUM_NODE_WIDTH-1:0]                        sm_num_of_nodes_o       ;

  assign sm_data_i              = { coef_cat, num_of_nodes };
  assign softmax_FIFO_din       = sm_data_i;
  assign softmax_FIFO_wr_valid  = dmvm_ready;
  assign softmax_FIFO_rd_valid  = (first_sm && ~softmax_FIFO_empty) ? 1'b1 : (sm_pre_ready && ~softmax_FIFO_empty) ? 1'b1 : 1'b0;

  assign sm_num_of_nodes_i      = softmax_FIFO_rd_valid ? (softmax_FIFO_dout[NUM_NODE_WIDTH-1:0]) : sm_num_of_nodes_i_reg;
  generate
    for (i = 0; i < NUM_OF_NODES; i = i + 1) begin
      assign sm_coef[i] = softmax_FIFO_rd_valid ? (softmax_FIFO_dout[SOFTMAX_WIDTH-1-i*DATA_WIDTH : SOFTMAX_WIDTH-(i+1)*DATA_WIDTH]) : sm_coef_reg[i];
    end
  endgenerate

  always @(posedge clk) begin
    if (!rst_n) begin
      sm_coef_reg           <= '0;
      sm_num_of_nodes_i_reg <= 0;
    end else begin
      sm_coef_reg           <= sm_coef;
      sm_num_of_nodes_i_reg <= sm_num_of_nodes_i;
    end
  end

  // -- sm_valid
  assign first_sm = (sm_valid_reg == 1'b1) ? 1'b0 : first_sm_reg;
  always @(posedge clk) begin
    if (!rst_n) begin
      first_sm_reg <= 1'b1;
    end else begin
      first_sm_reg <= first_sm;
    end
  end

  always @(*) begin
    if (sm_valid_reg) begin
      sm_valid = 1'b0;
    end else if (softmax_FIFO_rd_valid) begin
      sm_valid = 1'b1;
    end else begin
      sm_valid = sm_valid_reg;
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      sm_valid_reg <= 1'b0;
    end else begin
      sm_valid_reg <= sm_valid;
    end
  end

  (* dont_touch = "yes" *)
  softmax u_softmax (
    .clk            (clk                    ),
    .rst_n          (rst_n                  ),
    .sm_valid_i     (sm_valid_reg           ),
    .sm_pre_ready_o (sm_pre_ready           ),
    .sm_ready_o     (sm_ready               ),
    .coef_i         (sm_coef_reg            ),
    .num_of_nodes   (sm_num_of_nodes_i_reg  ),
    .alpha_o        (alpha                  )
  );

  generate
    for (i = 0; i < NUM_OF_NODES; i = i + 1) begin
      assign alpha_cat[ALPHA_DATA_WIDTH*(i+1)-1-:ALPHA_DATA_WIDTH] = alpha[NUM_OF_NODES-1-i];
    end
  endgenerate
  //* ==========================================================


  //* ======================= Aggregator =======================
  // -- BRAM logic
  aggr_t                                            aggr_data_i             ;
  // -- 1st data available
  logic                                             first_aggr              ;
  logic                                             first_aggr_reg          ;

  logic                                             aggr_valid              ;
  logic                                             aggr_valid_reg          ;
  logic                                             aggr_ready              ;
  logic                                             aggr_pre_ready          ;
  logic [NUM_OF_NODES-1:0] [ALPHA_DATA_WIDTH-1:0]   aggr_alpha              ;
  logic [NUM_OF_NODES-1:0] [ALPHA_DATA_WIDTH-1:0]   aggr_alpha_reg          ;
  logic [NUM_NODE_WIDTH-1:0]                        aggr_num_of_nodes_i     ;
  logic [NUM_NODE_WIDTH-1:0]                        aggr_num_of_nodes_i_reg ;

  assign aggr_data_i            = { alpha_cat, sm_num_of_nodes_o };
  assign aggr_FIFO_din          = aggr_data_i;
  assign aggr_FIFO_wr_valid     = sm_ready;
  assign aggr_FIFO_rd_valid     = (first_aggr && ~aggr_FIFO_empty) ? 1'b1 : (aggr_pre_ready && ~aggr_FIFO_empty) ? 1'b1 : 1'b0;

  assign aggr_num_of_nodes_i  = aggr_FIFO_rd_valid ? (aggr_BRAM_dout[NUM_NODE_WIDTH-1:0]) : aggr_num_of_nodes_i_reg;
  generate
    for (i = 0; i < NUM_OF_NODES; i = i + 1) begin
      assign aggr_alpha[i] = aggr_FIFO_rd_valid ? (aggr_BRAM_dout[AGGR_WIDTH-1-i*ALPHA_DATA_WIDTH : AGGR_WIDTH-(i+1)*ALPHA_DATA_WIDTH]) : aggr_alpha_reg[i];
    end
  endgenerate

  always @(posedge clk) begin
    if (!rst_n) begin
      aggr_alpha_reg          <= '0;
      aggr_num_of_nodes_i_reg <= 0;
    end else begin
      aggr_alpha_reg          <= aggr_alpha;
      aggr_num_of_nodes_i_reg <= aggr_num_of_nodes_i;
    end
  end

  // -- aggr_valid
  assign first_aggr = (aggr_valid_reg == 1'b1) ? 1'b0 : first_aggr_reg;
  always @(posedge clk) begin
    if (!rst_n) begin
      first_aggr_reg <= 1'b1;
    end else begin
      first_aggr_reg <= first_aggr;
    end
  end

  always @(*) begin
    if (aggr_valid_reg) begin
      aggr_valid = 1'b0;
    end else if (aggr_FIFO_rd_valid) begin
      aggr_valid = 1'b1;
    end else begin
      aggr_valid = aggr_valid_reg;
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      aggr_valid_reg <= 1'b0;
    end else begin
      aggr_valid_reg <= aggr_valid;
    end
  end

  aggregator u_aggregator (
    .clk              (clk                      ),
    .rst_n            (rst_n                    ),

    .aggr_valid_i     (aggr_valid_reg           ),
    .aggr_ready_o     (aggr_ready               ),
    .aggr_pre_ready_o (aggr_pre_ready           ),

    .WH_BRAM_doutb    (WH_2_BRAM_dout           ),
    .WH_BRAM_addrb    (WH_2_BRAM_addrb          ),
    .num_of_nodes     (aggr_num_of_nodes_i_reg  ),

    .alpha_i          (aggr_alpha_reg           )
  );
  //* ==========================================================
endmodule