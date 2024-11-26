module top #(
  //* ========== parameter ===========
  parameter DATA_WIDTH        = 8,
  parameter WH_DATA_WIDTH     = 12,
  parameter DMVM_DATA_WIDTH   = 20,
  parameter SM_DATA_WIDTH     = 103,
  parameter SM_SUM_DATA_WIDTH = 103,
  parameter SM_OUT_DATA_WIDTH = 32,
  // -- H
  parameter H_NUM_OF_ROWS     = 13264,
  parameter H_NUM_OF_COLS     = 1433,
  // -- W
  parameter W_NUM_OF_ROWS     = 1433,
  parameter W_NUM_OF_COLS     = 16,
  // -- BRAM
  parameter COL_IDX_DEPTH     = 242101,
  parameter VALUE_DEPTH       = 242101,
  parameter NODE_INFO_DEPTH   = 13264,
  parameter WEIGHT_DEPTH      = 22928,
  parameter WH_DEPTH          = 13264,
  parameter A_DEPTH           = 32,
  // -- NUM_OF_NODES
  parameter NUM_OF_NODES      = 168,

  //* ========= localparams ==========
  // -- col_idx
  parameter COL_IDX_WIDTH     = $clog2(H_NUM_OF_COLS),
  parameter COL_IDX_ADDR_W    = $clog2(COL_IDX_DEPTH),
  // -- value
  parameter VALUE_WIDTH       = DATA_WIDTH,
  parameter VALUE_ADDR_W      = $clog2(VALUE_DEPTH),
  // -- node_info = [row_len, num_nodes, flag]
  parameter ROW_LEN_WIDTH     = $clog2(H_NUM_OF_COLS),
  parameter NUM_NODE_WIDTH    = $clog2(NUM_OF_NODES),
  parameter NODE_INFO_WIDTH   = ROW_LEN_WIDTH + NUM_NODE_WIDTH + 1,
  parameter NODE_INFO_ADDR_W  = $clog2(NODE_INFO_DEPTH),
  // -- Weight
  parameter WEIGHT_ADDR_W     = $clog2(WEIGHT_DEPTH),
  // -- WH_BRAM
  parameter WH_WIDTH          = WH_DATA_WIDTH * W_NUM_OF_COLS + NUM_NODE_WIDTH + 1,
  parameter WH_ADDR_W         = $clog2(WH_DEPTH),
  // -- a
  parameter A_ADDR_W          = $clog2(A_DEPTH),
  // -- Softmax
  parameter SOFTMAX_WIDTH     = NUM_OF_NODES * DATA_WIDTH + NUM_NODE_WIDTH,
  parameter SOFTMAX_DEPTH     = 2708,
  parameter SOFTMAX_ADDR_W    = $clog2(SOFTMAX_DEPTH),
  // -- DMVM
  parameter COEF_W            = DATA_WIDTH * NUM_OF_NODES,
  parameter ALPHA_W           = SM_OUT_DATA_WIDTH * NUM_OF_NODES,
  // -- Aggregator
  parameter AGGR_WIDTH        = NUM_OF_NODES * SM_OUT_DATA_WIDTH + NUM_NODE_WIDTH,
  parameter AGGR_DEPTH        = 2708,
  parameter AGGR_ADDR_W       = $clog2(AGGR_DEPTH)
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

  logic   [WH_WIDTH-1:0]            WH_BRAM_din                 ;
  logic                             WH_BRAM_ena                 ;
  logic   [WH_ADDR_W-1:0]           WH_BRAM_addra               ;
  logic   [WH_ADDR_W-1:0]           WH_BRAM_addrb               ;
  logic   [WH_WIDTH-1:0]            WH_BRAM_doutb               ;
  logic   [WH_ADDR_W-1:0]           WH_BRAM_addrc               ;
  logic   [WH_WIDTH-1:0]            WH_BRAM_doutc               ;

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

  typedef struct packed {
    bit [DATA_WIDTH-1:0]      coef_1;
    bit [DATA_WIDTH-1:0]      coef_2;
    bit [DATA_WIDTH-1:0]      coef_3;
    bit [DATA_WIDTH-1:0]      coef_4;
    bit [DATA_WIDTH-1:0]      coef_5;
    bit [DATA_WIDTH-1:0]      coef_6;
    bit [NUM_NODE_WIDTH-1:0]  num_of_nodes;
  } coef_t;

  typedef struct packed {
    bit [SM_OUT_DATA_WIDTH-1:0]   aggr_1;
    bit [SM_OUT_DATA_WIDTH-1:0]   aggr_2;
    bit [SM_OUT_DATA_WIDTH-1:0]   aggr_3;
    bit [SM_OUT_DATA_WIDTH-1:0]   aggr_4;
    bit [SM_OUT_DATA_WIDTH-1:0]   aggr_5;
    bit [SM_OUT_DATA_WIDTH-1:0]   aggr_6;
    bit [NUM_NODE_WIDTH-1:0]      num_of_nodes;
  } aggr_t;

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
    .FIFO_DEPTH (2                      )
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

  logic [MULT_WEIGHT_ADDR_W-1:0]  mult_weight_addrb   [0:W_NUM_OF_COLS-1] ;
  logic [DATA_WIDTH-1:0]          mult_weight_dout    [0:W_NUM_OF_COLS-1] ;
  logic                           w_ready                                 ;
  logic [DATA_WIDTH-1:0]          a                   [0:A_DEPTH-1]       ;
  logic                           a_ready                                 ;

  scheduler #(
    .DATA_WIDTH         (DATA_WIDTH         ),
    .W_NUM_OF_ROWS      (W_NUM_OF_ROWS      ),
    .W_NUM_OF_COLS      (W_NUM_OF_COLS      ),
    .WEIGHT_DEPTH       (WEIGHT_DEPTH       ),
    .A_DEPTH            (A_DEPTH            )
  ) u_scheduler (
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
  SPMM #(
    .DATA_WIDTH       (DATA_WIDTH       ),
    .WH_DATA_WIDTH    (WH_DATA_WIDTH    ),
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
  //* ==========================================================


  //* ========================== DMVM ==========================
  logic                           dmvm_valid                                  ;
  logic                           dmvm_valid_reg                              ;
  logic                           dmvm_ready                                  ;
  logic [DATA_WIDTH-1:0]          coef                [0:NUM_OF_NODES-1]      ;
  logic [COEF_W-1:0]              coef_cat                                    ;
  logic [NUM_NODE_WIDTH-1:0]      num_of_nodes                                ;

  assign dmvm_valid = (&pe_ready) ? 1'b1 : dmvm_valid_reg;
  always @(posedge clk) begin
    if (!rst_n) begin
      dmvm_valid_reg <= 1'b0;
    end else begin
      dmvm_valid_reg <= dmvm_valid;
    end
  end

  (* dont_touch = "yes" *)
  DMVM #(
    .DATA_WIDTH       (DATA_WIDTH       ),
    .WH_DATA_WIDTH    (WH_DATA_WIDTH    ),
    .DMVM_DATA_WIDTH  (DMVM_DATA_WIDTH  ),

    .A_DEPTH          (A_DEPTH          ),
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
  coef_t                          sm_data_i                                   ;
  // -- 1st data available
  logic                           first_sm;
  logic                           first_sm_reg;
  // -- I/O
  logic                           sm_valid                                    ;
  logic                           sm_valid_reg                                ;
  logic                           sm_pre_ready                                ;
  logic                           sm_ready                                    ;
  logic [NUM_NODE_WIDTH-1:0]      sm_num_of_nodes_i                           ;
  logic [NUM_NODE_WIDTH-1:0]      sm_num_of_nodes_i_reg                       ;
  logic [DATA_WIDTH-1:0]          sm_coef             [0:NUM_OF_NODES-1]      ;
  logic [DATA_WIDTH-1:0]          sm_coef_reg         [0:NUM_OF_NODES-1]      ;
  logic [SM_OUT_DATA_WIDTH-1:0]   alpha               [0:NUM_OF_NODES-1]      ;
  logic [ALPHA_W-1:0]             alpha_cat                                   ;
  logic [NUM_NODE_WIDTH-1:0]      sm_num_of_nodes_o                           ;

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

  generate
    for (i = 0; i < NUM_OF_NODES; i = i + 1) begin
      always @(posedge clk) begin
        if (!rst_n) begin
          sm_coef_reg[i] <= 0;
        end else begin
          sm_coef_reg[i] <= sm_coef[i];
        end
      end
    end
  endgenerate

  always @(posedge clk) begin
    if (!rst_n) begin
      sm_num_of_nodes_i_reg <= 0;
    end else begin
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
  softmax #(
    .DATA_WIDTH         (DATA_WIDTH         ),
    .SM_DATA_WIDTH      (SM_DATA_WIDTH      ),
    .SM_SUM_DATA_WIDTH  (SM_SUM_DATA_WIDTH  ),
    .OUT_DATA_WIDTH     (SM_OUT_DATA_WIDTH  ),
    .MAX_NODES          (NUM_OF_NODES       )
  ) u_softmax (
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
      assign alpha_cat[SM_OUT_DATA_WIDTH*(i+1)-1-:SM_OUT_DATA_WIDTH] = alpha[NUM_OF_NODES-1-i];
    end
  endgenerate
  //* ==========================================================


  //* ======================= Aggregator =======================
  // -- BRAM logic
  aggr_t                          aggr_data_i                                 ;
  // -- 1st data available
  logic                           first_aggr                                  ;
  logic                           first_aggr_reg                              ;

  logic                           aggr_valid                                  ;
  logic                           aggr_valid_reg                              ;
  logic                           aggr_ready                                  ;
  logic [SM_OUT_DATA_WIDTH-1:0]   aggr_alpha          [0:NUM_OF_NODES-1]      ;
  logic [SM_OUT_DATA_WIDTH-1:0]   aggr_alpha_reg      [0:NUM_OF_NODES-1]      ;
  logic [NUM_NODE_WIDTH-1:0]      aggr_num_of_nodes_i                         ;
  logic [NUM_NODE_WIDTH-1:0]      aggr_num_of_nodes_i_reg                     ;

  assign aggr_data_i            = { alpha_cat, sm_num_of_nodes_o };
  assign aggr_FIFO_din          = aggr_data_i;
  assign aggr_FIFO_wr_valid     = sm_ready;
  assign aggr_FIFO_rd_valid     = (first_aggr && ~aggr_FIFO_empty) ? 1'b1 : (aggr_pre_ready && ~aggr_FIFO_empty) ? 1'b1 : 1'b0;

  assign aggr_num_of_nodes_i  = aggr_FIFO_rd_valid ? (aggr_BRAM_dout[NUM_NODE_WIDTH-1:0]) : aggr_num_of_nodes_i_reg;
  generate
    for (i = 0; i < NUM_OF_NODES; i = i + 1) begin
      assign aggr_alpha[i] = aggr_FIFO_rd_valid ? (aggr_BRAM_dout[AGGR_WIDTH-1-i*SM_OUT_DATA_WIDTH : AGGR_WIDTH-(i+1)*SM_OUT_DATA_WIDTH]) : aggr_alpha_reg[i];
    end
  endgenerate

  generate
    for (i = 0; i < NUM_OF_NODES; i = i + 1) begin
      always @(posedge clk) begin
        if (!rst_n) begin
          aggr_alpha_reg[i] <= 0;
        end else begin
          aggr_alpha_reg[i] <= aggr_alpha[i];
        end
      end
    end
  endgenerate

  always @(posedge clk) begin
    if (!rst_n) begin
      aggr_num_of_nodes_i_reg <= 0;
    end else begin
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

  aggregator #(
    .DATA_WIDTH         (DATA_WIDTH         ),
    .WH_DATA_WIDTH      (WH_DATA_WIDTH      ),
    .ALPHA_DATA_WIDTH   (SM_OUT_DATA_WIDTH  ),
    .NUM_OF_NODES       (NUM_OF_NODES       )
  ) u_aggregator (
    .clk              (clk                      ),
    .rst_n            (rst_n                    ),

    .aggr_valid_i     (aggr_valid_reg           ),
    .aggr_ready_o     (aggr_ready               ),
    .aggr_pre_ready_o (aggr_pre_ready           ),

    .WH_BRAM_doutc    (WH_BRAM_doutc            ),
    .WH_BRAM_addrc    (WH_BRAM_addrc            ),
    .num_of_nodes     (aggr_num_of_nodes_i_reg  ),

    .alpha_i          (aggr_alpha_reg           )
  );
  //* ==========================================================
endmodule