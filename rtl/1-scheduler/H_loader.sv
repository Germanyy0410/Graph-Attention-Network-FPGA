module H_loader #(
  //* ========== parameter ===========
  parameter DATA_WIDTH        = 8,
  parameter NUM_OF_COLS       = 1433,
  parameter NUM_OF_ROWS       = 200,
  parameter COL_INDEX_SIZE    = 8,
  parameter VALUE_SIZE        = 8,
  parameter NODE_INFO_SIZE    = NUM_OF_ROWS,

  //* ========= localparams ==========
  parameter INDEX_WIDTH       = $clog2(COL_INDEX_SIZE),
  // -- inputs
  // -- -- col_idx
  parameter COL_IDX_WIDTH     = $clog2(NUM_OF_COLS),
  // -- -- value
  parameter VALUE_WIDTH       = DATA_WIDTH,
  // -- -- node_info = [row_len, flag]
  parameter ROW_LEN_WIDTH     = $clog2(NUM_OF_COLS),
  parameter NODE_INFO_WIDTH   = ROW_LEN_WIDTH + 1,
  // -- outputs
  parameter FF_DATA_WIDTH     = COL_IDX_WIDTH + VALUE_WIDTH
)(
  input   clk,
  input   rst_n,

  input                           h_valid_i                                             ,
  output                          h_ready_o                                             ,

  input   [COL_IDX_WIDTH-1:0]     col_idx_i       [0:COL_INDEX_SIZE-1]                  ,
  input   [VALUE_WIDTH-1:0]       value_i         [0:VALUE_SIZE-1]                      ,
  input   [NODE_INFO_WIDTH-1:0]   node_info_i     [0:NODE_INFO_SIZE-1]                  ,

  output [FF_DATA_WIDTH-1:0]      H_data_i        [0:NUM_OF_ROWS-1]                     ,
  output [NUM_OF_ROWS-1:0]        H_wr_valid
);
  //* ========== wire declaration ===========
  // -- input
  wire                            h_valid                                                 ;
  wire  [COL_IDX_WIDTH-1:0]       col_idx           [0:COL_INDEX_SIZE-1]                  ;
  wire  [VALUE_WIDTH-1:0]         value             [0:VALUE_SIZE-1]                      ;
  wire  [NODE_INFO_WIDTH-1:0]     node_info         [0:NODE_INFO_SIZE-1]                  ;
  // -- output
  wire                            h_ready                                                 ;
  // -- counter for FIFO
  wire  [ROW_LEN_WIDTH-1:0]       counter           [0:NUM_OF_ROWS-1]                     ;

  //* =========== reg declaration ===========
  reg                             h_ready_reg                                             ;
  // -- start_idx calculation
  reg   [INDEX_WIDTH-1:0]         start_idx         [0:NODE_INFO_SIZE-1]                  ;
  reg   [INDEX_WIDTH-1:0]         start_idx_reg     [0:NODE_INFO_SIZE-1]                  ;
  reg   [INDEX_WIDTH-1:0]         idx                                                     ;
  reg   [INDEX_WIDTH-1:0]         idx_reg                                                 ;
  reg   [INDEX_WIDTH-1:0]         sum                                                     ;
  reg   [INDEX_WIDTH-1:0]         sum_reg                                                 ;
  // -- counter for FIFO
  reg   [ROW_LEN_WIDTH-1:0]       counter_reg       [0:NUM_OF_ROWS-1]                     ;

  //* ========= internal declaration ========
  genvar i;
  genvar a, b, c;
  genvar row_counter, col_counter;
  integer x;

  //* ========== output assignment ==========
  assign h_ready_o = h_ready_reg;

  //* ============= [start_idx] =============
  always @(*) begin
    for (x = 0; x < COL_INDEX_SIZE; x = x + 1) begin
      start_idx[x] = start_idx_reg[x];
    end
    sum = sum_reg;
    idx = idx_reg;

    if (idx_reg < NODE_INFO_SIZE) begin
      start_idx[idx_reg]  = sum_reg;
      sum                 = sum_reg + node_info_i[idx_reg][NODE_INFO_WIDTH-1:1];
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

  //* ============ h_ready ============
  assign h_ready = (idx_reg >= NODE_INFO_SIZE - 1);

  always @(posedge clk) begin
    if (!rst_n) begin
      h_ready_reg <= 0;
    end else begin
      h_ready_reg <= h_ready;
    end
  end

  //* ============ H_fifo ============
  generate
    for (i = 0; i < NUM_OF_ROWS; i = i + 1) begin
      always @(posedge clk) begin
        if (!rst_n) begin
          counter_reg[i] <= 0;
        end else begin
          counter_reg[i] <= counter[i];
        end
      end
    end
  endgenerate

  generate
    for (i = 0; i < NUM_OF_ROWS; i = i + 1) begin
      assign H_data_i[i]      = { col_idx_i[start_idx[i] + counter_reg[i]], value_i[start_idx[i] + counter_reg[i]] };
      assign H_wr_valid[i]    = (counter_reg[i] < node_info_i[i][NODE_INFO_WIDTH-1:1]);
      assign counter[i]       = (counter_reg[i] < node_info_i[i][NODE_INFO_WIDTH-1:1]) ? (counter_reg[i] + 1) : counter_reg[i];
    end
  endgenerate
