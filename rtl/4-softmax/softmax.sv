module softmax #(
  parameter DATA_WIDTH = 8,
  parameter MAX_NODES      = 168,
  parameter NODE_WIDTH    =  $clog2(MAX_NODES)
)(
  input clk,
  input rst_n,

  input sm_valid_i,
  output sm_ready_o,

  input   [DATA_WIDTH-1:0]  coef_i      [0:MAX_NODES-1],  
  input  [NODE_WIDTH-1:0] num_of_nodes,
  output  [12-1:0]  alpha_o [0:MAX_NODES-1]    
  );

  reg sm_ready_reg;
  reg sm_ready;
  reg [12-1:0] alpha [0:MAX_NODES-1];
  reg [12-1:0] alpha_reg [0:MAX_NODES-1];
  reg [DATA_WIDTH-1:0] exp_reg [0:MAX_NODES-1];
  reg [DATA_WIDTH-1:0] exp [0:MAX_NODES-1];

  reg [DATA_WIDTH-1:0] exp_calc [0:MAX_NODES-1];
  reg [DATA_WIDTH-1:0] exp_calc_reg [0:MAX_NODES-1];
  
  
  reg [NODE_WIDTH-1:0] arr_size_reg;
  reg [NODE_WIDTH-1:0] arr_size;
  reg done_exp_reg;
  reg done_exp;

  // reg [DATA_WIDTH-1:0] sum_exp_reg;
  reg [DATA_WIDTH-1:0] sum_exp;
  reg [DATA_WIDTH-1:0] sum_result;
  reg [DATA_WIDTH-1:0] sum_result_reg;


  reg sum_done_reg;
  reg sum_done;

  reg [NODE_WIDTH-1:0] i_idx_cnt;  
  reg [NODE_WIDTH-1:0] i_idx_cnt_reg;
  reg [NODE_WIDTH-1:0] o_idx_cnt;
  reg [NODE_WIDTH-1:0] o_idx_cnt_reg;
  reg [3:0] delay_cnt;
  reg [3:0] delay_cnt_reg;
  reg output_control_reg;
  reg output_control;

  reg [11:0] out;
  reg [11:0] out_reg;
  reg [7:0] in;
  reg [7:0] in_reg;

  // index use-in
  localparam WOI = 1; // WIDTH OUTPUT INTEGER
  localparam WOF = 11; // WIDTH OUTPUT FRACTION
  integer i;

/* COMBINATIONAL LOGIC */
  always @(*) begin
    done_exp = done_exp_reg;
    arr_size = arr_size_reg;
    sum_done = sum_done_reg;
    // sum_exp = sum_exp_reg;
    for(i = 0; i < MAX_NODES; i = i + 1) begin
      exp[i] = exp_reg[i];
      exp_calc[i] = exp_calc_reg[i];
    end
    sum_exp = 0;

    if(sm_valid_i && ~done_exp_reg) begin
      for(i = 0; i < MAX_NODES; i = i + 1) begin
        if (i < num_of_nodes) begin
          exp[i] = 1 << coef_i[i];
          exp_calc[i] = 1 << coef_i[i];
        end
      end
      done_exp = 1;
    end else if (done_exp_reg) begin
      if(arr_size_reg > 1) begin
        for(i = 0; i < MAX_NODES/2; i = i + 1) begin
          if(i < arr_size_reg) begin
            sum_exp = exp_reg[2*i] + exp_reg[2*i+1];
            // overflow
            exp[i] = sum_exp;
            arr_size = arr_size_reg >> 1;
          end
        end //for
      end else begin // arr_size_reg < 1
        // if(MAX_NODES % 2 == 1) begin
        //   sum_exp = exp_reg[0] + exp_reg[MAX_NODES-1];
        // end else begin
        //   sum_exp = exp_reg[0];
        // end
        done_exp = 0;
        arr_size = num_of_nodes;
        sum_done = 1;
      end
    end
  end

  always @(*) begin
    sum_result = sum_result_reg;
    if(num_of_nodes % 2 == 1) begin
      sum_result = exp_reg[0] + exp_reg[num_of_nodes-1];
    end else begin
      sum_result = exp_reg[0];
    end
  end
  always @(posedge clk) begin
    if(!rst_n) begin
      sum_result_reg <= 0;
    end
    else begin
      sum_result_reg <= sum_result;
    end
  end
  // always @(*) begin
  //   sm_ready = sm_ready_reg;
  //   if ((~sm_ready_reg)) begin
  //     sm_ready = 1'b1;
  //   end else if (sm_ready_reg) begin
  //     sm_ready = 1'b0;
  //   end
  // end

  always @(*) begin
    in = in_reg;
    i_idx_cnt = i_idx_cnt_reg;
    delay_cnt = delay_cnt_reg;
    output_control = output_control_reg;
    if(sum_done_reg) begin
      if (i_idx_cnt_reg < MAX_NODES - 1) begin
        i_idx_cnt = i_idx_cnt_reg + 1;
      end
      else begin
        i_idx_cnt = 0;
      end 
      if (delay_cnt_reg < WOI + WOF + 3) begin
        delay_cnt = delay_cnt_reg + 1;
      end
      else begin
        output_control = 1;
        delay_cnt = 0;
      end 
      in = exp_calc_reg[i_idx_cnt_reg];
    end else if (~sum_done_reg) begin
      i_idx_cnt = 0;
      delay_cnt = 0;
      output_control = 0;
    end
  end



  //start count output
  always @(*) begin
    o_idx_cnt = o_idx_cnt_reg;
    sm_ready = sm_ready_reg;
    // alpha[o_idx_cnt] = alpha_reg[o_idx_cnt];
    for (int i = 0; i < MAX_NODES; i = i + 1) begin
      alpha[i] = alpha_reg[i];
    end
    if (output_control_reg == 1 && o_idx_cnt_reg < num_of_nodes && !sm_ready_reg)  begin
      alpha[o_idx_cnt_reg] = out_reg;
      o_idx_cnt = o_idx_cnt_reg + 1; 
    end
    else if (o_idx_cnt_reg >= num_of_nodes) begin
      o_idx_cnt = 0;
      sm_ready = 1'b1;
    end
  end

  // always @(*) begin
  //   in = in_reg;
  //   if (sum_done_reg) begin
  //     in = exp_calc_reg[i_idx_cnt_reg];
  //   end
  // end
  genvar x; 
  generate
    for(x = 0; x < MAX_NODES; x = x + 1) begin
      assign alpha_o[x] = alpha_reg[x];
    end
  endgenerate
