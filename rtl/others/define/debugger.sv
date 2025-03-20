module debugger #(parameter H_NUM_SPARSE_DATA = 12)(
  input  clk,
  input  rst_n,
  input  spmm_vld_i,
  input  spmm_rdy_i,
  input  dmvm_vld_i,
  input  dmvm_rdy_i,
  input  sm_vld_i,
  input  sm_rdy_i,
  input  aggr_vld_i,
  input  aggr_rdy_i,


  input  [17:0] h_data_bram_addrb,
  input  [18:0] h_data_bram_dout,

  input  [14:0] wgt_bram_addrb,
  input  [13:0] h_node_info_bram_addrb,

  input  [15:0] [11:0] sppe,
  input  [13:0] wh_bram_addra,

  input  [31:0] feat_bram_din,
  input  feat_bram_ena,
  input  [15:0] feat_bram_addra,

  output [31:0] debug_1,
  output [31:0] debug_2,
  output [31:0] debug_3
);

  logic spmm_vld;
  logic spmm_vld_reg;
  logic spmm_rdy;
  logic spmm_rdy_reg;
  logic dmvm_vld;
  logic dmvm_vld_reg;
  logic dmvm_rdy;
  logic dmvm_rdy_reg;
  logic sm_vld;
  logic sm_vld_reg;
  logic sm_rdy;
  logic sm_rdy_reg;
  logic aggr_vld;
  logic aggr_vld_reg;
  logic aggr_rdy;
  logic aggr_rdy_reg;

  logic addr_flag;
  logic ena_flag;
  logic ena_flag_reg;

  assign spmm_vld = (spmm_vld_i) ? 1'b1 : spmm_vld_reg;
  assign spmm_rdy = (spmm_rdy_i) ? 1'b1 : spmm_rdy_reg;
  assign dmvm_vld = (dmvm_vld_i) ? 1'b1 : dmvm_vld_reg;
  assign dmvm_rdy = (dmvm_rdy_i) ? 1'b1 : dmvm_rdy_reg;
  assign sm_vld   = (sm_vld_i)   ? 1'b1 : sm_vld_reg;
  assign sm_rdy   = (sm_rdy_i)   ? 1'b1 : sm_rdy_reg;
  assign aggr_vld = (aggr_vld_i) ? 1'b1 : aggr_vld_reg;
  assign aggr_rdy = (aggr_rdy_i) ? 1'b1 : aggr_rdy_reg;

  assign addr_flag = (feat_bram_addra >= 43328);
  assign ena_flag  = (feat_bram_ena) ? 1'b1 : ena_flag_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      spmm_vld_reg <= '0;
      spmm_rdy_reg <= '0;
      dmvm_vld_reg <= '0;
      dmvm_rdy_reg <= '0;
      sm_vld_reg   <= '0;
      sm_rdy_reg   <= '0;
      aggr_vld_reg <= '0;
      aggr_rdy_reg <= '0;
      ena_flag_reg <= '0;
    end else begin
      spmm_vld_reg <= spmm_vld;
      spmm_rdy_reg <= spmm_rdy;
      dmvm_vld_reg <= dmvm_vld;
      dmvm_rdy_reg <= dmvm_rdy;
      sm_vld_reg   <= sm_vld;
      sm_rdy_reg   <= sm_rdy;
      aggr_vld_reg <= aggr_vld;
      aggr_rdy_reg <= aggr_rdy;
      ena_flag_reg <= ena_flag;
    end
  end

  logic [100:0] counter;
  logic [100:0] counter_reg;
  logic [31:0]  data_1;
  logic [31:0]  data_1_reg;
  logic [31:0]  data_2;
  logic [31:0]  data_2_reg;

  assign counter = (sm_vld_i) ? (counter_reg + 1) : counter_reg;
  assign data_1  = (wh_bram_addra == 10 && spmm_rdy_i) ? sppe[2] : data_1_reg;
  assign data_2  = (wh_bram_addra == 20 && spmm_rdy_i) ? sppe[2] : data_2_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter_reg <= '0;
      data_1_reg  <= '0;
      data_2_reg  <= '0;
    end else begin
      counter_reg <= counter;
      data_1_reg  <= data_1;
      data_2_reg  <= data_2;
    end
  end

  assign debug_1 = H_NUM_SPARSE_DATA;
  assign debug_2 = { spmm_vld_reg, spmm_rdy_reg, dmvm_vld_reg, dmvm_rdy_reg, sm_vld_reg, sm_rdy_reg, aggr_vld_reg, aggr_rdy_reg };
  assign debug_3 = 19032003;

endmodule