endmodule

module H_loader_BRAM #(
  //* ========== parameter ===========
  parameter DATA_WIDTH        = 8,
  parameter NUM_OF_COLS       = 1433,
  parameter NUM_OF_ROWS       = 200,
  parameter COL_INDEX_SIZE    = 8,
  parameter VALUE_SIZE        = 8,
  parameter NODE_INFO_SIZE    = NUM_OF_ROWS,

  //* ========= localparams ==========
  parameter INDEX_WIDTH       = $clog2(COL_INDEX_SIZE),
  // -- -- col_idx
  parameter COL_IDX_WIDTH     = $clog2(NUM_OF_COLS),
  // -- -- value
  parameter VALUE_WIDTH       = DATA_WIDTH,
  // -- -- node_info = [row_len, flag]
  parameter ROW_LEN_WIDTH     = $clog2(NUM_OF_COLS),
  parameter NODE_INFO_WIDTH   = ROW_LEN_WIDTH + 1,
  // -- inputs
  parameter H_BRAM_DATA_WIDTH = COL_IDX_WIDTH + VALUE_WIDTH + NODE_INFO_WIDTH + 1,
  parameter H_BRAM_ADDR_WIDTH = 32,
  // -- outputs
  parameter FF_DATA_WIDTH     = COL_IDX_WIDTH + VALUE_WIDTH
)(
  input   clk,
  input   rst_n,
  // -- H BRAM
  input   [H_BRAM_DATA_WIDTH-1:0]   H_BRAM_dout                       ,
  output                            H_BRAM_en                         ,
  output  [H_BRAM_ADDR_WIDTH-1:0]   H_BRAM_addr                       ,

  output                            h_ready_o                         ,

  output [FF_DATA_WIDTH-1:0]        H_data_i      [0:NUM_OF_ROWS-1]   ,
  output [NUM_OF_ROWS-1:0]          H_wr_valid
);
  //* ========== wire declaration ===========
  // -- input
  wire                            h_valid                                                 ;
  wire  [COL_IDX_WIDTH-1:0]       col_idx           [0:COL_INDEX_SIZE-1]                  ;
  wire  [VALUE_WIDTH-1:0]         value             [0:VALUE_SIZE-1]                      ;
  wire  [NODE_INFO_WIDTH-1:0]     node_info         [0:NODE_INFO_SIZE-1]                  ;
  // -- output
  wire                            h_ready                                                 ;
  // -- counter for FIFO
  wire  [ROW_LEN_WIDTH-1:0]       counter           [0:NUM_OF_ROWS-1]                     ;

  //* =========== reg declaration ===========
  reg                             h_ready_reg                                             ;
  // -- start_idx calculation
  reg   [INDEX_WIDTH-1:0]         start_idx         [0:NODE_INFO_SIZE-1]                  ;
  reg   [INDEX_WIDTH-1:0]         start_idx_reg     [0:NODE_INFO_SIZE-1]                  ;
  reg   [INDEX_WIDTH-1:0]         idx                                                     ;
  reg   [INDEX_WIDTH-1:0]         idx_reg                                                 ;
  reg   [INDEX_WIDTH-1:0]         sum                                                     ;
  reg   [INDEX_WIDTH-1:0]         sum_reg                                                 ;
  // -- counter for FIFO
  reg   [ROW_LEN_WIDTH-1:0]       counter_reg       [0:NUM_OF_ROWS-1]                     ;

  //* ========= internal declaration ========
  genvar i;
  genvar a, b, c;
  genvar row_counter, col_counter;
  integer x;

  //* ========== output assignment ==========
  assign h_ready_o = h_ready_reg;

  //* ============= [start_idx] =============
  always @(*) begin
    for (x = 0; x < COL_INDEX_SIZE; x = x + 1) begin
      start_idx[x] = start_idx_reg[x];
    end
    sum = sum_reg;
    idx = idx_reg;

    if (idx_reg < NODE_INFO_SIZE) begin
      start_idx[idx_reg]  = sum_reg;
      sum                 = sum_reg + node_info_i[idx_reg][NODE_INFO_WIDTH-1:1];
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

  //* ============ h_ready ============
  assign h_ready = (idx_reg >= NODE_INFO_SIZE - 1);

  always @(posedge clk) begin
    if (!rst_n) begin
      h_ready_reg <= 0;
    end else begin
      h_ready_reg <= h_ready;
    end
  end

  //* ============ H_fifo ============
  generate
    for (i = 0; i < NUM_OF_ROWS; i = i + 1) begin
      always @(posedge clk) begin
        if (!rst_n) begin
          counter_reg[i] <= 0;
        end else begin
          counter_reg[i] <= counter[i];
        end
      end
    end
  endgenerate

  generate
    for (i = 0; i < NUM_OF_ROWS; i = i + 1) begin
      assign H_data_i[i]      = { col_idx_i[start_idx[i] + counter_reg[i]], value_i[start_idx[i] + counter_reg[i]] };
      assign H_wr_valid[i]    = (counter_reg[i] < node_info_i[i][NODE_INFO_WIDTH-1:1]);
      assign counter[i]       = (counter_reg[i] < node_info_i[i][NODE_INFO_WIDTH-1:1]) ? (counter_reg[i] + 1) : counter_reg[i];
    end
  endgenerate
endmodule
