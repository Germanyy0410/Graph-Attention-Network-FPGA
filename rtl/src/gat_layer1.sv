module gat_layer1 import gat_pkg::*;
(
  input                             clk                         ,
  input                             rst_n                       ,

  input   [H_DATA_WIDTH-1:0]        h_data_bram_dout            ,
  output  [H_DATA_ADDR_W-1:0]       h_data_bram_addrb           ,

  input   [NODE_INFO_WIDTH-1:0]     h_node_info_bram_dout       ,
  input   [NODE_INFO_WIDTH-1:0]     h_node_info_bram_dout_nxt   ,
  output  [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addrb      ,

  input   [DATA_WIDTH-1:0]          wgt_bram_dout               ,
  output  [WEIGHT_ADDR_W-1:0]       wgt_bram_addrb              ,

  input   [DATA_WIDTH-1:0]          a_bram_dout                 ,
  output  [A_ADDR_W-1:0]            a_bram_addrb                ,

  input   [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addrb             ,
  output  [NEW_FEATURE_WIDTH-1:0]   feat_bram_dout

  output  [WH_WIDTH-1:0]            wh_bram_din                 ,
  output                            wh_bram_ena                 ,
  output  [WH_ADDR_W-1:0]           wh_bram_addra               ,
  output  [WH_ADDR_W-1:0]           wh_bram_addrb               ,
  input   [WH_WIDTH-1:0]            wh_bram_dout                ,

  output  [NUM_NODE_WIDTH-1:0]      num_node_bram_din           ,
  output                            num_node_bram_ena           ,
  output  [NUM_NODE_ADDR_W-1:0]     num_node_bram_addra         ,
  output  [NUM_NODE_ADDR_W-1:0]     num_node_bram_addrb         ,
  input   [NUM_NODE_WIDTH-1:0]      num_node_bram_doutb         ,
  output  [NUM_NODE_ADDR_W-1:0]     num_node_bram_addrc         ,
  input   [NUM_NODE_WIDTH-1:0]      num_node_bram_doutc         ,

  output  [DATA_WIDTH-1:0]          coef_ff_din                 ,
  output                            coef_ff_wr_vld              ,
  input   [DATA_WIDTH-1:0]          coef_ff_dout                ,
  output                            coef_ff_rd_vld              ,
  input                             coef_ff_empty               ,
  input                             coef_ff_full                ,

  output  [ALPHA_DATA_WIDTH-1:0]    alpha_ff_din                ,
  output                            alpha_ff_wr_vld             ,
  input   [ALPHA_DATA_WIDTH-1:0]    alpha_ff_dout               ,
  output                            alpha_ff_rd_vld             ,
  input                             alpha_ff_empty              ,
  input                             alpha_ff_full               ,

  output  [NEW_FEATURE_WIDTH-1:0]   feat_bram_din               ,
  output                            feat_bram_ena               ,
  output  [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addra
);

  genvar i;

  //* ======================= Scheduler ========================
  logic [W_NUM_OF_COLS-1:0] [MULT_WEIGHT_ADDR_W-1:0]  mult_wgt_addrb      ;
  logic [W_NUM_OF_COLS-1:0] [DATA_WIDTH-1:0]          mult_wgt_dout       ;
  logic                                               w_rdy               ;
  logic [A_DEPTH-1:0] [DATA_WIDTH-1:0]                a                   ;
  logic                                               a_rdy               ;

  scheduler u_scheduler (
    .clk                        (clk                        ),
    .rst_n                      (rst_n                      ),

    .wgt_bram_dout              (wgt_bram_dout              ),
    .wgt_bram_addrb             (wgt_bram_addrb             ),
    .wgt_bram_load_done         (wgt_bram_load_done         ),
    .mult_wgt_addrb             (mult_wgt_addrb             ),
    .mult_wgt_dout              (mult_wgt_dout              ),
    .w_rdy_o                    (w_rdy                      ),

    .a_bram_dout                (a_bram_dout                ),
    .a_bram_addrb               (a_bram_addrb               ),
    .a_bram_load_done           (a_bram_load_done           ),
    .a                          (a                          ),
    .a_rdy_o                    (a_rdy                      )
  );
  //* ==========================================================


  //* ========================== SPMM ==========================
  logic                       spmm_vld  ;
  logic                       spmm_rdy  ;
  logic [WH_WIDTH-1:0]        wh_data   ;

  assign spmm_vld = w_rdy;

  SPMM u_SPMM (
    .clk                        (clk                        ),
    .rst_n                      (rst_n                      ),

    .h_data_bram_dout           (h_data_bram_dout           ),
    .h_data_bram_addrb          (h_data_bram_addrb          ),

    .h_node_info_bram_dout      (h_node_info_bram_dout      ),
    .h_node_info_bram_dout_nxt  (h_node_info_bram_dout_nxt  ),
    .h_node_info_bram_addrb     (h_node_info_bram_addrb     ),

    .mult_wgt_addrb             (mult_wgt_addrb             ),
    .mult_wgt_dout              (mult_wgt_dout              ),

    .spmm_vld_i                 (spmm_vld                   ),
    .spmm_rdy_o                 (spmm_rdy                   ),

    .wh_data_o                  (wh_data                    ),

    .num_node_bram_addra        (num_node_bram_addra        ),
    .num_node_bram_ena          (num_node_bram_ena          ),
    .num_node_bram_din          (num_node_bram_din          ),

    .wh_bram_din                (wh_bram_din                ),
    .wh_bram_ena                (wh_bram_ena                ),
    .wh_bram_addra              (wh_bram_addra              )
  );
  //* ==========================================================


  //* ========================== DMVM ==========================
  logic dmvm_rdy;

  DMVM u_DMVM (
    .clk                (clk                  ),
    .rst_n              (rst_n                ),

    .dmvm_vld_i         (spmm_rdy             ),
    .dmvm_rdy_o         (dmvm_rdy             ),

    .a_vld_i            (a_bram_load_done     ),
    .a_i                (a                    ),

    .wh_data_i          (wh_data              ),

    .coef_ff_din        (coef_ff_din          ),
    .coef_ff_wr_vld     (coef_ff_wr_vld       ),
    .coef_ff_full       (coef_ff_full         )
  );
  //* ==========================================================


  //* ======================== Softmax =========================
  logic sm_rdy;

  softmax u_softmax (
    .clk                  (clk                    ),
    .rst_n                (rst_n                  ),

    .sm_vld_i             (dmvm_rdy               ),
    .sm_rdy_o             (sm_rdy                 ),

    .coef_ff_dout         (coef_ff_dout           ),
    .coef_ff_empty        (coef_ff_empty          ),
    .coef_ff_rd_vld       (coef_ff_rd_vld         ),

    .num_node_bram_dout   (num_node_bram_doutb    ),
    .num_node_bram_addrb  (num_node_bram_addrb    ),

    .alpha_ff_din         (alpha_ff_din           ),
    .alpha_ff_full        (alpha_ff_full          ),
    .alpha_ff_wr_vld      (alpha_ff_wr_vld        )
  );
  //* ==========================================================


  //* ======================= Aggregator =======================
  logic aggr_rdy;
  logic aggr_vld;
  logic aggr_vld_reg;

  assign aggr_vld = (sm_rdy == 1'b1) ? 1'b1 : aggr_vld_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      aggr_vld_reg <= 0;
    end else begin
      aggr_vld_reg <= aggr_vld;
    end
  end

  aggregator u_aggregator (
    .clk                  (clk                      ),
    .rst_n                (rst_n                    ),

    .aggr_vld_i           (aggr_vld_reg             ),
    .aggr_rdy_o           (aggr_rdy                 ),

    .wh_bram_dout         (wh_bram_dout             ),
    .wh_bram_addrb        (wh_bram_addrb            ),

    .alpha_ff_dout        (alpha_ff_dout            ),
    .alpha_ff_empty       (alpha_ff_empty           ),
    .alpha_ff_rd_vld      (alpha_ff_rd_vld          ),

    .feat_bram_addra      (feat_bram_addra          ),
    .feat_bram_din        (feat_bram_din            ),
    .feat_bram_ena        (feat_bram_ena            )
  );
  //* ==========================================================
endmodule