`include "./others/pkgs/parameters.vh"

module top_v (
  input                             clk                         ,
  input                             rst_n                       ,

  input   [H_DATA_WIDTH-1:0]        H_data_BRAM_din             ,
  input                             H_data_BRAM_ena             ,
  input   [H_DATA_ADDR_W-1:0]       H_data_BRAM_addra           ,
  output  [H_DATA_ADDR_W-1:0]       H_data_BRAM_addrb           ,
  input                             H_data_BRAM_load_done       ,

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
  wire [H_DATA_WIDTH-1:0]        H_data_BRAM_dout            ;
  wire [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout       ;
  wire [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout_nxt   ;
  wire [DATA_WIDTH-1:0]          Weight_BRAM_dout            ;
  wire [DATA_WIDTH-1:0]          a_BRAM_dout                 ;

  wire [WH_WIDTH-1:0]            WH_1_BRAM_din               ;
  wire                           WH_1_BRAM_ena               ;
  wire [WH_1_ADDR_W-1:0]         WH_1_BRAM_addra             ;
  wire [WH_1_ADDR_W-1:0]         WH_1_BRAM_addrb             ;
  wire [WH_WIDTH-1:0]            WH_1_BRAM_dout              ;

  wire [WH_WIDTH-1:0]            WH_2_BRAM_din               ;
  wire                           WH_2_BRAM_ena               ;
  wire [WH_2_ADDR_W-1:0]         WH_2_BRAM_addra             ;
  wire [WH_2_ADDR_W-1:0]         WH_2_BRAM_addrb             ;
  wire [WH_WIDTH-1:0]            WH_2_BRAM_dout              ;

  wire [SOFTMAX_WIDTH-1:0]       softmax_FIFO_din            ;
  wire [SOFTMAX_WIDTH-1:0]       softmax_FIFO_dout           ;
  wire                           softmax_FIFO_wr_valid       ;
  wire                           softmax_FIFO_rd_valid       ;
  wire                           softmax_FIFO_empty          ;
  wire                           softmax_FIFO_full           ;

  wire [AGGR_WIDTH-1:0]          aggr_FIFO_din               ;
  wire [AGGR_WIDTH-1:0]          aggr_FIFO_dout              ;
  wire                           aggr_FIFO_wr_valid          ;
  wire                           aggr_FIFO_rd_valid          ;
  wire                           aggr_FIFO_empty             ;
  wire                           aggr_FIFO_full              ;

  wire [AGGR_WIDTH-1:0]          aggr_BRAM_din               ;
  wire                           aggr_BRAM_ena               ;
  wire [AGGR_ADDR_W-1:0]         aggr_BRAM_addra             ;
  wire [AGGR_WIDTH-1:0]          aggr_BRAM_dout              ;
  wire [AGGR_ADDR_W-1:0]         aggr_BRAM_addrb             ;

  genvar i;

  //* ==================== Memory Controller ===================
  mem_ctrl u_mem_ctrl (
    .H_data_BRAM_din            (H_data_BRAM_din            ),
    .H_data_BRAM_ena            (H_data_BRAM_ena            ),
    .H_data_BRAM_addra          (H_data_BRAM_addra          ),
    .H_data_BRAM_dout           (H_data_BRAM_dout           ),
    .H_data_BRAM_addrb          (H_data_BRAM_addrb          ),

    .H_node_info_BRAM_din       (H_node_info_BRAM_din       ),
    .H_node_info_BRAM_ena       (H_node_info_BRAM_ena       ),
    .H_node_info_BRAM_addra     (H_node_info_BRAM_addra     ),
    .H_node_info_BRAM_dout      (H_node_info_BRAM_dout      ),
    .H_node_info_BRAM_dout_nxt  (H_node_info_BRAM_dout_nxt  ),
    .H_node_info_BRAM_addrb     (H_node_info_BRAM_addrb     ),

    .Weight_BRAM_din            (Weight_BRAM_din            ),
    .Weight_BRAM_ena            (Weight_BRAM_ena            ),
    .Weight_BRAM_addra          (Weight_BRAM_addra          ),
    .Weight_BRAM_dout           (Weight_BRAM_dout           ),
    .Weight_BRAM_addrb          (Weight_BRAM_addrb          ),

    .a_BRAM_din                 (a_BRAM_din                 ),
    .a_BRAM_ena                 (a_BRAM_ena                 ),
    .a_BRAM_addra               (a_BRAM_addra               ),
    .a_BRAM_dout                (a_BRAM_dout                ),
    .a_BRAM_addrb               (a_BRAM_addrb               ),

    .WH_1_BRAM_din              (WH_1_BRAM_din              ),
    .WH_1_BRAM_ena              (WH_1_BRAM_ena              ),
    .WH_1_BRAM_addra            (WH_1_BRAM_addra            ),
    .WH_1_BRAM_dout             (WH_1_BRAM_dout             ),
    .WH_1_BRAM_addrb            (WH_1_BRAM_addrb            ),
    .WH_1_BRAM_dout             (WH_1_BRAM_dout             ),

    .WH_2_BRAM_din              (WH_2_BRAM_din              ),
    .WH_2_BRAM_ena              (WH_2_BRAM_ena              ),
    .WH_2_BRAM_addra            (WH_2_BRAM_addra            ),
    .WH_2_BRAM_dout             (WH_2_BRAM_dout             ),
    .WH_2_BRAM_addrb            (WH_2_BRAM_addrb            ),
    .WH_2_BRAM_dout             (WH_2_BRAM_dout             )
  );
  //* ==========================================================


  //* ======================== scheduler =======================
  wire [W_NUM_OF_COLS*MULT_WEIGHT_ADDR_W-1:0]   mult_weight_addrb   ;
  wire [W_NUM_OF_COLS*DATA_WIDTH-1:0]           mult_weight_dout    ;
  wire                                          w_ready             ;
  wire [A_DEPTH*DATA_WIDTH-1:0]                 a                   ;
  wire                                          a_ready             ;

  (* dont_touch = "yes" *)
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
  wire                       spmm_valid  ;
  wire [W_NUM_OF_COLS-1:0]   pe_ready    ;

  assign spmm_valid = (H_data_BRAM_load_done && H_node_info_BRAM_load_done && Weight_BRAM_load_done && w_ready);

  (* dont_touch = "yes" *)
  SPMM u_SPMM (
    .clk                        (clk                        ),
    .rst_n                      (rst_n                      ),

    .H_data_BRAM_dout           (H_data_BRAM_dout           ),
    .H_data_BRAM_addrb          (H_data_BRAM_addrb          ),

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
  wire                                       dmvm_valid      ;
  reg                                        dmvm_valid_reg  ;
  wire                                       dmvm_ready      ;
  wire [MAX_NODES-1:0] [DATA_WIDTH-1:0]      coef            ;
  wire [COEF_W-1:0]                          coef_cat        ;
  wire [NUM_NODE_WIDTH-1:0]                  num_of_nodes    ;

  assign dmvm_valid = (&pe_ready) ? 1'b1 : dmvm_valid_reg;

  always @(posedge clk or negedge rst_n) begin
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
    for (i = 0; i < MAX_NODES; i = i + 1) begin
      assign coef_cat[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = coef[MAX_NODES-1-i];
    end
  endgenerate
  //* ==========================================================


  //* ======================== Softmax =========================
  // -- BRAM logic
  wire [COEF_W+NUM_NODE_WIDTH-1:0]                 sm_data_i               ;
  // -- 1st data available
  wire                                             first_sm                ;
  reg                                              first_sm_reg            ;
  // -- I/O
  reg                                              sm_valid                ;
  reg                                              sm_valid_reg            ;
  wire                                             sm_pre_ready            ;
  wire                                             sm_ready                ;
  wire [NUM_NODE_WIDTH-1:0]                        sm_num_of_nodes_i       ;
  reg  [NUM_NODE_WIDTH-1:0]                        sm_num_of_nodes_i_reg   ;
  wire [MAX_NODES-1:0] [DATA_WIDTH-1:0]            sm_coef                 ;
  reg  [MAX_NODES-1:0] [DATA_WIDTH-1:0]            sm_coef_reg             ;
  wire [MAX_NODES-1:0] [ALPHA_DATA_WIDTH-1:0]      alpha                   ;
  wire [ALPHA_W-1:0]                               alpha_cat               ;
  wire [NUM_NODE_WIDTH-1:0]                        sm_num_of_nodes_o       ;

  assign sm_data_i              = { coef_cat, num_of_nodes };
  assign softmax_FIFO_din       = sm_data_i;
  assign softmax_FIFO_wr_valid  = dmvm_ready;
  assign softmax_FIFO_rd_valid  = (first_sm && ~softmax_FIFO_empty) ? 1'b1 : (sm_pre_ready && ~softmax_FIFO_empty) ? 1'b1 : 1'b0;

  assign sm_num_of_nodes_i      = softmax_FIFO_rd_valid ? (softmax_FIFO_dout[NUM_NODE_WIDTH-1:0]) : sm_num_of_nodes_i_reg;
  generate
    for (i = 0; i < MAX_NODES; i = i + 1) begin
      assign sm_coef[i] = softmax_FIFO_rd_valid ? (softmax_FIFO_dout[SOFTMAX_WIDTH-1-i*DATA_WIDTH : SOFTMAX_WIDTH-(i+1)*DATA_WIDTH]) : sm_coef_reg[i];
    end
  endgenerate

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sm_coef_reg           <= 0;
      sm_num_of_nodes_i_reg <= 0;
    end else begin
      sm_coef_reg           <= sm_coef;
      sm_num_of_nodes_i_reg <= sm_num_of_nodes_i;
    end
  end

  // -- sm_valid
  assign first_sm = (sm_valid_reg == 1'b1) ? 1'b0 : first_sm_reg;
  always @(posedge clk or negedge rst_n) begin
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

  always @(posedge clk or negedge rst_n) begin
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
    for (i = 0; i < MAX_NODES; i = i + 1) begin
      assign alpha_cat[ALPHA_DATA_WIDTH*(i+1)-1-:ALPHA_DATA_WIDTH] = alpha[MAX_NODES-1-i];
    end
  endgenerate
  //* ==========================================================


  //* ======================= Aggregator =======================
  // -- BRAM logic
  wire [AGGR_WIDTH-1:0]                            aggr_data_i             ;
  // -- 1st data available
  wire                                             first_aggr              ;
  reg                                              first_aggr_reg          ;

  reg                                              aggr_valid              ;
  reg                                              aggr_valid_reg          ;
  wire                                             aggr_ready              ;
  wire                                             aggr_pre_ready          ;
  wire [MAX_NODES-1:0] [ALPHA_DATA_WIDTH-1:0]      aggr_alpha              ;
  reg  [MAX_NODES-1:0] [ALPHA_DATA_WIDTH-1:0]      aggr_alpha_reg          ;
  wire [NUM_NODE_WIDTH-1:0]                        aggr_num_of_nodes_i     ;
  reg  [NUM_NODE_WIDTH-1:0]                        aggr_num_of_nodes_i_reg ;

  assign aggr_data_i            = { alpha_cat, sm_num_of_nodes_o };
  assign aggr_FIFO_din          = aggr_data_i;
  assign aggr_FIFO_wr_valid     = sm_ready;
  assign aggr_FIFO_rd_valid     = (first_aggr && ~aggr_FIFO_empty) ? 1'b1 : (aggr_pre_ready && ~aggr_FIFO_empty) ? 1'b1 : 1'b0;

  assign aggr_num_of_nodes_i  = aggr_FIFO_rd_valid ? (aggr_BRAM_dout[NUM_NODE_WIDTH-1:0]) : aggr_num_of_nodes_i_reg;
  generate
    for (i = 0; i < MAX_NODES; i = i + 1) begin
      assign aggr_alpha[i] = aggr_FIFO_rd_valid ? (aggr_BRAM_dout[AGGR_WIDTH-1-i*ALPHA_DATA_WIDTH : AGGR_WIDTH-(i+1)*ALPHA_DATA_WIDTH]) : aggr_alpha_reg[i];
    end
  endgenerate

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      aggr_alpha_reg          <= 0;
      aggr_num_of_nodes_i_reg <= 0;
    end else begin
      aggr_alpha_reg          <= aggr_alpha;
      aggr_num_of_nodes_i_reg <= aggr_num_of_nodes_i;
    end
  end

  // -- aggr_valid
  assign first_aggr = (aggr_valid_reg == 1'b1) ? 1'b0 : first_aggr_reg;
  always @(posedge clk or negedge rst_n) begin
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

  always @(posedge clk or negedge rst_n) begin
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