`include "./../others/pkgs/params_pkg.sv"

module DMVM import params_pkg::*;
(
  input                                         clk                 ,
  input                                         rst_n               ,

  input                                         dmvm_valid_i        ,
  output                                        dmvm_ready_o        ,
  // -- a
  input                                         a_valid_i           ,
  input   [A_DEPTH-1:0] [DATA_WIDTH-1:0]        a_i                 ,
  // -- WH BRAM
  input   [WH_WIDTH-1:0]                        WH_BRAM_dout        ,
  output  [WH_1_ADDR_W-1:0]                     WH_BRAM_addrb       ,
  // -- output
  output  [DATA_WIDTH-1:0]                      coef_FIFO_din       ,
  input                                         coef_FIFO_full      ,
  output                                        coef_FIFO_wr_vld
);
  localparam NUM_STAGES = $clog2(NUM_FEATURE_OUT) + 1;
  localparam COEF_DELAY_LENGTH = NUM_STAGES + 1;

  //* ========== logic declaration ===========
  // -- Weight vector a1 & a2
  logic [HALF_A_SIZE-1:0] [DATA_WIDTH-1:0]                        a_source            ;
  logic [HALF_A_SIZE-1:0] [DATA_WIDTH-1:0]                        a_neighbor          ;

  // -- capture [dout]
  logic                                                           WH_read_delay       ;
  logic [WH_WIDTH-1:0]                                            WH_BRAM_data        ;
  logic [WH_WIDTH-1:0]                                            WH_BRAM_data_reg    ;

  // -- WH data
  logic [WH_1_ADDR_W-1:0]                                         WH_addr             ;
  logic [WH_1_ADDR_W-1:0]                                         WH_addr_reg         ;
  logic [HALF_A_SIZE-1:0] [WH_DATA_WIDTH-1:0]                     WH_arr              ;
  logic                                                           source_node_flag    ;

  logic [NUM_NODE_WIDTH-1:0]                                      num_of_nodes        ;


  // -- pipeline [NUM_FEATURE_OUT + 1] stages
  logic [NUM_STAGES-1:0]                                          pipe_src_flag       ;
  logic [NUM_STAGES:0]                                            pipe_src_flag_reg   ;
  logic [DMVM_DATA_WIDTH-1:0]                                     source_dmvm         ;
  logic [DMVM_DATA_WIDTH-1:0]                                     source_dmvm_reg     ;
  logic [DATA_WIDTH-1:0]                                          pipe_coef           ;
  logic [NUM_STAGES-1:0] [HALF_A_SIZE-1:0] [DMVM_DATA_WIDTH-1:0]  pipe_product        ;
  logic [NUM_STAGES:0] [HALF_A_SIZE-1:0] [DMVM_DATA_WIDTH-1:0]    pipe_product_reg    ;

  // -- output
  logic [COEF_DELAY_LENGTH-1:0]                                   valid_shift_reg     ;
  logic                                                           dmvm_ready_reg      ;

  //* =======================================

  genvar i, k;
  integer x;

  //* ========== output assignment ==========
  assign dmvm_ready_o   = dmvm_ready_reg;
  //* =======================================


  //* ========== split vector [a] ===========
  generate
    for (i = 0; i < HALF_A_SIZE; i = i + 1) begin
      assign a_source[HALF_A_SIZE-1-i] = a_i[i];
    end

    for (i = 0; i < HALF_A_SIZE; i = i + 1) begin
      assign a_neighbor[HALF_A_SIZE-1-i] = a_i[i + HALF_A_SIZE];
    end
  endgenerate
  //* =======================================


  //* ============== WH_BRAM ================
  // -- addrb
  assign WH_BRAM_addrb  = WH_addr_reg;
  assign WH_addr = (dmvm_valid_i) ? ((WH_addr_reg < WH_1_DEPTH - 1) ? (WH_addr_reg + 1) : 0) : WH_addr_reg;

  // -- capture [dout]
  always_ff @(posedge clk) begin
    WH_read_delay <= (WH_addr != WH_addr_reg);
  end
  assign WH_BRAM_data = WH_read_delay ? WH_BRAM_dout : WH_BRAM_data_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      WH_addr_reg       <= '0;
      WH_BRAM_data_reg  <= '0;
    end else begin
      WH_addr_reg       <= WH_addr;
      WH_BRAM_data_reg  <= WH_BRAM_data;
    end
  end
  //* =======================================


  //* ======= get WH data from BRAM =========
  assign source_node_flag = WH_BRAM_data_reg[0];
  assign num_of_nodes     = WH_BRAM_data_reg[NUM_NODE_WIDTH:1];

  generate
    for (i = 0; i < HALF_A_SIZE; i = i + 1) begin
      assign WH_arr[HALF_A_SIZE-1-i] = WH_BRAM_data_reg[WH_WIDTH-1-i*WH_DATA_WIDTH : WH_WIDTH-(i+1)*WH_DATA_WIDTH];
    end
  endgenerate
  //* =======================================


  //* ======== Pipeline calculation =========
  assign source_dmvm = (pipe_src_flag_reg[5] == 1'b1) ? pipe_product_reg[5][0] : source_dmvm_reg;
  assign pipe_coef   = (pipe_product_reg[5][0] + source_dmvm) >> (DMVM_DATA_WIDTH - DATA_WIDTH);

  // -- src_flag
  generate
    for (i = 0; i < NUM_STAGES; i = i + 1) begin
      assign pipe_src_flag[i]  = (i == 0) ? source_node_flag : pipe_src_flag_reg[i];
    end
  endgenerate

  // -- calculation
  generate
    for (i = 0; i < NUM_STAGES; i = i + 1) begin
      if (i == 0) begin
        for (k = 0; k < HALF_A_SIZE; k = k + 1) begin
          assign pipe_product[i][k] = (source_node_flag) ? ($signed(a_source[k]) * $signed(WH_arr[k])) : ($signed(a_neighbor[k]) * $signed(WH_arr[k]));
        end
      end else begin
        for (k = 0; k < HALF_A_SIZE / (1 << i); k = k + 1) begin
          assign pipe_product[i][k] = $signed(pipe_product_reg[i][2*k]) + $signed(pipe_product_reg[i][2*k+1]);
        end
      end
    end
  endgenerate

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      source_dmvm_reg <= 0;
    end else begin
      source_dmvm_reg <= source_dmvm;
    end
  end

  generate
    for (i = 0; i < NUM_STAGES; i = i + 1) begin
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          pipe_product_reg[i+1]   <= '0;
          pipe_src_flag_reg[i+1]  <= '0;
        end else begin
          pipe_product_reg[i+1]   <= pipe_product[i];
          pipe_src_flag_reg[i+1]  <= pipe_src_flag[i];
        end
      end
    end
  endgenerate
  //* =======================================


  //* ========== Write [e] to FIFO ==========
  assign coef_FIFO_din      = pipe_coef;
  assign coef_FIFO_wr_vld   = dmvm_ready_reg && !coef_FIFO_full;
  //* =======================================


  //* ============ dmvm_ready ===============
  always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			valid_shift_reg <= '0;
			dmvm_ready_reg  <= 1'b0;
		end else begin
			valid_shift_reg <= {valid_shift_reg[COEF_DELAY_LENGTH-2:0], dmvm_valid_i};
			dmvm_ready_reg  <= valid_shift_reg[COEF_DELAY_LENGTH-1];
		end
	end
  //* =======================================
endmodule