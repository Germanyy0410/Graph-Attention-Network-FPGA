// ====================================================================
// File name  : aggregator.sv
// Project    : Graph Attention Network Accelerator on FPGA
// Function   :
// -- Compute the new Feature vector: H = ReLU[sum(alpha x Wh)]
// -- Pipeline stage = 2
// -- Fetch Wh vectors and coefficients from BRAM
// -- Store new Feature vector in BRAM
// Author     : @Germanyy0410
// ====================================================================

module aggregator import gat_pkg::*;
(
  input                                               clk                 ,
  input                                               rst_n               ,

  input                                               aggr_vld_i          ,
  output                                              aggr_rdy_o          ,

  // -- WH
  input   [WH_WIDTH-1:0]                              wh_bram_dout        ,
  output  [WH_ADDR_W-1:0]                             wh_bram_addrb       ,

  // -- alpha
  input   [ALPHA_DATA_WIDTH-1:0]                      alpha_ff_dout       ,
  input                                               alpha_ff_empty      ,
  output                                              alpha_ff_rd_vld     ,

  // -- new features
  output logic [NEW_FEATURE_ADDR_W-1:0]               feat_bram_addra     ,
  output logic [DATA_WIDTH-1:0]                       feat_bram_din       ,
  output logic                                        feat_bram_ena
);
  //* ============== logic declaration ==============
  logic [ALPHA_DATA_WIDTH-1:0]                        alpha               ;

  logic [WH_ADDR_W-1:0]                               wh_addr             ;
  logic [WH_ADDR_W-1:0]                               wh_addr_reg         ;
  logic [NUM_FEATURE_OUT-1:0] [WH_DATA_WIDTH-1:0]     wh_dout             ;
  logic [NUM_NODE_WIDTH-1:0]                          wh_num_node         ;
  logic                                               src_flag            ;

  logic [NUM_NODE_WIDTH-1:0]                          num_node            ;
  logic [NUM_NODE_WIDTH-1:0]                          num_node_reg        ;
  logic [NUM_NODE_WIDTH-1:0]                          cnt                 ;
  logic [NUM_NODE_WIDTH-1:0]                          cnt_reg             ;

  logic                                               mul_vld             ;
  logic [NUM_FEATURE_OUT-1:0]                         mul_rdy             ;
  logic [NUM_FEATURE_OUT-1:0] [AGGR_MULT_W-1:0]       prod                ;
  logic [NUM_FEATURE_OUT-1:0] [AGGR_MULT_W-1:0]       res                 ;
  logic [NUM_FEATURE_OUT-1:0] [AGGR_MULT_W-1:0]       res_reg             ;

  logic [NUM_FEATURE_OUT-1:0] [DATA_WIDTH-1:0]        new_feat            ;
  logic [NUM_NODE_WIDTH-1:0]                          num_node_out        ;
  logic [NUM_NODE_WIDTH-1:0]                          num_node_out_reg    ;
  logic [NEW_FEATURE_ADDR_W-1:0]                      feat_addr           ;
  logic [NEW_FEATURE_ADDR_W-1:0]                      feat_addr_reg       ;

  logic                                               new_feat_ena        ;
  //* ===============================================

  genvar i;

  //* =========== read data from WH bram ============
  assign wh_bram_addrb                      = wh_addr_reg;
  assign { wh_dout, wh_num_node, src_flag } = wh_bram_dout;

  assign wh_addr  = (alpha_ff_rd_vld) ? (wh_addr_reg + 1'b1) : wh_addr_reg;
  assign num_node = (src_flag) ? wh_num_node : num_node_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wh_addr_reg   <= 'b0;
      num_node_reg  <= 'b0;
    end else begin
      wh_addr_reg   <= wh_addr;
      num_node_reg  <= num_node;
    end
  end
  //* ==============================================


  //* ========= read data from Alpha ff ==========
  assign alpha_ff_rd_vld = (!alpha_ff_empty);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      alpha <= 'b0;
    end else begin
      alpha <= alpha_ff_dout;
    end
  end
  //* ==============================================


  //* ============= main calculation ===============
  always_comb begin
    cnt = cnt_reg;
    if (&mul_rdy) begin
      if (cnt_reg < num_node_reg) begin
        cnt = cnt_reg + 1;
      end else begin
        cnt = '0;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mul_vld <= 'b0;
    end else begin
      mul_vld <= alpha_ff_rd_vld;
    end
  end

  generate
    for (i = 0; i < NUM_FEATURE_OUT; i = i + 1) begin
      fxp_mul_pipe #(
        .WIIA   (WH_DATA_WIDTH    ),
        .WIFA   (0                ),
        .WIIB   (WOI              ),
        .WIFB   (WOF              ),
        .WOI    (WH_DATA_WIDTH    ),
        .WOF    (32               ),
        .ROUND  (1                )
      ) u_mul_pipe (
        .clk    (clk              ),
        .rstn   (rst_n            ),
        .vld    (mul_vld          ),
        .rdy    (mul_rdy[i]       ),
        .ina    (wh_dout[i]       ),
        .inb    (alpha            ),
        .out    (prod[i]          )
      );
    end
  endgenerate

  generate
    for (i = 0; i < NUM_FEATURE_OUT; i = i + 1) begin
      assign res[i] = (cnt_reg == 0) ? prod[i] : (prod[i] + res_reg[i]);
    end
  endgenerate

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      res_reg  <= '0;
      cnt_reg <= '0;
    end else begin
      res_reg  <= res;
      cnt_reg <= cnt;
    end
  end
  //* ==============================================


  //* ========== push data to feature bram =========
  generate
    for (i = 0; i < NUM_FEATURE_OUT; i = i + 1) begin
      assign new_feat[i] = (res_reg[i][AGGR_MULT_W-1] == 1'b0)
                              ? res_reg[i][AGGR_MULT_W-1:AGGR_MULT_W-WH_DATA_WIDTH]
                              : '0;
    end
  endgenerate

  assign num_node_out = (aggr_rdy_o || (feat_addr_reg == 0 && aggr_vld_i)) ? num_node_reg : num_node_out_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      num_node_out_reg <= '0;
    end else begin
      num_node_out_reg <= num_node_out;
    end
  end

  assign new_feat_ena = (cnt_reg == (num_node_out_reg - 1));

  feature_controller u_feature_controller (
    .clk                (clk                ),
    .rst_n              (rst_n              ),

    .new_feat           (new_feat           ),
    .new_feat_vld       (new_feat_ena       ),
    .new_feat_rdy       (aggr_rdy_o         ),

    .feat_bram_addra    (feat_bram_addra    ),
    .feat_bram_din      (feat_bram_din      ),
    .feat_bram_ena      (feat_bram_ena      )
  );
  //* ==============================================
endmodule

