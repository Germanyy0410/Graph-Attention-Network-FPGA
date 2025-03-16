module debugger (
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
  input  [15:0] feat_bram_addra,
  input  feat_bram_ena,

  output [31:0] debug_1,
  output [31:0] debug_2,
  output [31:0] debug_3
);

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
      spmm_rdy_reg <= '0;
      dmvm_vld_reg <= '0;
      dmvm_rdy_reg <= '0;
      sm_vld_reg   <= '0;
      sm_rdy_reg   <= '0;
      aggr_vld_reg <= '0;
      aggr_rdy_reg <= '0;
      ena_flag_reg <= '0;
    end else begin
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

  assign debug_1 = { addr_flag, ena_flag_reg, dmvm_vld_reg, dmvm_rdy_reg, sm_vld_reg, sm_rdy_reg, aggr_vld_reg, aggr_rdy_reg };

  assign debug_2 = feat_bram_addra;

  logic [100:0] counter;
  logic [100:0] counter_reg;

  assign counter = (sm_vld_i) ? (counter_reg + 1) : counter_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter_reg <= '0;
    end else begin
      counter_reg <= counter;
    end
  end
  assign debug_3 = counter_reg;

endmodule