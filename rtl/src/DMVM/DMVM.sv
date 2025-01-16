// ======================================================================
// File name  : DMVM.sv
// Project    : Graph Attention Network Accelerator on FPGA
// Function   :
// -- Compute attention coefficients: a = ReLU[e x (Wh1 || Wh2)]
// -- Pipeline stage = $clog2(NUM_FEATURE_OUT) + 1
// -- Fetch WH vector and Attention Weight vector from BRAM
// -- Store the coefficients in BRAM
// Author     : @Germanyy0410
// ======================================================================

module DMVM import gat_pkg::*;
(
  input                                         clk                 ,
  input                                         rst_n               ,

  input                                         dmvm_vld_i          ,
  output                                        dmvm_rdy_o          ,

  // -- a
  input                                         a_vld_i             ,
  input   [A_DEPTH-1:0] [DATA_WIDTH-1:0]        a_i                 ,

  // -- WH bram
  input   [WH_WIDTH-1:0]                        wh_data_i           ,

  // -- output
  output  [DATA_WIDTH-1:0]                      coef_ff_din         ,
  input                                         coef_ff_full        ,
  output                                        coef_ff_wr_vld
);

  //* ========== logic declaration ===========
  // -- Weight vector a1 & a2
  logic [HALF_A_SIZE-1:0] [DATA_WIDTH-1:0]                        a_src               ;
  logic [HALF_A_SIZE-1:0] [DATA_WIDTH-1:0]                        a_nbr               ;

  // -- capture [dout]
  logic                                                           wh_rd_dly           ;
  logic [WH_WIDTH-1:0]                                            wh_data             ;
  logic [WH_WIDTH-1:0]                                            wh_data_reg         ;

  // -- WH data
  logic [HALF_A_SIZE-1:0] [WH_DATA_WIDTH-1:0]                     wh_arr              ;
  logic                                                           src_flag            ;

  logic [NUM_NODE_WIDTH-1:0]                                      num_node            ;

  // -- pipeline 5 stages
  logic [NUM_STAGES-1:0]                                          pipe_src_flag       ;
  logic [NUM_STAGES:0]                                            pipe_src_flag_reg   ;
  logic [DMVM_DATA_WIDTH-1:0]                                     source_dmvm         ;
  logic [DMVM_DATA_WIDTH-1:0]                                     source_dmvm_reg     ;
  logic [DATA_WIDTH-1:0]                                          pipe_coef           ;
  logic [DATA_WIDTH-1:0]                                          pipe_coef_reg       ;
  logic [NUM_STAGES-1:0] [HALF_A_SIZE-1:0] [DMVM_DATA_WIDTH-1:0]  pipe_prod           ;
  logic [NUM_STAGES:0] [HALF_A_SIZE-1:0] [DMVM_DATA_WIDTH-1:0]    pipe_prod_reg       ;

  // -- output
  logic [COEF_DELAY_LENGTH-1:0]                                   vld_shft_reg        ;
  logic                                                           dmvm_rdy_reg        ;

  //* =======================================

  genvar i, k;
  integer x;

  //* ========== output assignment ==========
  assign dmvm_rdy_o = dmvm_rdy_reg;
  //* =======================================


  //* ========== split vector [a] ===========
  generate
    for (i = 0; i < HALF_A_SIZE; i = i + 1) begin
      assign a_src[HALF_A_SIZE-1-i] = a_i[i];
    end

    for (i = 0; i < HALF_A_SIZE; i = i + 1) begin
      assign a_nbr[HALF_A_SIZE-1-i] = a_i[i + HALF_A_SIZE];
    end
  endgenerate
  //* =======================================


  //* ============== wh_data ================
  assign wh_data = dmvm_vld_i ? wh_data_i : wh_data_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wh_data_reg  <= 'b0;
    end else begin
      wh_data_reg  <= wh_data;
    end
  end
  //* =======================================


  //* ======= get WH data from bram =========
  assign src_flag = wh_data_reg[0];
  assign num_node     = wh_data_reg[NUM_NODE_WIDTH:1];

  generate
    for (i = 0; i < HALF_A_SIZE; i = i + 1) begin
      assign wh_arr[HALF_A_SIZE-1-i] = wh_data_reg[WH_WIDTH-1-i*WH_DATA_WIDTH : WH_WIDTH-(i+1)*WH_DATA_WIDTH];
    end
  endgenerate
  //* =======================================


  //* ======== Pipeline calculation =========
  assign source_dmvm = (pipe_src_flag_reg[5] == 1'b1) ? pipe_prod_reg[5][0] : source_dmvm_reg;
  assign pipe_coef   = (pipe_prod_reg[5][0] + source_dmvm) >> (DMVM_DATA_WIDTH - DATA_WIDTH);

  // -- src_flag
  generate
    for (i = 0; i < NUM_STAGES; i = i + 1) begin
      assign pipe_src_flag[i]  = (i == 0) ? src_flag : pipe_src_flag_reg[i];
    end
  endgenerate

  // -- calculation
  generate
    for (i = 0; i < NUM_STAGES; i = i + 1) begin
      if (i == 0) begin
        for (k = 0; k < HALF_A_SIZE; k = k + 1) begin
          assign pipe_prod[i][k] = (src_flag) ? ($signed(a_src[k]) * $signed(wh_arr[k])) : ($signed(a_nbr[k]) * $signed(wh_arr[k]));
        end
      end else begin
        for (k = 0; k < HALF_A_SIZE / (1 << i); k = k + 1) begin
          assign pipe_prod[i][k] = $signed(pipe_prod_reg[i][2*k]) + $signed(pipe_prod_reg[i][2*k+1]);
        end
      end
    end
  endgenerate

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      source_dmvm_reg <= 'b0;
    end else begin
      source_dmvm_reg <= source_dmvm;
    end
  end

  generate
    for (i = 0; i < NUM_STAGES; i = i + 1) begin
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          pipe_prod_reg[i+1]      <= 'b0;
          pipe_src_flag_reg[i+1]  <= 'b0;
        end else begin
          pipe_prod_reg[i+1]      <= pipe_prod[i];
          pipe_src_flag_reg[i+1]  <= pipe_src_flag[i];
        end
      end
    end
  endgenerate
  //* =======================================


  //* ========== Write [e] to ff ==========
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pipe_coef_reg <= 'b0;
    end else begin
      pipe_coef_reg <= pipe_coef;
    end
  end

  assign coef_ff_din      = (pipe_coef_reg[DATA_WIDTH-1] == 1'b0) ? pipe_coef_reg : 'b0;
  assign coef_ff_wr_vld   = dmvm_rdy_reg && !coef_ff_full;
  //* =======================================


  //* ============ dmvm_ready ===============
  always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			vld_shft_reg  <= 'b0;
			dmvm_rdy_reg  <= 'b0;
		end else begin
			vld_shft_reg <= { vld_shft_reg[COEF_DELAY_LENGTH-2:0], dmvm_vld_i };
			dmvm_rdy_reg  <= vld_shft_reg[COEF_DELAY_LENGTH-1];
		end
	end
  //* =======================================
endmodule