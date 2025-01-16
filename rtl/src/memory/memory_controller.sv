// ==================================================================
// File name  : memory_controller.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   :
// -- Main memory between PS and PL
// -- Manage the initialization of FIFO & BRAM
// Author     : @Germanyy0410
// ==================================================================

module memory_controller import gat_pkg::*;
(
  input                             clk                         ,
  input                             rst_n                       ,

  input   [H_DATA_WIDTH-1:0]        h_data_bram_din             ,
  input                             h_data_bram_ena             ,
  input   [H_DATA_ADDR_W-1:0]       h_data_bram_addra           ,
  input   [H_DATA_ADDR_W-1:0]       h_data_bram_addrb           ,
  output  [H_DATA_WIDTH-1:0]        h_data_bram_dout            ,
  input                             h_data_bram_load_done       ,

  input   [NODE_INFO_WIDTH-1:0]     h_node_info_bram_din        ,
  input                             h_node_info_bram_ena        ,
  input   [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addra      ,
  input   [NODE_INFO_ADDR_W-1:0]    h_node_info_bram_addrb      ,
  output  [NODE_INFO_WIDTH-1:0]     h_node_info_bram_dout       ,
  output  [NODE_INFO_WIDTH-1:0]     h_node_info_bram_dout_nxt   ,
  input                             h_node_info_bram_load_done  ,

  input   [DATA_WIDTH-1:0]          wgt_bram_din                ,
  input                             wgt_bram_ena                ,
  input   [WEIGHT_ADDR_W-1:0]       wgt_bram_addra              ,
  input   [WEIGHT_ADDR_W-1:0]       wgt_bram_addrb              ,
  output  [DATA_WIDTH-1:0]          wgt_bram_dout               ,
  input                             wgt_bram_load_done          ,

  input   [DATA_WIDTH-1:0]          a_bram_din                  ,
  input                             a_bram_ena                  ,
  input   [A_ADDR_W-1:0]            a_bram_addra                ,
  input   [A_ADDR_W-1:0]            a_bram_addrb                ,
  output  [DATA_WIDTH-1:0]          a_bram_dout                 ,
  input                             a_bram_load_done            ,

  input   [WH_WIDTH-1:0]            wh_bram_din                 ,
  input                             wh_bram_ena                 ,
  input   [WH_ADDR_W-1:0]           wh_bram_addra               ,
  output  [WH_WIDTH-1:0]            wh_bram_dout                ,
  input   [WH_ADDR_W-1:0]           wh_bram_addrb               ,

  input   [NUM_NODE_WIDTH-1:0]      num_node_bram_din           ,
  input                             num_node_bram_ena           ,
  input   [NUM_NODE_ADDR_W-1:0]     num_node_bram_addra         ,
  input   [NUM_NODE_ADDR_W-1:0]     num_node_bram_addrb         ,
  output  [NUM_NODE_WIDTH-1:0]      num_node_bram_doutb         ,
  input   [NUM_NODE_ADDR_W-1:0]     num_node_bram_addrc         ,
  output  [NUM_NODE_WIDTH-1:0]      num_node_bram_doutc         ,

  input   [DATA_WIDTH-1:0]          coef_ff_din                 ,
  output                            coef_ff_empty               ,
  output                            coef_ff_full                ,
  input                             coef_ff_wr_vld              ,
  input                             coef_ff_rd_vld              ,
  output  [DATA_WIDTH-1:0]          coef_ff_dout                ,

  input   [ALPHA_DATA_WIDTH-1:0]    alpha_ff_din                ,
  output                            alpha_ff_empty              ,
  output                            alpha_ff_full               ,
  input                             alpha_ff_wr_vld             ,
  input                             alpha_ff_rd_vld             ,
  output  [ALPHA_DATA_WIDTH-1:0]    alpha_ff_dout               ,

  input   [DATA_WIDTH-1:0]          feat_bram_din               ,
  input                             feat_bram_ena               ,
  input   [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addra             ,
  output  [DATA_WIDTH-1:0]          feat_bram_dout              ,
  input   [NEW_FEATURE_ADDR_W-1:0]  feat_bram_addrb
);
  //* ========================= MEMORY =========================
  BRAM #(
    .DATA_WIDTH   (H_DATA_WIDTH         ),
    .DEPTH        (H_DATA_DEPTH         )
  ) u_h_data_bram (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (h_data_bram_din      ),
    .addra        (h_data_bram_addra    ),
    .ena          (h_data_bram_ena      ),
    .addrb        (h_data_bram_addrb    ),
    .dout         (h_data_bram_dout     )
  );

  modified_BRAM #(
    .DATA_WIDTH   (NODE_INFO_WIDTH            ),
    .DEPTH        (NODE_INFO_DEPTH            )
  ) u_h_node_info_bram (
    .clk          (clk                        ),
    .rst_n        (rst_n                      ),
    .din          (h_node_info_bram_din       ),
    .addra        (h_node_info_bram_addra     ),
    .ena          (h_node_info_bram_ena       ),
    .addrb        (h_node_info_bram_addrb     ),
    .dout         (h_node_info_bram_dout      ),
    .dout_nxt     (h_node_info_bram_dout_nxt  )
  );

  BRAM #(
    .DATA_WIDTH   (DATA_WIDTH           ),
    .DEPTH        (WEIGHT_DEPTH         )
  ) u_wgt_bram (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (wgt_bram_din         ),
    .addra        (wgt_bram_addra       ),
    .ena          (wgt_bram_ena         ),
    .addrb        (wgt_bram_addrb       ),
    .dout         (wgt_bram_dout        )
  );

  (* dont_touch = "true" *)
  BRAM #(
    .DATA_WIDTH   (WH_WIDTH             ),
    .DEPTH        (WH_DEPTH             )
  ) u_wh_bram (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (wh_bram_din          ),
    .addra        (wh_bram_addra        ),
    .ena          (wh_bram_ena          ),
    .addrb        (wh_bram_addrb        ),
    .dout         (wh_bram_dout         )
  );

  BRAM #(
    .DATA_WIDTH   (DATA_WIDTH           ),
    .DEPTH        (A_DEPTH              )
  ) u_a_bram (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (a_bram_din           ),
    .addra        (a_bram_addra         ),
    .ena          (a_bram_ena           ),
    .addrb        (a_bram_addrb         ),
    .dout         (a_bram_dout          )
  );

  dual_read_BRAM #(
    .DATA_WIDTH   (NUM_NODE_WIDTH       ),
    .DEPTH        (NUM_NODES_DEPTH      )
  ) u_num_node_bram (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (num_node_bram_din    ),
    .addra        (num_node_bram_addra  ),
    .ena          (num_node_bram_ena    ),
    .addrb        (num_node_bram_addrb  ),
    .doutb        (num_node_bram_doutb  ),
    .addrc        (num_node_bram_addrc  ),
    .doutc        (num_node_bram_doutc  )
  );

  FIFO #(
    .DATA_WIDTH (DATA_WIDTH         ),
    .FIFO_DEPTH (COEF_DEPTH         )
  ) u_coef_fifo (
    .clk        (clk                ),
    .rst_n      (rst_n              ),
    .din        (coef_ff_din        ),
    .wr_vld     (coef_ff_wr_vld     ),
    .full       (coef_ff_full       ),
    .empty      (coef_ff_empty      ),
    .dout       (coef_ff_dout       ),
    .rd_vld     (coef_ff_rd_vld     )
  );

  FIFO #(
    .DATA_WIDTH (ALPHA_DATA_WIDTH       ),
    .FIFO_DEPTH (ALPHA_DEPTH            )
  ) u_alpha_fifo (
    .clk        (clk                    ),
    .rst_n      (rst_n                  ),
    .din        (alpha_ff_din           ),
    .dout       (alpha_ff_dout          ),
    .wr_vld     (alpha_ff_wr_vld        ),
    .rd_vld     (alpha_ff_rd_vld        ),
    .empty      (alpha_ff_empty         ),
    .full       (alpha_ff_full          )
  );

  (* dont_touch = "true" *)
  BRAM #(
    .DATA_WIDTH     (NEW_FEATURE_WIDTH    ),
    .DEPTH          (NEW_FEATURE_DEPTH    )
  ) u_feat_bram (
    .clk            (clk                  ),
    .rst_n          (rst_n                ),
    .din            (feat_bram_din        ),
    .addra          (feat_bram_addra      ),
    .ena            (feat_bram_ena        ),
    .addrb          (feat_bram_addrb      ),
    .dout           (feat_bram_dout       )
  );
  //* ==========================================================
endmodule