/* COMBINATIONAL LOGIC */


/* SEQUENTIAL LOGIC */
  always @(posedge clk) begin
    if (!rst_n) begin
      sm_ready_reg <= 0;
    end else begin
      sm_ready_reg <= sm_ready;
    end
  end

  always @(posedge clk) begin
    if(!rst_n) begin
      output_control_reg <= 0;
    end
    else begin 
      output_control_reg <= output_control;
    end
  end
  always @(posedge clk) begin
    if(!rst_n) begin
      arr_size_reg <= MAX_NODES;
    end else begin
      arr_size_reg <= arr_size;
    end
  end

  always @(posedge clk) begin
    for(i = 0; i < MAX_NODES; i = i + 1) begin
      if(!rst_n) begin
        exp_reg[i] <= 0;
      end else begin
        exp_reg[i] <= exp[i];
      end
    end
  end

  
 

  //sum_exp_reg//done_exp_reg
  always @(posedge clk) begin
    if(!rst_n) begin
      // sum_exp_reg <= 0;
      done_exp_reg <= 0;
      sum_done_reg <= 0;
    end else begin
      // sum_exp_reg <= sum_exp;
      done_exp_reg <= done_exp;
      sum_done_reg <= sum_done;
    end
  end //always

  // divider control
  always @(posedge clk) begin
    if(!rst_n) begin
      i_idx_cnt_reg <= 0;
    end else begin
      i_idx_cnt_reg <= i_idx_cnt;
    end
  end 

  always @(posedge clk) begin
    if(!rst_n) begin
      o_idx_cnt_reg <= 0;
    end else begin
      o_idx_cnt_reg <= o_idx_cnt;
    end 
  end
  
  always @(posedge clk) begin
    if(!rst_n) begin
      delay_cnt_reg <= 0;
    end else begin
      delay_cnt_reg <= delay_cnt;
    end
  end
  
  
  generate
    for(x = 0; x < MAX_NODES; x = x + 1) begin
      always @(posedge clk) begin
        if(!rst_n) begin
          exp_calc_reg[x] <= 0;
        end else begin
          exp_calc_reg[x] <= exp_calc[x];
        end
      end
    end
  endgenerate
  
   
  always @(posedge clk) begin
    if (!rst_n) begin
      in_reg <= 0;
    end else begin 
      in_reg <= in;
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      out_reg <= 0;
    end else begin
      out_reg <= out;
    end
  end
  generate 
    for (x = 0; x < MAX_NODES; x = x + 1) begin 
      always @(posedge clk) begin
        if (!rst_n) begin
          alpha_reg[x] <= 0;
        end else begin
          alpha_reg[x] <= alpha[x];
        end  
      end
    end 
  endgenerate
/* SEQUENTIAL LOGIC */
   
  // DIVIDER PIPELINE
  fxp_div_pipe #(
      .WIIA(8),
      .WIFA(0),
      .WIIB(8),
      .WIFB(0),
      .WOI(WOI),
      .WOF(WOF),
      .ROUND(0)
  ) u_fxp_div_pipe (
      .rstn    (rst_n),
      .clk     (clk),
      .dividend(in),
      .divisor (sum_result_reg),
      .out     (out)
  );
  assign sm_ready_o = sm_ready_reg;
endmodule

