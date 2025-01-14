`include "./../inc/gat_pkg.sv"

module gat_top import gat_pkg::*;
(
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

  input   [DATA_WIDTH-1:0]          weight_BRAM_din             ,
  input                             weight_BRAM_ena             ,
  input   [WEIGHT_ADDR_W-1:0]       weight_BRAM_addra           ,
  output  [WEIGHT_ADDR_W-1:0]       weight_BRAM_addrb           ,
  input                             weight_BRAM_load_done       ,

  input   [DATA_WIDTH-1:0]          a_BRAM_din                  ,
  input                             a_BRAM_ena                  ,
  input   [A_ADDR_W-1:0]            a_BRAM_addra                ,
  output  [A_ADDR_W-1:0]            a_BRAM_addrb                ,
  input                             a_BRAM_load_done            ,

  input   [NEW_FEATURE_ADDR_W-1:0]  feature_BRAM_addrb          ,
  output  [DATA_WIDTH-1:0]          feature_BRAM_dout
);
  logic   [H_DATA_WIDTH-1:0]        H_data_BRAM_dout            ;
  logic   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout       ;
  logic   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout_nxt   ;
  logic   [DATA_WIDTH-1:0]          weight_BRAM_dout            ;
  logic   [DATA_WIDTH-1:0]          a_BRAM_dout                 ;

  logic   [WH_WIDTH-1:0]            WH_BRAM_din                 ;
  logic                             WH_BRAM_ena                 ;
  logic   [WH_ADDR_W-1:0]           WH_BRAM_addra               ;
  logic   [WH_ADDR_W-1:0]           WH_BRAM_addrb               ;
  logic   [WH_WIDTH-1:0]            WH_BRAM_dout                ;

  logic   [NUM_NODE_WIDTH-1:0]      num_node_BRAM_din           ;
  logic                             num_node_BRAM_ena           ;
  logic   [NUM_NODE_ADDR_W-1:0]     num_node_BRAM_addra         ;
  logic   [NUM_NODE_ADDR_W-1:0]     num_node_BRAM_addrb         ;
  logic   [NUM_NODE_WIDTH-1:0]      num_node_BRAM_doutb         ;
  logic   [NUM_NODE_ADDR_W-1:0]     num_node_BRAM_addrc         ;
  logic   [NUM_NODE_WIDTH-1:0]      num_node_BRAM_doutc         ;

  logic   [DATA_WIDTH-1:0]          coef_FIFO_din               ;
  logic                             coef_FIFO_wr_vld            ;
  logic   [DATA_WIDTH-1:0]          coef_FIFO_dout              ;
  logic                             coef_FIFO_rd_vld            ;
  logic                             coef_FIFO_empty             ;
  logic                             coef_FIFO_full              ;

  logic   [ALPHA_DATA_WIDTH-1:0]    alpha_FIFO_din              ;
  logic                             alpha_FIFO_wr_vld           ;
  logic   [ALPHA_DATA_WIDTH-1:0]    alpha_FIFO_dout             ;
  logic                             alpha_FIFO_rd_vld           ;
  logic                             alpha_FIFO_empty            ;
  logic                             alpha_FIFO_full             ;

  logic   [NEW_FEATURE_WIDTH-1:0]   feature_BRAM_din            ;
  logic                             feature_BRAM_ena            ;
  logic   [NEW_FEATURE_ADDR_W-1:0]  feature_BRAM_addra          ;

  genvar i;

  //* ==================== Memory Controller ===================
  memory_controller u_memory_controller (.*);
  //* ==========================================================


  //* ======================== scheduler =======================
  logic [W_NUM_OF_COLS-1:0] [MULT_WEIGHT_ADDR_W-1:0]  mult_weight_addrb   ;
  logic [W_NUM_OF_COLS-1:0] [DATA_WIDTH-1:0]          mult_weight_dout    ;
  logic                                               w_ready             ;
  logic [A_DEPTH-1:0] [DATA_WIDTH-1:0]                a                   ;
  logic                                               a_ready             ;

  scheduler u_scheduler (
    .clk                        (clk                        ),
    .rst_n                      (rst_n                      ),

    .weight_BRAM_dout           (weight_BRAM_dout           ),
    .weight_BRAM_addrb          (weight_BRAM_addrb          ),
    .weight_BRAM_load_done      (weight_BRAM_load_done      ),
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
  logic                       spmm_valid  ;
  logic                       spmm_ready  ;
  logic [WH_WIDTH-1:0]        WH_data     ;

  assign spmm_valid = (H_data_BRAM_load_done && H_node_info_BRAM_load_done && weight_BRAM_load_done && w_ready);

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
    .spmm_ready_o               (spmm_ready                 ),

    .WH_data_o                  (WH_data                    ),

    .num_node_BRAM_addra        (num_node_BRAM_addra        ),
    .num_node_BRAM_ena          (num_node_BRAM_ena          ),
    .num_node_BRAM_din          (num_node_BRAM_din          ),

    .WH_BRAM_din                (WH_BRAM_din                ),
    .WH_BRAM_ena                (WH_BRAM_ena                ),
    .WH_BRAM_addra              (WH_BRAM_addra              )
  );
  //* ==========================================================


  //* ========================== DMVM ==========================
  logic dmvm_ready;

  DMVM u_DMVM (
    .clk                (clk                  ),
    .rst_n              (rst_n                ),

    .dmvm_valid_i       (spmm_ready           ),
    .dmvm_ready_o       (dmvm_ready           ),

    .a_valid_i          (a_BRAM_load_done     ),
    .a_i                (a                    ),

    .WH_data_i          (WH_data              ),

    .coef_FIFO_din      (coef_FIFO_din        ),
    .coef_FIFO_wr_vld   (coef_FIFO_wr_vld     ),
    .coef_FIFO_full     (coef_FIFO_full       )
  );
  //* ==========================================================


  //* ======================== Softmax =========================
  logic sm_ready;

  softmax u_softmax (
    .clk                  (clk                    ),
    .rst_n                (rst_n                  ),

    .sm_valid_i           (dmvm_ready             ),
    .sm_ready_o           (sm_ready               ),

    .coef_FIFO_dout       (coef_FIFO_dout         ),
    .coef_FIFO_empty      (coef_FIFO_empty        ),
    .coef_FIFO_rd_vld     (coef_FIFO_rd_vld       ),

    .num_node_BRAM_dout   (num_node_BRAM_doutb    ),
    .num_node_BRAM_addrb  (num_node_BRAM_addrb    ),

    .alpha_FIFO_din       (alpha_FIFO_din         ),
    .alpha_FIFO_full      (alpha_FIFO_full        ),
    .alpha_FIFO_wr_vld    (alpha_FIFO_wr_vld      )
  );
  //* ==========================================================


  //* ======================= Aggregator =======================
  logic aggr_ready;
  logic aggr_valid;
  logic aggr_valid_reg;

  assign aggr_valid = (sm_ready == 1'b1) ? 1'b1 : aggr_valid_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      aggr_valid_reg <= 0;
    end else begin
      aggr_valid_reg <= aggr_valid;
    end
  end

  aggregator u_aggregator (
    .clk                  (clk                      ),
    .rst_n                (rst_n                    ),

    .aggr_valid_i         (aggr_valid_reg           ),
    .aggr_ready_o         (aggr_ready               ),

    .WH_BRAM_dout         (WH_BRAM_dout             ),
    .WH_BRAM_addrb        (WH_BRAM_addrb            ),

    .alpha_FIFO_dout      (alpha_FIFO_dout          ),
    .alpha_FIFO_empty     (alpha_FIFO_empty         ),
    .alpha_FIFO_rd_vld    (alpha_FIFO_rd_vld        ),

    .feature_BRAM_addra   (feature_BRAM_addra       ),
    .feature_BRAM_din     (feature_BRAM_din         ),
    .feature_BRAM_ena     (feature_BRAM_ena         )
  );
  //* ==========================================================
endmodule