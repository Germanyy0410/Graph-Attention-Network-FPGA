`include "./../../inc/gat_pkg.sv"

module memory_controller import gat_pkg::*;
(
  input                             clk                         ,
  input                             rst_n                       ,

  input   [H_DATA_WIDTH-1:0]        H_data_BRAM_din             ,
  input                             H_data_BRAM_ena             ,
  input   [H_DATA_ADDR_W-1:0]       H_data_BRAM_addra           ,
  input   [H_DATA_ADDR_W-1:0]       H_data_BRAM_addrb           ,
  output  [H_DATA_WIDTH-1:0]        H_data_BRAM_dout            ,
  input                             H_data_BRAM_load_done       ,

  input   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_din        ,
  input                             H_node_info_BRAM_ena        ,
  input   [NODE_INFO_ADDR_W-1:0]    H_node_info_BRAM_addra      ,
  input   [NODE_INFO_ADDR_W-1:0]    H_node_info_BRAM_addrb      ,
  output  [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout       ,
  output  [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout_nxt   ,
  input                             H_node_info_BRAM_load_done  ,

  input   [DATA_WIDTH-1:0]          weight_BRAM_din             ,
  input                             weight_BRAM_ena             ,
  input   [WEIGHT_ADDR_W-1:0]       weight_BRAM_addra           ,
  input   [WEIGHT_ADDR_W-1:0]       weight_BRAM_addrb           ,
  output  [DATA_WIDTH-1:0]          weight_BRAM_dout            ,
  input                             weight_BRAM_load_done       ,

  input   [DATA_WIDTH-1:0]          a_BRAM_din                  ,
  input                             a_BRAM_ena                  ,
  input   [A_ADDR_W-1:0]            a_BRAM_addra                ,
  input   [A_ADDR_W-1:0]            a_BRAM_addrb                ,
  output  [DATA_WIDTH-1:0]          a_BRAM_dout                 ,
  input                             a_BRAM_load_done            ,

  input   [WH_WIDTH-1:0]            WH_BRAM_din                 ,
  input                             WH_BRAM_ena                 ,
  input   [WH_ADDR_W-1:0]           WH_BRAM_addra               ,
  output  [WH_WIDTH-1:0]            WH_BRAM_dout                ,
  input   [WH_ADDR_W-1:0]           WH_BRAM_addrb               ,

  input   [NUM_NODE_WIDTH-1:0]      num_node_BRAM_din           ,
  input                             num_node_BRAM_ena           ,
  input   [NUM_NODE_ADDR_W-1:0]     num_node_BRAM_addra         ,
  input   [NUM_NODE_ADDR_W-1:0]     num_node_BRAM_addrb         ,
  output  [NUM_NODE_WIDTH-1:0]      num_node_BRAM_doutb         ,
  input   [NUM_NODE_ADDR_W-1:0]     num_node_BRAM_addrc         ,
  output  [NUM_NODE_WIDTH-1:0]      num_node_BRAM_doutc         ,

  input   [DATA_WIDTH-1:0]          coef_FIFO_din               ,
  output                            coef_FIFO_empty             ,
  output                            coef_FIFO_full              ,
  input                             coef_FIFO_wr_vld            ,
  input                             coef_FIFO_rd_vld            ,
  output  [DATA_WIDTH-1:0]          coef_FIFO_dout              ,

  input   [ALPHA_DATA_WIDTH-1:0]    alpha_FIFO_din              ,
  output                            alpha_FIFO_empty            ,
  output                            alpha_FIFO_full             ,
  input                             alpha_FIFO_wr_vld           ,
  input                             alpha_FIFO_rd_vld           ,
  output  [ALPHA_DATA_WIDTH-1:0]    alpha_FIFO_dout             ,

  input   [DATA_WIDTH-1:0]          feature_BRAM_din            ,
  input                             feature_BRAM_ena            ,
  input   [NEW_FEATURE_ADDR_W-1:0]  feature_BRAM_addra          ,
  output  [DATA_WIDTH-1:0]          feature_BRAM_dout           ,
  input   [NEW_FEATURE_ADDR_W-1:0]  feature_BRAM_addrb
);
  //* ========================= MEMORY =========================
  BRAM #(
    .DATA_WIDTH   (H_DATA_WIDTH         ),
    .DEPTH        (H_DATA_DEPTH         )
  ) u_H_data_BRAM (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (H_data_BRAM_din      ),
    .addra        (H_data_BRAM_addra    ),
    .ena          (H_data_BRAM_ena      ),
    .addrb        (H_data_BRAM_addrb    ),
    .dout         (H_data_BRAM_dout     )
  );

  modified_BRAM #(
    .DATA_WIDTH   (NODE_INFO_WIDTH            ),
    .DEPTH        (NODE_INFO_DEPTH            )
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

  BRAM #(
    .DATA_WIDTH   (DATA_WIDTH           ),
    .DEPTH        (WEIGHT_DEPTH         )
  ) u_weight_BRAM (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (weight_BRAM_din      ),
    .addra        (weight_BRAM_addra    ),
    .ena          (weight_BRAM_ena      ),
    .addrb        (weight_BRAM_addrb    ),
    .dout         (weight_BRAM_dout     )
  );

  (* dont_touch = "true" *)
  BRAM #(
    .DATA_WIDTH   (WH_WIDTH             ),
    .DEPTH        (WH_DEPTH             )
  ) u_WH_BRAM (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (WH_BRAM_din          ),
    .addra        (WH_BRAM_addra        ),
    .ena          (WH_BRAM_ena          ),
    .addrb        (WH_BRAM_addrb        ),
    .dout         (WH_BRAM_dout         )
  );

  BRAM #(
    .DATA_WIDTH   (DATA_WIDTH           ),
    .DEPTH        (A_DEPTH              )
  ) u_a_BRAM (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (a_BRAM_din           ),
    .addra        (a_BRAM_addra         ),
    .ena          (a_BRAM_ena           ),
    .addrb        (a_BRAM_addrb         ),
    .dout         (a_BRAM_dout          )
  );

  dual_read_BRAM #(
    .DATA_WIDTH   (NUM_NODE_WIDTH       ),
    .DEPTH        (NUM_NODES_DEPTH      )
  ) u_num_node_BRAM (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (num_node_BRAM_din    ),
    .addra        (num_node_BRAM_addra  ),
    .ena          (num_node_BRAM_ena    ),
    .addrb        (num_node_BRAM_addrb  ),
    .doutb        (num_node_BRAM_doutb  ),
    .addrc        (num_node_BRAM_addrc  ),
    .doutc        (num_node_BRAM_doutc  )
  );

  FIFO #(
    .DATA_WIDTH (DATA_WIDTH     ),
    .FIFO_DEPTH (COEF_DEPTH     )
  ) u_coef_FIFO (
    .clk        (clk                ),
    .rst_n      (rst_n              ),
    .din        (coef_FIFO_din      ),
    .wr_vld     (coef_FIFO_wr_vld   ),
    .full       (coef_FIFO_full     ),
    .empty      (coef_FIFO_empty    ),
    .dout       (coef_FIFO_dout     ),
    .rd_vld     (coef_FIFO_rd_vld   )
  );

  FIFO #(
    .DATA_WIDTH (ALPHA_DATA_WIDTH       ),
    .FIFO_DEPTH (ALPHA_DEPTH            )
  ) u_alpha_FIFO (
    .clk        (clk                    ),
    .rst_n      (rst_n                  ),
    .din        (alpha_FIFO_din         ),
    .dout       (alpha_FIFO_dout        ),
    .wr_vld     (alpha_FIFO_wr_vld      ),
    .rd_vld     (alpha_FIFO_rd_vld      ),
    .empty      (alpha_FIFO_empty       ),
    .full       (alpha_FIFO_full        )
  );

  (* dont_touch = "true" *)
  BRAM #(
    .DATA_WIDTH     (NEW_FEATURE_WIDTH    ),
    .DEPTH          (NEW_FEATURE_DEPTH    )
  ) u_feature_BRAM (
    .clk            (clk                  ),
    .rst_n          (rst_n                ),
    .din            (feature_BRAM_din     ),
    .addra          (feature_BRAM_addra   ),
    .ena            (feature_BRAM_ena     ),
    .addrb          (feature_BRAM_addrb   ),
    .dout           (feature_BRAM_dout    )
  );
  //* ==========================================================
endmodule