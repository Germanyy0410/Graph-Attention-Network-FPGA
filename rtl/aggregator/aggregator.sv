`include "./../others/pkgs/params_pkg.sv"

module aggregator import params_pkg::*;
(
  input                                               clk                 ,
  input                                               rst_n               ,

  input                                               aggr_valid_i        ,
  output                                              aggr_ready_o        ,

  // -- WH
  input   [WH_WIDTH-1:0]                              WH_BRAM_dout        ,
  output  [WH_ADDR_W-1:0]                             WH_BRAM_addrb       ,

  // -- alpha
  input   [ALPHA_DATA_WIDTH-1:0]                      alpha_FIFO_dout     ,
  input                                               alpha_FIFO_empty    ,
  output                                              alpha_FIFO_rd_vld   ,

  // -- new features
  output logic [NEW_FEATURE_ADDR_W-1:0]               Feature_BRAM_addra  ,
  output logic [NEW_FEATURE_WIDTH-1:0]                Feature_BRAM_din    ,
  output logic                                        Feature_BRAM_ena
);
  //* ============== logic declaration ==============
  logic                                               aggr_valid_q1       ;
  logic                                               aggr_ready          ;
  logic                                               aggr_ready_reg      ;

  logic [ALPHA_DATA_WIDTH-1:0]                        alpha               ;

  logic [WH_ADDR_W-1:0]                               WH_addr             ;
  logic [WH_ADDR_W-1:0]                               WH_addr_reg         ;
  logic [NUM_FEATURE_OUT-1:0] [WH_DATA_WIDTH-1:0]     WH_dout             ;
  logic [NUM_NODE_WIDTH-1:0]                          WH_num_of_nodes     ;
  logic                                               source_node_flag    ;

  logic [NUM_NODE_WIDTH-1:0]                          num_of_nodes        ;
  logic [NUM_NODE_WIDTH-1:0]                          num_of_nodes_reg    ;
  logic [NUM_NODE_WIDTH-1:0]                          counter             ;
  logic [NUM_NODE_WIDTH-1:0]                          counter_reg         ;

  logic                                               mul_valid           ;
  logic [NUM_FEATURE_OUT-1:0]                         mul_ready           ;
  logic [NUM_FEATURE_OUT-1:0] [AGGR_MULT_W-1:0]       product             ;
  logic [NUM_FEATURE_OUT-1:0] [AGGR_MULT_W-1:0]       result              ;
  logic [NUM_FEATURE_OUT-1:0] [AGGR_MULT_W-1:0]       result_reg          ;

  logic [NUM_FEATURE_OUT-1:0] [DATA_WIDTH-1:0]        new_feature         ;
  logic [NUM_NODE_WIDTH-1:0]                          num_of_nodes_out    ;
  logic [NUM_NODE_WIDTH-1:0]                          num_of_nodes_out_reg;
  logic [NEW_FEATURE_ADDR_W-1:0]                      feature_addr        ;
  logic [NEW_FEATURE_ADDR_W-1:0]                      feature_addr_reg    ;

  logic                                               new_feature_enable  ;
  //* ===============================================

  genvar i;

  //* ================= flop input ==================
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      aggr_valid_q1 <= 0;
    end else begin
      aggr_valid_q1 <= aggr_valid_i;
    end
  end
  //* ===============================================


  //* =========== read data from WH BRAM ============
  assign WH_BRAM_addrb                                  = WH_addr_reg;
  assign { WH_dout, WH_num_of_nodes, source_node_flag } = WH_BRAM_dout;

  assign WH_addr      = (alpha_FIFO_rd_vld) ? (WH_addr_reg + 1'b1) : WH_addr_reg;
  assign num_of_nodes = (source_node_flag) ? WH_num_of_nodes : num_of_nodes_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      WH_addr_reg       <= '0;
      num_of_nodes_reg  <= '0;
    end else begin
      WH_addr_reg       <= WH_addr;
      num_of_nodes_reg  <= num_of_nodes;
    end
  end
  //* ==============================================


  //* ========= read data from Alpha FIFO ==========
  assign alpha_FIFO_rd_vld = (!alpha_FIFO_empty);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      alpha <= 0;
    end else begin
      alpha <= alpha_FIFO_dout;
    end
  end
  //* ==============================================


  //* ============= main calculation ===============
  always_comb begin
    counter = counter_reg;
    if (&mul_ready) begin
      if (counter_reg < num_of_nodes_reg) begin
        counter = counter_reg + 1;
      end else begin
        counter = '0;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mul_valid <= '0;
    end else begin
      mul_valid <= alpha_FIFO_rd_vld;
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
        .valid  (mul_valid        ),
        .ready  (mul_ready[i]     ),
        .ina    (WH_dout[i]       ),
        .inb    (alpha            ),
        .out    (product[i]       )
      );
    end
  endgenerate

  generate
    for (i = 0; i < NUM_FEATURE_OUT; i = i + 1) begin
      assign result[i] = (counter_reg == 0) ? product[i] : (product[i] + result_reg[i]);
    end
  endgenerate

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      result_reg  <= '0;
      counter_reg <= '0;
    end else begin
      result_reg  <= result;
      counter_reg <= counter;
    end
  end
  //* ==============================================


  //* ========== push data to Feature BRAM =========
  generate
    for (i = 0; i < NUM_FEATURE_OUT; i = i + 1) begin
      assign new_feature[i] = (result_reg[i][AGGR_MULT_W-1] == 1'b0)
                              ? result_reg[i][AGGR_MULT_W-1:AGGR_MULT_W-WH_DATA_WIDTH]
                              : '0;
    end
  endgenerate

  assign num_of_nodes_out = (Feature_BRAM_ena || (feature_addr_reg == 0 && aggr_valid_i)) ? num_of_nodes_reg : num_of_nodes_out_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      num_of_nodes_out_reg <= '0;
    end else begin
      num_of_nodes_out_reg <= num_of_nodes_out;
    end
  end

  assign new_feature_enable = (counter_reg == (num_of_nodes_out_reg - 1));
  assign feature_addr       = (new_feature_enable && aggr_valid_i) ? (feature_addr_reg + 1'b1) : feature_addr_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      feature_addr_reg <= 0;
    end else begin
      feature_addr_reg <= feature_addr;
    end
  end

  assign Feature_BRAM_din = new_feature;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      Feature_BRAM_addra  <= '0;
      Feature_BRAM_ena    <= '0;
    end else begin
      Feature_BRAM_addra  <= feature_addr_reg;
      Feature_BRAM_ena    <= new_feature_enable;
    end
  end
  //* ==============================================


  //* ================= aggr_ready =================
  assign aggr_ready_o = aggr_ready_reg;
  assign aggr_ready   = new_feature_enable;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      aggr_ready_reg <= '0;
    end else begin
      aggr_ready_reg <= aggr_ready;
    end
  end
  //* ==============================================
endmodule

