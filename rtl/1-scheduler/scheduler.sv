module scheduler #(
  //* ========== parameter ===========
  parameter DATA_WIDTH          = 8,
  parameter WH_DATA_WIDTH       = 12,
  parameter DMVM_DATA_WIDTH     = 20,
  parameter SM_DATA_WIDTH       = 103,
  parameter SM_SUM_DATA_WIDTH   = 103,
  // -- H
  parameter H_NUM_OF_ROWS       = 13264,
  parameter H_NUM_OF_COLS       = 1433,
  // -- W
  parameter W_NUM_OF_ROWS       = 1433,
  parameter W_NUM_OF_COLS       = 16,
  // -- BRAM
  parameter COL_IDX_DEPTH       = 242101,
  parameter VALUE_DEPTH         = 242101,
  parameter NODE_INFO_DEPTH     = 13264,
  parameter WEIGHT_DEPTH        = 1433 * 16,
  parameter WH_DEPTH            = 13264,
  parameter A_DEPTH             = 2 * 16,
  // -- NUM_OF_NODES
  parameter NUM_OF_NODES        = 168,

  //* ========= localparams ==========
  // -- col_idx
  parameter COL_IDX_WIDTH       = $clog2(H_NUM_OF_COLS),
  parameter COL_IDX_ADDR_W      = $clog2(COL_IDX_DEPTH),
  // -- value
  parameter VALUE_WIDTH         = DATA_WIDTH,
  parameter VALUE_ADDR_W        = $clog2(VALUE_DEPTH),
  // -- node_info = [row_len, num_nodes, flag]
  parameter ROW_LEN_WIDTH       = $clog2(H_NUM_OF_COLS),
  parameter NUM_NODE_WIDTH      = $clog2(NUM_OF_NODES),
  parameter NODE_INFO_WIDTH     = ROW_LEN_WIDTH + NUM_NODE_WIDTH + 1,
  parameter NODE_INFO_ADDR_W    = $clog2(NODE_INFO_DEPTH),
  // -- Weight
  parameter WEIGHT_ADDR_W       = $clog2(WEIGHT_DEPTH),
  parameter MULT_WEIGHT_ADDR_W  = $clog2(W_NUM_OF_ROWS),
  // -- WH_BRAM
  parameter WH_WIDTH            = WH_DATA_WIDTH * W_NUM_OF_COLS + NUM_NODE_WIDTH + 1,
  parameter WH_ADDR_W           = $clog2(WH_DEPTH),
  // -- a
  parameter A_ADDR_W            = $clog2(A_DEPTH),
  // -- softmax
  parameter SOFTMAX_WIDTH       = NUM_OF_NODES * DATA_WIDTH + NUM_NODE_WIDTH,
  parameter SOFTMAX_DEPTH       = 2708,
  parameter SOFTMAX_ADDR_W      = $clog2(SOFTMAX_DEPTH),

  parameter NUM_NODES_W         = $clog2(NUM_OF_NODES),
  parameter COEF_W              = DATA_WIDTH * NUM_OF_NODES
)(
  input                             clk                         ,
  input                             rst_n                       ,

  // -- H_col_idx BRAM
  input   [COL_IDX_WIDTH-1:0]       H_col_idx_BRAM_dout         ,
  output  [COL_IDX_ADDR_W-1:0]      H_col_idx_BRAM_addrb        ,
  input                             H_col_idx_BRAM_load_done    ,
  // -- H_value BRAM
  input   [VALUE_WIDTH-1:0]         H_value_BRAM_dout           ,
  output  [VALUE_ADDR_W-1:0]        H_value_BRAM_addrb          ,
  input                             H_value_BRAM_load_done      ,
  // -- H_node_info BRAM
  input   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout       ,
  input   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout_nxt   ,
  output  [NODE_INFO_ADDR_W-1:0]    H_node_info_BRAM_addrb      ,
  input                             H_node_info_BRAM_load_done  ,
  // -- Weight BRAM
  input   [DATA_WIDTH-1:0]          Weight_BRAM_dout            ,
  output  [WEIGHT_ADDR_W-1:0]       Weight_BRAM_addrb           ,
  input                             Weight_BRAM_load_done       ,
  // -- a BRAM
  input   [DATA_WIDTH-1:0]          a_BRAM_dout                 ,
  output  [A_ADDR_W-1:0]            a_BRAM_addrb                ,
  input                             a_BRAM_load_done            ,
  // -- WH BRAM
  output  [WH_WIDTH-1:0]            WH_BRAM_din                 ,
  output                            WH_BRAM_ena                 ,
  output                            WH_BRAM_wea                 ,
  output  [WH_ADDR_W-1:0]           WH_BRAM_addra               ,
  input   [WH_WIDTH-1:0]            WH_BRAM_doutb               ,
  input   [WH_WIDTH-1:0]            WH_BRAM_doutc               ,
  output  [WH_ADDR_W-1:0]           WH_BRAM_addrb
);
  typedef struct packed {
    bit [DATA_WIDTH-1:0]      coef_1          ;
    bit [DATA_WIDTH-1:0]      coef_2          ;
    bit [DATA_WIDTH-1:0]      coef_3          ;
    bit [DATA_WIDTH-1:0]      coef_4          ;
    bit [DATA_WIDTH-1:0]      coef_5          ;
    bit [DATA_WIDTH-1:0]      coef_6          ;
    bit [NUM_NODE_WIDTH-1:0]  num_of_nodes    ;
  } coef_t;

  //* ======== internal declaration =========
  logic [NUM_NODES_W-1:0]         num_of_nodes                                ;
  logic                           h_ready                                     ;

  // -- W_loader
  logic [MULT_WEIGHT_ADDR_W-1:0]  mult_weight_addrb   [0:W_NUM_OF_COLS-1]     ;
  logic [DATA_WIDTH-1:0]          mult_weight_dout    [0:W_NUM_OF_COLS-1]     ;
  logic                           w_ready                                     ;

  // -- a_loader
  logic [DATA_WIDTH-1:0]          a                   [0:A_DEPTH-1]           ;
  logic                           a_ready                                     ;

  // -- SPMM
  logic                           spmm_valid                                  ;
  logic [W_NUM_OF_COLS-1:0]       pe_ready                                    ;

  // -- DMVM
  logic                           dmvm_valid                                  ;
  logic                           dmvm_valid_reg                              ;
  logic                           dmvm_ready                                  ;
  logic [DATA_WIDTH-1:0]          coef                [0:NUM_OF_NODES-1]      ;
  logic [COEF_W-1:0]              coef_cat                                    ;

  // -- softmax
  logic [SOFTMAX_WIDTH-1:0]       softmax_BRAM_din                            ;
  logic                           softmax_BRAM_ena                            ;
  logic [SOFTMAX_ADDR_W-1:0]      softmax_BRAM_addra                          ;
  logic [SOFTMAX_WIDTH-1:0]       softmax_BRAM_dout                           ;
  logic [SOFTMAX_ADDR_W-1:0]      softmax_BRAM_addrb                          ;

  logic                           first_sm;
  logic                           first_sm_reg;

  logic [SOFTMAX_ADDR_W-1:0]      sm_addra                                    ;
  logic [SOFTMAX_ADDR_W-1:0]      sm_addra_reg                                ;
  coef_t                          sm_data_i                                   ;
  coef_t                          sm_data_o                                   ;
  logic [SOFTMAX_ADDR_W-1:0]      sm_addrb                                    ;
  logic [SOFTMAX_ADDR_W-1:0]      sm_addrb_reg                                ;

  logic                           sm_valid                                    ;
  logic                           sm_valid_reg                                ;
  logic                           sm_ready                                    ;
  logic                           sm_pre_ready                                ;
  logic                           sm_ready                                    ;
  logic [NUM_NODE_WIDTH-1:0]      sm_num_of_nodes                             ;
  logic [DATA_WIDTH-1:0]          sm_coef             [0:NUM_OF_NODES-1]      ;
  //* =======================================

  genvar i;

  //* ======================== W_loader ========================
  W_loader #(
    .DATA_WIDTH       (DATA_WIDTH       ),
    .W_NUM_OF_COLS    (W_NUM_OF_COLS    ),
    .W_NUM_OF_ROWS    (W_NUM_OF_ROWS    )
  ) u_W_loader (
    .clk                      (clk                    ),
    .rst_n                    (rst_n                  ),

    .w_valid_i                (Weight_BRAM_load_done  ),
    .w_ready_o                (w_ready                ),

    .Weight_BRAM_dout         (Weight_BRAM_dout       ),
    .Weight_BRAM_enb          (Weight_BRAM_enb        ),
    .Weight_BRAM_addrb        (Weight_BRAM_addrb      ),

    .mult_weight_addrb        (mult_weight_addrb      ),
    .mult_weight_dout         (mult_weight_dout       )
  );
  //* ==========================================================


  //* ======================== a_loader ========================
  a_loader #(
    .DATA_WIDTH       (DATA_WIDTH       ),
    .A_ADDR_W         (A_ADDR_W         ),
    .A_DEPTH          (A_DEPTH          )
  ) u_a_loader (
    .clk              (clk                    ),
    .rst_n            (rst_n                  ),

    .a_valid_i        (a_BRAM_load_done       ),
    .a_ready_o        (a_ready                ),

    .a_BRAM_dout      (a_BRAM_dout            ),
    .a_BRAM_enb       (a_BRAM_enb             ),
    .a_BRAM_addrb     (a_BRAM_addrb           ),

    .a_o              (a                      )
  );
  //* ==========================================================


  //* ========================== SPMM ==========================
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
  assign dmvm_valid = (&pe_ready) ? 1'b1 : dmvm_valid_reg;
  always @(posedge clk) begin
    if (!rst_n) begin
      dmvm_valid_reg <= 1'b0;
    end else begin
      dmvm_valid_reg <= dmvm_valid;
    end
  end

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
  BRAM #(
    .DATA_WIDTH   (SOFTMAX_WIDTH    ),
    .DEPTH        (SOFTMAX_DEPTH    ),
    .CLK_LATENCY  (1                )
  ) u_softmax_BRAM (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (softmax_BRAM_din     ),
    .addra        (softmax_BRAM_addra   ),
    .ena          (softmax_BRAM_ena     ),
    .addrb        (softmax_BRAM_addrb   ),
    .dout         (softmax_BRAM_dout    )
  );

  // -- BRAM addr logic
  always @(*) begin
    sm_addra = sm_addra_reg;
    sm_addrb = sm_addrb_reg;

    if (dmvm_ready) begin
      if (sm_addra_reg < 19) begin
        sm_addra = sm_addra_reg + 1;
      end else begin
        sm_addra = 0;
      end
    end

    if (sm_pre_ready) begin
      if (sm_addrb_reg < 19) begin
        sm_addrb = sm_addrb_reg + 1;
      end else begin
        sm_addrb = 0;
      end
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      sm_addra_reg <= 0;
      sm_addrb_reg <= 0;
    end else begin
      sm_addra_reg <= sm_addra;
      sm_addrb_reg <= sm_addrb;
    end
  end

  // -- Write to BRAM
  assign sm_data_i          = { coef_cat, num_of_nodes };
  assign softmax_BRAM_din   = sm_data_i;
  assign softmax_BRAM_ena   = dmvm_ready;
  assign softmax_BRAM_addra = sm_addra_reg;

  // -- Read from BRAM
  assign softmax_BRAM_addrb = sm_addrb_reg;
  assign sm_num_of_nodes    = softmax_BRAM_dout[NUM_NODES_W-1:0];
  generate
    for (i = 0; i < NUM_OF_NODES; i = i + 1) begin
      assign sm_coef[i] = softmax_BRAM_dout[SOFTMAX_WIDTH-1-i*DATA_WIDTH : SOFTMAX_WIDTH-(i+1)*DATA_WIDTH];
    end
  endgenerate

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
    end else if ((softmax_BRAM_addra > 0) && (softmax_BRAM_addra > softmax_BRAM_addrb) && ~sm_valid_reg && ((sm_ready && softmax_BRAM_addrb >= 0) || (softmax_BRAM_addrb == 0 && first_sm_reg))) begin
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

  softmax #(
    .DATA_WIDTH         (DATA_WIDTH         ),
    .SM_DATA_WIDTH      (SM_DATA_WIDTH      ),
    .SM_SUM_DATA_WIDTH  (SM_SUM_DATA_WIDTH  ),
    .MAX_NODES          (NUM_OF_NODES       )
  ) u_softmax (
    .clk            (clk              ),
    .rst_n          (rst_n            ),
    .sm_valid_i     (sm_valid_reg     ),
    .sm_pre_ready_o (sm_pre_ready     ),
    .sm_ready_o     (sm_ready         ),
    .coef_i         (sm_coef          ),
    .num_of_nodes   (sm_num_of_nodes  )
  );
  //* ==========================================================
endmodule


