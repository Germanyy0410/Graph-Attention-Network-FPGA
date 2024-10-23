// module H_loader #(
//   //* ========== parameter ===========
//   parameter DATA_WIDTH        = 8                           ,
//   parameter NUM_OF_COLS       = 500                         ,
//   parameter NUM_OF_ROWS       = 168                         ,

//   parameter GCSR_SIZE         = 30                          ,
//   parameter COL_INDEX_SIZE    = 500                         ,
//   parameter VALUE_SIZE        = 500                         ,
//   parameter NODE_INFO_SIZE    = NUM_OF_ROWS                 ,
//   // -- BRAM
//   parameter BRAM_ADDR_WIDTH   = 32                          ,

//   //* ========= localparams ==========
//   parameter INDEX_WIDTH       = $clog2(COL_INDEX_SIZE)      ,
//   parameter IDX_WIDTH         = $clog2(NUM_OF_ROWS)         ,
//   // -- -- col_idx
//   parameter COL_IDX_WIDTH     = $clog2(NUM_OF_COLS)         ,
//   // -- -- value
//   parameter VALUE_WIDTH       = DATA_WIDTH                  ,
//   // -- -- node_info = [row_len, flag]
//   parameter ROW_LEN_WIDTH     = $clog2(NUM_OF_COLS)         ,
//   parameter NODE_INFO_WIDTH   = ROW_LEN_WIDTH + 1           ,
//   // -- outputs
//   parameter FF_DATA_WIDTH     = COL_IDX_WIDTH + VALUE_WIDTH
// )(
//   input   clk,
//   input   rst_n,
//   // -- H_col_idx BRAM
//   input   [COL_IDX_WIDTH-1:0]       H_col_idx_BRAM_dout                                         ,
//   output                            H_col_idx_BRAM_en                                           ,
//   output  [BRAM_ADDR_WIDTH-1:0]     H_col_idx_BRAM_addr                                         ,
//   // -- H_value BRAM
//   input   [VALUE_WIDTH-1:0]         H_value_BRAM_dout                                           ,
//   output                            H_value_BRAM_en                                             ,
//   output  [BRAM_ADDR_WIDTH-1:0]     H_value_BRAM_addr                                           ,
//   // -- H_node_info BRAM
//   input   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout                                       ,
//   output                            H_node_info_BRAM_en                                         ,
//   output  [BRAM_ADDR_WIDTH-1:0]     H_node_info_BRAM_addr                                       ,

//   output                            h_ready_o                                                   ,
//   output  [COL_IDX_WIDTH-1:0]       row_col_idx_o   [0:NUM_OF_ROWS-1] [0:GCSR_SIZE-1]           ,
//   output  [VALUE_WIDTH-1:0]         row_value_o     [0:NUM_OF_ROWS-1] [0:GCSR_SIZE-1]           ,
//   output  [NODE_INFO_WIDTH-1:0]     row_info_o      [0:NUM_OF_ROWS-1]                           ,
//   output  [IDX_WIDTH-1:0]           num_of_nodes_o
// );
//   //* ========== wire declaration ===========
//   // -- GCSR format
//   // -- output wire
//   wire                            h_ready                                                     ;
//   wire  [COL_IDX_WIDTH-1:0]       row_col_idx       [0:NUM_OF_ROWS-1] [0:GCSR_SIZE-1]         ;
//   wire  [VALUE_WIDTH-1:0]         row_value         [0:NUM_OF_ROWS-1] [0:GCSR_SIZE-1]         ;
//   wire  [NODE_INFO_WIDTH-1:0]     row_info          [0:NUM_OF_ROWS-1]                         ;
//   // -- BRAM
//   wire  [BRAM_ADDR_WIDTH-1:0]     cv_addr                                                     ;
//   wire  [BRAM_ADDR_WIDTH-1:0]     n_addr                                                      ;
//   //* =======================================


