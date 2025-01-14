`include "./../../inc/gat_pkg.sv"

module feature_controller import gat_pkg::*;
(
  input                                               clk                 ,
  input                                               rst_n               ,

  input        [NEW_FEATURE_WIDTH-1:0]                new_feature         ,
  input                                               new_feature_vld     ,
  output logic                                        new_feature_rdy     ,

  // -- new features
  output logic [NEW_FEATURE_ADDR_W-1:0]               feature_BRAM_addra  ,
  output logic [DATA_WIDTH-1:0]                       feature_BRAM_din    ,
  output logic                                        feature_BRAM_ena
);

  localparam CNT_DATA_WIDTH = $clog2(NUM_FEATURE_OUT);

  logic [NEW_FEATURE_WIDTH-1:0]                   feature_FIFO_din        ;
  logic [NEW_FEATURE_WIDTH-1:0]                   feature_FIFO_dout       ;
  logic                                           feature_FIFO_wr_vld     ;
  logic                                           feature_FIFO_rd_vld     ;
  logic                                           feature_FIFO_empty      ;
  logic                                           feature_FIFO_full       ;

  logic [NUM_FEATURE_OUT-1:0] [DATA_WIDTH-1:0]    feature                 ;
  logic [CNT_DATA_WIDTH-1:0]                      counter                 ;
  logic [CNT_DATA_WIDTH-1:0]                      counter_reg             ;

  logic [NEW_FEATURE_ADDR_W-1:0]                  feature_addr            ;
  logic [NEW_FEATURE_ADDR_W-1:0]                  feature_addr_reg        ;

  logic                                           push_feature_en         ;

  FIFO #(
    .DATA_WIDTH (NEW_FEATURE_WIDTH      ),
    .FIFO_DEPTH (NUM_FEATURE_OUT        )
  ) u_new_feature_FIFO (
    .clk        (clk                    ),
    .rst_n      (rst_n                  ),
    .din        (feature_FIFO_din       ),
    .dout       (feature_FIFO_dout      ),
    .wr_vld     (feature_FIFO_wr_vld    ),
    .rd_vld     (feature_FIFO_rd_vld    ),
    .empty      (feature_FIFO_empty     ),
    .full       (feature_FIFO_full      )
  );

  //* ================== push into FIFO ==================
  assign feature_FIFO_wr_vld = new_feature_vld;
  assign feature_FIFO_din    = new_feature;
  //* ====================================================

  //* ================== pop from FIFO ===================
  assign feature_FIFO_rd_vld = (counter_reg == 0) && (!feature_FIFO_empty);
  assign feature             = feature_FIFO_dout;
  //* ====================================================

  assign push_feature_en  = feature_FIFO_rd_vld || ((counter_reg > 0) && (counter_reg < NUM_FEATURE_OUT));
  assign feature_addr     = push_feature_en ? (feature_addr_reg + 1)  : feature_addr_reg;
  assign counter          = push_feature_en ? (counter_reg + 1)       : counter_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter_reg       <= '0;
      feature_addr_reg  <= '0;
    end else begin
      counter_reg       <= counter;
      feature_addr_reg  <= feature_addr;
    end
  end

  //* ================== push into BRAM ==================
  assign feature_BRAM_din   = feature[counter_reg];
  assign feature_BRAM_addra = feature_addr_reg;
  assign feature_BRAM_ena   = push_feature_en;
  //* ====================================================

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      new_feature_rdy <= '0;
    end else begin
      new_feature_rdy <= (counter_reg == NUM_FEATURE_OUT - 1);
    end
  end
endmodule