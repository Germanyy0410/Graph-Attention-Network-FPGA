// ==================================================================
// File name  : feature_controller.sv
// Project    : Acceleration of Graph Attention Networks on FPGA
// Function   :
// -- Buffer each Feature vector in FIFO
// -- Fetch and store each value in a Feature vector in BRAM
// Author     : @Germanyy0410
// ==================================================================

module feature_controller import gat_pkg::*;
(
  input                                               clk                 ,
  input                                               rst_n               ,

  input        [NEW_FEATURE_WIDTH-1:0]                new_feat            ,
  input                                               new_feat_vld        ,
  output logic                                        new_feat_rdy        ,

  // -- new features
  output logic [NEW_FEATURE_ADDR_W-1:0]               feat_bram_addra     ,
  output logic [DATA_WIDTH-1:0]                       feat_bram_din       ,
  output logic                                        feat_bram_ena
);

  localparam CNT_DATA_WIDTH = $clog2(NUM_FEATURE_OUT);

  logic [NEW_FEATURE_WIDTH-1:0]                   feat_ff_din       ;
  logic [NEW_FEATURE_WIDTH-1:0]                   feat_ff_dout      ;
  logic                                           feat_ff_wr_vld    ;
  logic                                           feat_ff_rd_vld    ;
  logic                                           feat_ff_empty     ;
  logic                                           feat_ff_full      ;

  logic [NUM_FEATURE_OUT-1:0] [DATA_WIDTH-1:0]    feat              ;
  logic [CNT_DATA_WIDTH-1:0]                      cnt               ;
  logic [CNT_DATA_WIDTH-1:0]                      cnt_reg           ;

  logic [NEW_FEATURE_ADDR_W-1:0]                  feat_addr         ;
  logic [NEW_FEATURE_ADDR_W-1:0]                  feat_addr_reg     ;

  logic                                           push_feat_ena     ;

  FIFO #(
    .DATA_WIDTH (NEW_FEATURE_WIDTH      ),
    .FIFO_DEPTH (NUM_FEATURE_OUT        )
  ) u_new_feat_fifo (
    .clk        (clk                    ),
    .rst_n      (rst_n                  ),
    .din        (feat_ff_din            ),
    .dout       (feat_ff_dout           ),
    .wr_vld     (feat_ff_wr_vld         ),
    .rd_vld     (feat_ff_rd_vld         ),
    .empty      (feat_ff_empty          ),
    .full       (feat_ff_full           )
  );

  //* ================== push into ff ==================
  assign feat_ff_wr_vld = new_feat_vld;
  assign feat_ff_din    = new_feat;
  //* ====================================================

  //* ================== pop from ff ===================
  assign feat_ff_rd_vld = (cnt_reg == 0) && (!feat_ff_empty);
  assign feat           = feat_ff_dout;
  //* ====================================================

  assign push_feat_ena  = feat_ff_rd_vld || ((cnt_reg > 0) && (cnt_reg < NUM_FEATURE_OUT));
  assign feat_addr      = push_feat_ena ? (feat_addr_reg + 1) : feat_addr_reg;
  assign cnt            = push_feat_ena ? (cnt_reg + 1)       : cnt_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt_reg       <= 'b0;
      feat_addr_reg <= 'b0;
    end else begin
      cnt_reg         <= cnt;
      feat_addr_reg  <= feat_addr;
    end
  end

  //* ================== push into bram ==================
  assign feat_bram_din   = feat[cnt_reg];
  assign feat_bram_addra = feat_addr_reg;
  assign feat_bram_ena   = push_feat_ena;
  //* ====================================================

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      new_feat_rdy <= 'b0;
    end else begin
      new_feat_rdy <= (cnt_reg == NUM_FEATURE_OUT - 1);
    end
  end
endmodule