//   //* =========== reg declaration ===========
//   // -- GCSR format
//   reg   [COL_IDX_WIDTH-1:0]       col_idx           [0:COL_INDEX_SIZE-1]                      ;
//   reg   [COL_IDX_WIDTH-1:0]       col_idx_reg       [0:COL_INDEX_SIZE-1]                      ;
//   reg   [VALUE_WIDTH-1:0]         value             [0:VALUE_SIZE-1]                          ;
//   reg   [VALUE_WIDTH-1:0]         value_reg         [0:VALUE_SIZE-1]                          ;
//   reg   [NODE_INFO_WIDTH-1:0]     node_info         [0:NODE_INFO_SIZE-1]                      ;
//   reg   [NODE_INFO_WIDTH-1:0]     node_info_reg     [0:NODE_INFO_SIZE-1]                      ;
//   // -- -- array length
//   reg   [INDEX_WIDTH-1:0]         cv_length                                                   ;
//   reg   [IDX_WIDTH-1:0]           node_info_length                                            ;
//   // -- -- counter
//   reg   [INDEX_WIDTH-1:0]         cv_counter                                                  ;
//   reg   [INDEX_WIDTH-1:0]         cv_counter_reg                                              ;
//   reg   [IDX_WIDTH-1:0]           n_counter                                                   ;
//   reg   [IDX_WIDTH-1:0]           n_counter_reg                                               ;
//   // -- start_idx calculation
//   reg   [INDEX_WIDTH-1:0]         start_idx         [0:NODE_INFO_SIZE-1]                      ;
//   reg   [INDEX_WIDTH-1:0]         start_idx_reg     [0:NODE_INFO_SIZE-1]                      ;
//   reg   [INDEX_WIDTH-1:0]         idx                                                         ;
//   reg   [INDEX_WIDTH-1:0]         idx_reg                                                     ;
//   reg   [INDEX_WIDTH-1:0]         sum                                                         ;
//   reg   [INDEX_WIDTH-1:0]         sum_reg                                                     ;
//   // -- BRAM
//   reg   [BRAM_ADDR_WIDTH-1:0]     cv_addr_reg                                                 ;
//   reg   [BRAM_ADDR_WIDTH-1:0]     n_addr_reg                                                  ;
//   // -- output
//   reg                             h_ready_reg                                                 ;
//   reg   [COL_IDX_WIDTH-1:0]       row_col_idx_reg   [0:NUM_OF_ROWS-1] [0:GCSR_SIZE-1]         ;
//   reg   [VALUE_WIDTH-1:0]         row_value_reg     [0:NUM_OF_ROWS-1] [0:GCSR_SIZE-1]         ;
//   reg   [NODE_INFO_WIDTH-1:0]     row_info_reg      [0:NUM_OF_ROWS-1]                         ;
//   //* =======================================


//   //* ========= internal declaration ========
//   genvar i;
//   integer x;
//   genvar row_counter, col_counter;
//   //* =======================================


//   //* ========== output assignment ==========
//   assign h_ready_o              = h_ready_reg;
//   assign H_col_idx_BRAM_addr    = cv_addr_reg;
//   assign H_value_BRAM_addr      = cv_addr_reg;
//   assign H_node_info_BRAM_addr  = n_addr_reg;
//   assign row_col_idx_o          = row_col_idx_reg;
//   assign row_value_o            = row_value_reg;
//   assign row_info_o             = row_info_reg;
//   //* =======================================


//   //* =========== Get H from BRAM ===========
//   // -- addr
//   assign cv_addr = cv_addr_reg + 1;
//   assign n_addr  = n_addr_reg + 1;

//   always @(posedge clk) begin
//     if (!rst_n) begin
//       cv_addr_reg <= 0;
//       n_addr_reg  <= 0;
//     end else begin
//       cv_addr_reg <= cv_addr;
//       n_addr_reg  <= n_addr;
//     end
//   end

//   // -- col_idx & value counter
//   always @(*) begin
//     cv_counter = cv_counter_reg;
//     for (x = 0; x < COL_INDEX_SIZE; x = x + 1) begin
//       col_idx[x]  = col_idx_reg[x];
//       value[x]    = value_reg[x];
//     end

//     if (cv_counter_reg < cv_length) begin
//       col_idx[cv_counter_reg] = H_col_idx_BRAM_dout;
//       value[cv_counter_reg]   = H_value_BRAM_dout;
//       cv_counter              = cv_counter_reg + 1;
//     end
//   end

