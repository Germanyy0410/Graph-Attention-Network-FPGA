`include "./../others/pkgs/params_pkg.sv"

module mem_ctrl import params_pkg::*;
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

  input   [DATA_WIDTH-1:0]          Weight_BRAM_din             ,
  input                             Weight_BRAM_ena             ,
  input   [WEIGHT_ADDR_W-1:0]       Weight_BRAM_addra           ,
  input   [WEIGHT_ADDR_W-1:0]       Weight_BRAM_addrb           ,
  output  [DATA_WIDTH-1:0]          Weight_BRAM_dout            ,
  input                             Weight_BRAM_load_done       ,

  input   [DATA_WIDTH-1:0]          a_BRAM_din                  ,
  input                             a_BRAM_ena                  ,
  input   [A_ADDR_W-1:0]            a_BRAM_addra                ,
  input   [A_ADDR_W-1:0]            a_BRAM_addrb                ,
  output  [DATA_WIDTH-1:0]          a_BRAM_dout                 ,
  input                             a_BRAM_load_done            ,

  input   [WH_WIDTH-1:0]            WH_1_BRAM_din               ,
  input                             WH_1_BRAM_ena               ,
  input   [WH_1_ADDR_W-1:0]         WH_1_BRAM_addra             ,
  output  [WH_WIDTH-1:0]            WH_1_BRAM_dout              ,
  input   [WH_1_ADDR_W-1:0]         WH_1_BRAM_addrb             ,

  input   [WH_WIDTH-1:0]            WH_2_BRAM_din               ,
  input                             WH_2_BRAM_ena               ,
  input   [WH_2_ADDR_W-1:0]         WH_2_BRAM_addra             ,
  output  [WH_WIDTH-1:0]            WH_2_BRAM_dout              ,
  input   [WH_2_ADDR_W-1:0]         WH_2_BRAM_addrb             ,

  // input   [NUM_NODE_WIDTH-1:0]      num_node_BRAM_din           ,
  // input                             num_node_BRAM_ena           ,
  // input   [NUM_NODE_ADDR_W-1:0]     num_node_BRAM_addra         ,
  // input   [NUM_NODE_ADDR_W-1:0]     num_node_BRAM_addrb         ,
  // output  [NUM_NODE_WIDTH-1:0]      num_node_BRAM_doutb         ,
  // input   [NUM_NODE_ADDR_W-1:0]     num_node_BRAM_addrc         ,
  // output  [NUM_NODE_WIDTH-1:0]      num_node_BRAM_doutc         ,

  // input   [DATA_WIDTH-1:0]          coef_FIFO_din               ,
  // output                            coef_FIFO_empty             ,
  // output                            coef_FIFO_full              ,
  // input                             coef_FIFO_wr_valid          ,
  // input                             coef_FIFO_rd_valid          ,
  // output  [DATA_WIDTH-1:0]          coef_FIFO_dout              ,

  // input   [ALPHA_DATA_WIDTH-1:0]    alpha_FIFO_din              ,
  // output                            alpha_FIFO_empty            ,
  // output                            alpha_FIFO_full             ,
  // input                             alpha_FIFO_wr_valid         ,
  // input                             alpha_FIFO_rd_valid         ,
  // output  [ALPHA_DATA_WIDTH-1:0]    alpha_FIFO_dout             ,

  input   [SOFTMAX_WIDTH-1:0]       softmax_FIFO_din            ,
  output  [SOFTMAX_WIDTH-1:0]       softmax_FIFO_dout           ,
  input                             softmax_FIFO_wr_valid       ,
  input                             softmax_FIFO_rd_valid       ,
  output                            softmax_FIFO_empty          ,
  output                            softmax_FIFO_full           ,

  input   [AGGR_WIDTH-1:0]          aggr_FIFO_din               ,
  output  [AGGR_WIDTH-1:0]          aggr_FIFO_dout              ,
  input                             aggr_FIFO_wr_valid          ,
  input                             aggr_FIFO_rd_valid          ,
  output                            aggr_FIFO_empty             ,
  output                            aggr_FIFO_full
);

  //* ========================= MEMORY =========================
  (* dont_touch = "yes" *)
  BRAM #(
    .DATA_WIDTH   (H_DATA_WIDTH         ),
    .DEPTH        (H_DATA_DEPTH         ),
    .CLK_LATENCY  (1                    )
  ) u_H_data_BRAM (
    .clk          (clk                  ),
    .rst_n        (rst_n                ),
    .din          (H_data_BRAM_din      ),
    .addra        (H_data_BRAM_addra    ),
    .ena          (H_data_BRAM_ena      ),
    .addrb        (H_data_BRAM_addrb    ),
    .dout         (H_data_BRAM_dout     )
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

  // (* dont_touch = "yes" *)
  // dual_read_BRAM #(
  //   .DATA_WIDTH   (NUM_NODE_WIDTH       ),
  //   .DEPTH        (NUM_NODES_DEPTH      ),
  //   .CLK_LATENCY  (0                    )
  // ) u_num_node_BRAM (
  //   .clk          (clk                  ),
  //   .rst_n        (rst_n                ),
  //   .din          (num_node_BRAM_din    ),
  //   .addra        (num_node_BRAM_addra  ),
  //   .ena          (num_node_BRAM_ena    ),
  //   .addrb        (num_node_BRAM_addrb  ),
  //   .doutb        (num_node_BRAM_doutb  ),
  //   .addrc        (num_node_BRAM_addrc  ),
  //   .doutc        (num_node_BRAM_doutc  )
  // );

  // (* dont_touch = "yes" *)
  // FIFO #(
  //   .DATA_WIDTH (DATA_WIDTH     ),
  //   .FIFO_DEPTH (TOTAL_NODES    )
  // ) u_coef_FIFO (
  //   .clk        (clk                ),
  //   .rst_n      (rst_n              ),
  //   .din        (coef_FIFO_din      ),
  //   .wr_vld     (coef_FIFO_wr_valid ),
  //   .full       (coef_FIFO_full     ),
  //   .empty      (coef_FIFO_empty    ),
  //   .dout       (coef_FIFO_dout     ),
  //   .rd_vld     (coef_FIFO_rd_valid )
  // );

  (* dont_touch = "yes" *)
  FIFO #(
    .DATA_WIDTH (SOFTMAX_WIDTH          ),
    .FIFO_DEPTH (20                     )
  ) u_softmax_FIFO (
    .clk        (clk                    ),
    .rst_n      (rst_n                  ),
    .din        (softmax_FIFO_din       ),
    .dout       (softmax_FIFO_dout      ),
    .wr_vld     (softmax_FIFO_wr_valid  ),
    .rd_vld     (softmax_FIFO_rd_valid  ),
    .empty      (softmax_FIFO_empty     ),
    .full       (softmax_FIFO_full      )
  );

  // (* dont_touch = "yes" *)
  // FIFO #(
  //   .DATA_WIDTH (ALPHA_DATA_WIDTH       ),
  //   .FIFO_DEPTH (TOTAL_NODES            )
  // ) u_alpha_FIFO (
  //   .clk        (clk                    ),
  //   .rst_n      (rst_n                  ),
  //   .din        (alpha_FIFO_din         ),
  //   .dout       (alpha_FIFO_dout        ),
  //   .wr_vld     (alpha_FIFO_wr_valid    ),
  //   .rd_vld     (alpha_FIFO_rd_valid    ),
  //   .empty      (alpha_FIFO_empty       ),
  //   .full       (alpha_FIFO_full        )
  // );

  (* dont_touch = "yes" *)
  FIFO #(
    .DATA_WIDTH (AGGR_WIDTH             ),
    .FIFO_DEPTH (20                     )
  ) u_aggregator_FIFO (
    .clk        (clk                    ),
    .rst_n      (rst_n                  ),
    .din        (aggr_FIFO_din          ),
    .dout       (aggr_FIFO_dout         ),
    .wr_vld     (aggr_FIFO_wr_valid     ),
    .rd_vld     (aggr_FIFO_rd_valid     ),
    .empty      (aggr_FIFO_empty        ),
    .full       (aggr_FIFO_full         )
  );
  //* ==========================================================
endmodule