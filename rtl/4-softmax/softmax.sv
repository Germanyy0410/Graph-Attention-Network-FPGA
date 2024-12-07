`include "./../others/pkgs/params_pkg.sv"

module softmax import params_pkg::*;
(
  input                                               clk               ,
  input                                               rst_n             ,

  input                                               sm_valid_i        ,
  output                                              sm_ready_o        ,
  output                                              sm_pre_ready_o    ,

  input   [NUM_OF_NODES-1:0] [DATA_WIDTH-1:0]         coef_i            ,
  input   [NUM_NODE_WIDTH-1:0]                        num_of_nodes      ,

  output  [NUM_OF_NODES-1:0] [ALPHA_DATA_WIDTH-1:0]   alpha_o           ,
  output  [NUM_NODE_WIDTH-1:0]                        sm_num_of_nodes_o
);
  logic                                             sm_ready              ;
  logic                                             sm_ready_reg          ;
  logic [NUM_NODE_WIDTH-1:0]                        sm_num_of_nodes       ;
  logic [NUM_NODE_WIDTH-1:0]                        sm_num_of_nodes_reg   ;

  logic [NUM_OF_NODES-1:0] [ALPHA_DATA_WIDTH-1:0]   alpha                 ;
  logic [NUM_OF_NODES-1:0] [ALPHA_DATA_WIDTH-1:0]   alpha_reg             ;
  logic [NUM_OF_NODES-1:0] [SM_DATA_WIDTH-1:0]      exp                   ;
  logic [NUM_OF_NODES-1:0] [SM_DATA_WIDTH-1:0]      exp_reg               ;

  logic [NUM_OF_NODES-1:0] [SM_DATA_WIDTH-1:0]      exp_calc              ;
  logic [NUM_OF_NODES-1:0] [SM_DATA_WIDTH-1:0]      exp_calc_reg          ;

  logic [NUM_NODE_WIDTH-1:0]                        arr_size              ;
  logic [NUM_NODE_WIDTH-1:0]                        arr_size_reg          ;
  logic                                             exp_done              ;
  logic                                             exp_done_reg          ;

  logic [SM_SUM_DATA_WIDTH-1:0]                     sum_result            ;
  logic [SM_SUM_DATA_WIDTH-1:0]                     sum_result_reg        ;
  logic [SM_SUM_DATA_WIDTH-1:0]                     sum_extra             ;
  logic [SM_SUM_DATA_WIDTH-1:0]                     sum_extra_reg         ;

  logic                                             sum_done              ;
  logic                                             sum_done_reg          ;

  // -- [division] IN
  logic [SM_DATA_WIDTH-1:0]                         in                    ;
  logic [SM_DATA_WIDTH-1:0]                         in_reg                ;
  logic [NUM_NODE_WIDTH-1:0]                        i_idx_cnt             ;
  logic [NUM_NODE_WIDTH-1:0]                        i_idx_cnt_reg         ;

  // -- [division] delay
  logic [DL_DATA_WIDTH-1:0]                         delay_cnt             ;
  logic [DL_DATA_WIDTH-1:0]                         delay_cnt_reg         ;

  // -- [division] OUT
  logic [NUM_NODE_WIDTH-1:0]                        o_idx_cnt             ;
  logic [NUM_NODE_WIDTH-1:0]                        o_idx_cnt_reg         ;
  logic                                             output_control        ;
  logic                                             output_control_reg    ;
  logic [ALPHA_DATA_WIDTH-1:0]                      out                   ;
  logic [ALPHA_DATA_WIDTH-1:0]                      out_reg               ;

  integer i;
  genvar x;

  //* ===================== output assignment ======================
  generate
    for(x = 0; x < NUM_OF_NODES; x = x + 1) begin
      assign alpha_o[x] = alpha_reg[x];
    end
  endgenerate

  assign sm_ready_o         = sm_ready_reg;
  assign sm_pre_ready_o     = sm_ready;
  assign sm_num_of_nodes_o  = sm_num_of_nodes_reg;
  //* ==============================================================


  //* ======================== exp(x) & sum ========================
  always_comb begin
    exp_done  = exp_done_reg;
    arr_size  = arr_size_reg;
    sum_extra = sum_extra_reg;

    for(i = 0; i < NUM_OF_NODES; i = i + 1) begin
      exp[i]      = exp_reg[i];
      exp_calc[i] = exp_calc_reg[i];
    end

    if(sm_valid_i && ~exp_done_reg) begin
      for(i = 0; i < NUM_OF_NODES; i = i + 1) begin
        if (i < num_of_nodes) begin
          exp[i]      = (coef_i[i] == ZERO) ? 1 : (1 << coef_i[i]);
          exp_calc[i] = (coef_i[i] == ZERO) ? 1 : (1 << coef_i[i]);
        end
      end
      arr_size  = num_of_nodes;
      exp_done  = 1;
      sum_extra = 0;
    end else if (exp_done_reg) begin
      if(arr_size_reg > 1) begin
        for(i = 0; i < NUM_OF_NODES/2; i = i + 1) begin
          if(i < arr_size_reg) begin
            sum_extra = (arr_size_reg[0] == 1'b1) ? (exp_reg[arr_size_reg-1] + sum_extra_reg) : sum_extra_reg;
            exp[i]    = exp_reg[2*i] + exp_reg[2*i+1];
            arr_size  = arr_size_reg >> 1;
          end
        end
      end else begin
        exp_done = 0;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      arr_size_reg    <= NUM_OF_NODES;
      exp_done_reg    <= 0;
      exp_reg         <= '0;
      exp_calc_reg    <= '0;
    end else begin
      arr_size_reg    <= arr_size;
      exp_done_reg    <= exp_done;
      exp_reg         <= exp;
      exp_calc_reg    <= exp_calc;
    end
  end
  //* ==============================================================


  //* ============================ sum =============================
  always_comb begin
    sum_done = sum_done_reg;
    if ((sm_valid_i && ~exp_done_reg) || (delay_cnt_reg == WOI + WOF + 3)) begin
      sum_done = 1'b0;
    end else if (arr_size_reg == 1) begin
      sum_done = 1'b1;
    end
  end

  always_comb begin
    sum_result = sum_result_reg;
    if (num_of_nodes % 2 == 1 && delay_cnt_reg == 0) begin
      sum_result = exp_reg[0] + exp_reg[num_of_nodes-1] + sum_extra_reg;
    end else if (delay_cnt_reg == 0) begin
      sum_result = exp_reg[0] + sum_extra_reg;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      sum_done_reg    <= 0;
      sum_extra_reg   <= 0;
      sum_result_reg  <= 0;
    end else begin
      sum_done_reg    <= sum_done;
      sum_extra_reg   <= sum_extra;
      sum_result_reg  <= sum_result;
    end
  end
  //* ==============================================================


  //* ========================= i_idx_cnt ==========================
  assign in = (sum_done_reg) ? exp_calc_reg[i_idx_cnt_reg] : in_reg;

  always_comb begin
    i_idx_cnt = i_idx_cnt_reg;
    if (sum_done_reg && (i_idx_cnt_reg < num_of_nodes - 1)) begin
      i_idx_cnt = i_idx_cnt_reg + 1;
    end else if (sm_valid_i) begin
      i_idx_cnt = 0;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      in_reg        <= 0;
      i_idx_cnt_reg <= 0;
    end else begin
      in_reg        <= in;
      i_idx_cnt_reg <= i_idx_cnt;
    end
  end
  //* ==============================================================


  //* ========================= delay_cnt ==========================
  always_comb begin
    delay_cnt = delay_cnt_reg;
    if (sum_done_reg && delay_cnt_reg < WOI + WOF + 3) begin
      delay_cnt = delay_cnt_reg + 1;
    end else if (sm_valid_i) begin
      delay_cnt = 0;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      delay_cnt_reg <= 0;
    end else begin
      delay_cnt_reg <= delay_cnt;
    end
  end
  //* ==============================================================


  //* ======================= output_control =======================
  always_comb begin
    output_control = output_control_reg;
    if (sum_done_reg && delay_cnt_reg == WOI + WOF + 3) begin
      output_control = 1;
    end else if (sm_ready) begin
      output_control = 0;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      output_control_reg <= 0;
    end else begin
      output_control_reg <= output_control;
    end
  end
  //* ==============================================================


  //* ========================= o_idx_cnt ==========================
  always_comb begin
    o_idx_cnt = o_idx_cnt_reg;

    if ((output_control_reg == 1) && (o_idx_cnt_reg < num_of_nodes - 1) && (~sm_ready_reg))  begin
      o_idx_cnt = o_idx_cnt_reg + 1;
    end else if (o_idx_cnt_reg >= num_of_nodes - 1) begin
      o_idx_cnt = 0;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      out_reg       <= 0;
      o_idx_cnt_reg <= 0;
    end else begin
      out_reg       <= out;
      o_idx_cnt_reg <= o_idx_cnt;
    end
  end
  //* ==============================================================


  //* =========================== alpha ============================
  always_comb begin
    for (int i = 0; i < NUM_OF_NODES; i = i + 1) begin
      alpha[i] = alpha_reg[i];
    end
    if ((output_control_reg == 1) && (o_idx_cnt_reg < num_of_nodes) && (~sm_ready_reg)) begin
      alpha[o_idx_cnt_reg]  = out_reg;
    end else if (sm_valid_i) begin
      for (int i = 0; i < NUM_OF_NODES; i = i + 1) begin
        alpha[i] = 0;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      alpha_reg <= '0;
    end else begin
      alpha_reg <= alpha;
    end
  end
  //* ==============================================================


  //* ========================= sm_ready ===========================
  always_comb begin
    sm_ready  = sm_ready_reg;
    if (sm_ready_reg) begin
      sm_ready = 1'b0;
    end else if (o_idx_cnt_reg >= num_of_nodes - 1) begin
      sm_ready  = 1'b1;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sm_ready_reg <= 0;
    end else begin
      sm_ready_reg <= sm_ready;
    end
  end
  //* ==============================================================


  //* ====================== sm_num_of_nodes =======================
  assign sm_num_of_nodes = (sm_ready) ? num_of_nodes : sm_num_of_nodes_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sm_num_of_nodes_reg <= 0;
    end else begin
      sm_num_of_nodes_reg <= sm_num_of_nodes;
    end
  end
  //* ==============================================================

  (* dont_touch = "yes" *)
  fxp_div_pipe #(
    .WIIA     (SM_DATA_WIDTH      ),
    .WIFA     (0                  ),
    .WIIB     (SM_SUM_DATA_WIDTH  ),
    .WIFB     (0                  ),
    .WOI      (WOI                ),
    .WOF      (WOF                ),
    .ROUND    (0                  )
  ) u_fxp_div_pipe (
    .clk      (clk                ),
    .rstn     (rst_n              ),
    .dividend (in                 ),
    .divisor  (sum_result_reg     ),
    .out      (out                )
  );
endmodule