//   // -- node_info counter
//   always @(*) begin
//     n_counter = n_counter_reg;
//     for (x = 0; x < NODE_INFO_SIZE; x = x + 1) begin
//       node_info[x] = node_info_reg[x];
//     end

//     if (n_counter_reg < node_info_length) begin
//       node_info[n_counter_reg]  = H_node_info_BRAM_dout;
//       n_counter                 = n_counter_reg + 1;
//     end
//   end

//   generate
//     for (i = 0; i < COL_INDEX_SIZE; i = i + 1) begin
//       always @(posedge clk) begin
//         if (!rst_n) begin
//           col_idx_reg[i] <= 0;
//           value_reg[i]   <= 0;
//         end else begin
//           col_idx_reg[i] <= col_idx[i];
//           value_reg[i]   <= value_reg[i];
//         end
//       end
//     end
//     for (i = 0; i < NODE_INFO_SIZE; i = i + 1) begin
//       always @(posedge clk) begin
//         if (!rst_n) begin
//           node_info_reg[i] <= 0;
//         end else begin
//           node_info_reg[i] <= node_info[i];
//         end
//       end
//     end
//   endgenerate


//   always @(posedge clk) begin
//     if (!rst_n) begin
//       cv_counter_reg  <= 0;
//       n_counter_reg   <= 0;
//     end else begin
//       cv_counter_reg  <= cv_counter;
//       n_counter_reg   <= n_counter;
//     end
//   end
//   //* =======================================


//   //* ============= [start_idx] =============
//   always @(*) begin
//     for (x = 0; x < COL_INDEX_SIZE; x = x + 1) begin
//       start_idx[x] = start_idx_reg[x];
//     end
//     sum = sum_reg;
//     idx = idx_reg;

//     if (idx_reg < NODE_INFO_SIZE && n_counter_reg > 0) begin
//       start_idx[idx_reg]  = sum_reg;
//       sum                 = sum_reg + node_info_reg[idx_reg][NODE_INFO_WIDTH-1:1];
//       idx                 = idx_reg + 1;
//     end
//   end

//   generate
//     for (i = 0; i < NODE_INFO_SIZE; i = i + 1) begin
//       always @(posedge clk) begin
//         if (!rst_n) begin
//           start_idx_reg[i]  <= 0;
//         end else begin
//           start_idx_reg[i]  <= start_idx[i];
//         end
//       end
//     end
//   endgenerate

//   always @(posedge clk) begin
//     if (!rst_n) begin
//       sum_reg <= 0;
//       idx_reg <= 0;
//     end else begin
//       sum_reg <= sum;
//       idx_reg <= idx;
//     end
//   end
//   //* =======================================


//   //* =============== h_ready ===============
//   assign h_ready = (cv_counter_reg == cv_length) ? 1'b1 : h_ready_reg;

//   always @(posedge clk) begin
//     if (!rst_n) begin
//       h_ready_reg <= 0;
//     end else begin
//       h_ready_reg <= h_ready;
//     end
//   end
//   //* =======================================


//   //* ============ extract rows =============
//   generate
//     for (row_counter = 0; row_counter < NUM_OF_ROWS; row_counter = row_counter + 1) begin
//       for (col_counter = 0; col_counter < NUM_OF_COLS; col_counter = col_counter + 1) begin
//         assign row_col_idx[row_counter][col_counter]  = (col_counter < node_info_reg[row_counter][(NODE_INFO_WIDTH-1):1])
//                                                       ? col_idx_reg[start_idx_reg[row_counter] + col_counter]
//                                                       : 0;
//         assign row_value[row_counter][col_counter]    = (col_counter < node_info_reg[row_counter][(NODE_INFO_WIDTH-1):1])
//                                                       ? value_reg[start_idx_reg[row_counter] + col_counter]
//                                                       : 0;
//       end
//       assign row_info[row_counter] = node_info_reg[row_counter];
//     end
//   endgenerate

//   generate
//     for (row_counter = 0; row_counter < NUM_OF_ROWS; row_counter = row_counter + 1) begin
//       for (col_counter = 0; col_counter < NUM_OF_COLS; col_counter = col_counter + 1) begin
//         always @(posedge clk) begin
//           row_col_idx_reg[row_counter][col_counter] <= row_col_idx[row_counter][col_counter];
//           row_value_reg[row_counter][col_counter]   <= row_value[row_counter][col_counter];
//         end
//       end
//     end
//   endgenerate
//   //* =======================================

// endmodule

module H_loader #(
  //* ========== parameter ===========
  parameter DATA_WIDTH        = 8                           ,
  parameter NUM_OF_COLS       = 500                         ,
  parameter NUM_OF_ROWS       = 168                         ,

  parameter GCSR_SIZE         = 30                          ,
  parameter COL_INDEX_SIZE    = 500                         ,
  parameter VALUE_SIZE        = 500                         ,
  parameter NODE_INFO_SIZE    = NUM_OF_ROWS                 ,
  // -- BRAM
  parameter BRAM_ADDR_WIDTH   = 32                          ,

  //* ========= localparams ==========
  parameter INDEX_WIDTH       = $clog2(COL_INDEX_SIZE)      ,
  parameter IDX_WIDTH         = $clog2(NUM_OF_ROWS)         ,
  // -- -- col_idx
  parameter COL_IDX_WIDTH     = $clog2(NUM_OF_COLS)         ,
  // -- -- value
  parameter VALUE_WIDTH       = DATA_WIDTH                  ,
  // -- -- node_info = [row_len, flag]
  parameter ROW_LEN_WIDTH     = $clog2(NUM_OF_COLS)         ,
  parameter NODE_INFO_WIDTH   = ROW_LEN_WIDTH + 1           ,
  // -- outputs
  parameter FF_DATA_WIDTH     = COL_IDX_WIDTH + VALUE_WIDTH
)(
  input   clk,
  input   rst_n,
  // -- H_col_idx BRAM
  input   [COL_IDX_WIDTH-1:0]       H_col_idx_BRAM_dout                                         ,
  output                            H_col_idx_BRAM_en                                           ,
  output  [BRAM_ADDR_WIDTH-1:0]     H_col_idx_BRAM_addr                                         ,
  // -- H_value BRAM
  input   [VALUE_WIDTH-1:0]         H_value_BRAM_dout                                           ,
  output                            H_value_BRAM_en                                             ,
  output  [BRAM_ADDR_WIDTH-1:0]     H_value_BRAM_addr                                           ,
  // -- H_node_info BRAM
  input   [NODE_INFO_WIDTH-1:0]     H_node_info_BRAM_dout                                       ,
  output                            H_node_info_BRAM_en                                         ,
  output  [BRAM_ADDR_WIDTH-1:0]     H_node_info_BRAM_addr                                       ,

  output                            h_ready_o                                                   ,
  output  [COL_IDX_WIDTH-1:0]       row_col_idx_o   [0:NUM_OF_ROWS-1] [0:GCSR_SIZE-1]           ,
  output  [VALUE_WIDTH-1:0]         row_value_o     [0:NUM_OF_ROWS-1] [0:GCSR_SIZE-1]           ,
  output  [NODE_INFO_WIDTH-1:0]     row_info_o      [0:NUM_OF_ROWS-1]                           ,
  output  [IDX_WIDTH-1:0]           num_of_nodes_o
);
  //* ========== wire declaration ===========
  // -- GCSR format
  // -- output wire
  wire                            h_ready                                                     ;
  wire  [COL_IDX_WIDTH-1:0]       row_col_idx       [0:NUM_OF_ROWS-1] [0:GCSR_SIZE-1]         ;
  wire  [VALUE_WIDTH-1:0]         row_value         [0:NUM_OF_ROWS-1] [0:GCSR_SIZE-1]         ;
  wire  [NODE_INFO_WIDTH-1:0]     row_info          [0:NUM_OF_ROWS-1]                         ;
  // -- BRAM
  wire  [BRAM_ADDR_WIDTH-1:0]     cv_addr                                                     ;
  wire  [BRAM_ADDR_WIDTH-1:0]     n_addr                                                      ;
  //* =======================================


  //* =========== reg declaration ===========
  // -- GCSR format
  reg   [COL_IDX_WIDTH-1:0]       col_idx           [0:COL_INDEX_SIZE-1]                      ;
  reg   [COL_IDX_WIDTH-1:0]       col_idx_reg       [0:COL_INDEX_SIZE-1]                      ;
  reg   [VALUE_WIDTH-1:0]         value             [0:VALUE_SIZE-1]                          ;
  reg   [VALUE_WIDTH-1:0]         value_reg         [0:VALUE_SIZE-1]                          ;
  reg   [NODE_INFO_WIDTH-1:0]     node_info         [0:NODE_INFO_SIZE-1]                      ;
  reg   [NODE_INFO_WIDTH-1:0]     node_info_reg     [0:NODE_INFO_SIZE-1]                      ;
  // -- -- array length
  reg   [INDEX_WIDTH-1:0]         cv_length                                                   ;
  reg   [IDX_WIDTH-1:0]           node_info_length                                            ;
  // -- -- counter
  reg   [INDEX_WIDTH-1:0]         cv_counter                                                  ;
  reg   [INDEX_WIDTH-1:0]         cv_counter_reg                                              ;
  reg   [IDX_WIDTH-1:0]           n_counter                                                   ;
  reg   [IDX_WIDTH-1:0]           n_counter_reg                                               ;
  // -- start_idx calculation
  reg   [INDEX_WIDTH-1:0]         start_idx         [0:NODE_INFO_SIZE-1]                      ;
  reg   [INDEX_WIDTH-1:0]         start_idx_reg     [0:NODE_INFO_SIZE-1]                      ;
  reg   [INDEX_WIDTH-1:0]         idx                                                         ;
  reg   [INDEX_WIDTH-1:0]         idx_reg                                                     ;
  reg   [INDEX_WIDTH-1:0]         sum                                                         ;
  reg   [INDEX_WIDTH-1:0]         sum_reg                                                     ;
  // -- BRAM
  reg   [BRAM_ADDR_WIDTH-1:0]     cv_addr_reg                                                 ;
  reg   [BRAM_ADDR_WIDTH-1:0]     n_addr_reg                                                  ;
  // -- output
  reg                             h_ready_reg                                                 ;
  reg   [COL_IDX_WIDTH-1:0]       row_col_idx_reg   [0:NUM_OF_ROWS-1] [0:GCSR_SIZE-1]         ;
  reg   [VALUE_WIDTH-1:0]         row_value_reg     [0:NUM_OF_ROWS-1] [0:GCSR_SIZE-1]         ;
  reg   [NODE_INFO_WIDTH-1:0]     row_info_reg      [0:NUM_OF_ROWS-1]                         ;
  //* =======================================


  //* ========= internal declaration ========
  genvar i;
  integer x;
  genvar row_counter, col_counter;
  //* =======================================


  //* ========== output assignment ==========
  assign h_ready_o              = h_ready_reg;
  assign H_col_idx_BRAM_addr    = cv_addr_reg;
  assign H_value_BRAM_addr      = cv_addr_reg;
  assign H_node_info_BRAM_addr  = n_addr_reg;
  assign row_col_idx_o          = row_col_idx_reg;
  assign row_value_o            = row_value_reg;
  assign row_info_o             = row_info_reg;
  //* =======================================


  //* =========== Get H from BRAM ===========
  // -- addr
  assign cv_addr = cv_addr_reg + 1;
  assign n_addr  = n_addr_reg + 1;

  always @(posedge clk) begin
    if (!rst_n) begin
      cv_addr_reg <= 0;
      n_addr_reg  <= 0;
    end else begin
      cv_addr_reg <= cv_addr;
      n_addr_reg  <= n_addr;
    end
  end

  // -- col_idx & value counter
  always @(*) begin
    cv_counter = cv_counter_reg;
    for (x = 0; x < COL_INDEX_SIZE; x = x + 1) begin
      col_idx[x]  = col_idx_reg[x];
      value[x]    = value_reg[x];
    end

    if (cv_counter_reg < cv_length) begin
      col_idx[cv_counter_reg] = H_col_idx_BRAM_dout;
      value[cv_counter_reg]   = H_value_BRAM_dout;
      cv_counter              = cv_counter_reg + 1;
    end
  end

  // -- node_info counter
  always @(*) begin
    n_counter = n_counter_reg;
    for (x = 0; x < NODE_INFO_SIZE; x = x + 1) begin
      node_info[x] = node_info_reg[x];
    end

    if (n_counter_reg < node_info_length) begin
      node_info[n_counter_reg]  = H_node_info_BRAM_dout;
      n_counter                 = n_counter_reg + 1;
    end
  end

  generate
    for (i = 0; i < COL_INDEX_SIZE; i = i + 1) begin
      always @(posedge clk) begin
        if (!rst_n) begin
          col_idx_reg[i] <= 0;
          value_reg[i]   <= 0;
        end else begin
          col_idx_reg[i] <= col_idx[i];
          value_reg[i]   <= value_reg[i];
        end
      end
    end
    for (i = 0; i < NODE_INFO_SIZE; i = i + 1) begin
      always @(posedge clk) begin
        if (!rst_n) begin
          node_info_reg[i] <= 0;
        end else begin
          node_info_reg[i] <= node_info[i];
        end
      end
    end
  endgenerate


  always @(posedge clk) begin
    if (!rst_n) begin
      cv_counter_reg  <= 0;
      n_counter_reg   <= 0;
    end else begin
      cv_counter_reg  <= cv_counter;
      n_counter_reg   <= n_counter;
    end
  end
  //* =======================================


  //* ============= [start_idx] =============
  always @(*) begin
    for (x = 0; x < COL_INDEX_SIZE; x = x + 1) begin
      start_idx[x] = start_idx_reg[x];
    end
    sum = sum_reg;
    idx = idx_reg;

    if (idx_reg < NODE_INFO_SIZE && n_counter_reg > 0) begin
      start_idx[idx_reg]  = sum_reg;
      sum                 = sum_reg + node_info_reg[idx_reg][NODE_INFO_WIDTH-1:1];
      idx                 = idx_reg + 1;
    end
  end

  generate
    for (i = 0; i < NODE_INFO_SIZE; i = i + 1) begin
      always @(posedge clk) begin
        if (!rst_n) begin
          start_idx_reg[i]  <= 0;
        end else begin
          start_idx_reg[i]  <= start_idx[i];
        end
      end
    end
  endgenerate

  always @(posedge clk) begin
    if (!rst_n) begin
      sum_reg <= 0;
      idx_reg <= 0;
    end else begin
      sum_reg <= sum;
      idx_reg <= idx;
    end
  end
  //* =======================================


  //* =============== h_ready ===============
  assign h_ready = (cv_counter_reg == cv_length) ? 1'b1 : h_ready_reg;

  always @(posedge clk) begin
    if (!rst_n) begin
      h_ready_reg <= 0;
    end else begin
      h_ready_reg <= h_ready;
    end
  end
  //* =======================================


  //* ============ extract rows =============
  generate
    for (row_counter = 0; row_counter < NUM_OF_ROWS; row_counter = row_counter + 1) begin
      for (col_counter = 0; col_counter < NUM_OF_COLS; col_counter = col_counter + 1) begin
        assign row_col_idx[row_counter][col_counter]  = (col_counter < node_info_reg[row_counter][(NODE_INFO_WIDTH-1):1])
                                                      ? col_idx_reg[start_idx_reg[row_counter] + col_counter]
                                                      : 0;
        assign row_value[row_counter][col_counter]    = (col_counter < node_info_reg[row_counter][(NODE_INFO_WIDTH-1):1])
                                                      ? value_reg[start_idx_reg[row_counter] + col_counter]
                                                      : 0;
      end
      assign row_info[row_counter] = node_info_reg[row_counter];
    end
  endgenerate

  generate
    for (row_counter = 0; row_counter < NUM_OF_ROWS; row_counter = row_counter + 1) begin
      for (col_counter = 0; col_counter < NUM_OF_COLS; col_counter = col_counter + 1) begin
        always @(posedge clk) begin
          row_col_idx_reg[row_counter][col_counter] <= row_col_idx[row_counter][col_counter];
          row_value_reg[row_counter][col_counter]   <= row_value[row_counter][col_counter];
        end
      end
    end
  endgenerate
  //* =======================================

endmodule
