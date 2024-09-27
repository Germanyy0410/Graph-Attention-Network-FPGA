module scheduler #(
  //* ========== parameter ===========
  parameter   DATA_WIDTH      = 8,
  parameter   NUM_OF_COLS     = 5,
  parameter   NUM_OF_ROWS     = 5,
  parameter   COL_INDEX_SIZE  = 8,
  parameter   VALUE_SIZE      = 8,
  parameter   NODE_INFO_SIZE  = 5,

  //* ========= localparams ==========
  // -- inputs
  // -- -- col_idx
  localparam  COL_IDX_WIDTH           = $clog2(NUM_OF_COLS),
  localparam  COL_IDX_WIDTH_FLAT      = COL_IDX_WIDTH * COL_INDEX_SIZE,
  // -- -- value
  localparam VALUE_WIDTH              = DATA_WIDTH,
  localparam VALUE_WIDTH_FLAT         = DATA_WIDTH * VALUE_SIZE,
  // -- -- node_info = [idx, row_len, flag]
  localparam  INDEX_WIDTH             = $clog2(COL_INDEX_SIZE),
  localparam  ROW_LEN_WIDTH           = $clog2(NUM_OF_COLS),
  localparam  NODE_INFO_WIDTH         = INDEX_WIDTH + ROW_LEN_WIDTH + 1,
  localparam  NODE_INFO_WIDTH_FLAT    = NODE_INFO_WIDTH * NODE_INFO_SIZE,
  // -- outputs
  // -- -- col_idx
  localparam  ROW_COL_IDX_WIDTH_FLAT  = COL_IDX_WIDTH * NUM_OF_COLS * NUM_OF_ROWS,
  // -- -- value
  localparam  ROW_VALUE_WIDTH_FLAT    = DATA_WIDTH * NUM_OF_COLS * NUM_OF_ROWS,
  // -- -- node_info of each row = [row_len, flag]
  localparam  ROW_INFO_WIDTH          = ROW_LEN_WIDTH + 1,
  localparam  ROW_INFO_WIDTH_FLAT     = ROW_INFO_WIDTH * NUM_OF_ROWS
)(
  input   clk,
  input   rst_n,

  input                                 sched_valid_i   ,
  input   [COL_IDX_WIDTH_FLAT-1:0]      col_idx_i       ,
  input   [VALUE_WIDTH_FLAT-1:0]        value_i         ,
  input   [NODE_INFO_WIDTH_FLAT-1:0]    node_info_i     ,

  output                                sched_ready_o   ,
  output  [ROW_COL_IDX_WIDTH_FLAT-1:0]  row_col_idx_o   ,
  output  [ROW_VALUE_WIDTH_FLAT-1:0]    row_value_o     ,
  output  [ROW_INFO_WIDTH_FLAT-1:0]     row_info_o
);
  //* ========== wire declaration ===========
  // -- input
  wire                                  sched_valid                                             ;
  wire  [COL_IDX_WIDTH-1:0]             col_idx           [0:COL_INDEX_SIZE-1]                  ;
  wire  [VALUE_WIDTH-1:0]               value             [0:VALUE_SIZE-1]                      ;
  wire  [NODE_INFO_WIDTH-1:0]           node_info         [0:NODE_INFO_SIZE-1]                  ;
  // -- output
  wire                                  sched_ready                                             ;
  wire  [COL_IDX_WIDTH-1:0]             row_col_idx       [0:NUM_OF_ROWS-1] [0:NUM_OF_COLS-1]   ;
  wire  [VALUE_WIDTH-1:0]               row_value         [0:NUM_OF_ROWS-1] [0:NUM_OF_COLS-1]   ;
  wire  [ROW_INFO_WIDTH-1:0]            row_info          [0:NUM_OF_ROWS-1]                     ;

  //* =========== reg declaration ===========
  reg                                   sched_ready_reg                                         ;
  reg   [COL_IDX_WIDTH-1:0]             row_col_idx_reg   [0:NUM_OF_ROWS-1] [0:NUM_OF_COLS-1]   ;
  reg   [VALUE_WIDTH-1:0]               row_value_reg     [0:NUM_OF_ROWS-1] [0:NUM_OF_COLS-1]   ;
  reg   [ROW_INFO_WIDTH-1:0]            row_info_reg      [0:NUM_OF_ROWS-1]                     ;

  //* ========= internal declaration ========
  genvar i;
  genvar a, b, c;
  genvar row_counter, col_counter;

  //* ========== input assignment ===========
  // -- deflatten inputs to 2d array
  generate
    // -- col_idx
    for (i = 0; i < COL_INDEX_SIZE; i = i + 1) begin
      assign col_idx[COL_INDEX_SIZE-1-i] = col_idx_i[COL_IDX_WIDTH*(i+1)-1:COL_IDX_WIDTH*i];
    end
    // -- value
    for (i = 0; i < VALUE_SIZE; i = i + 1) begin
      assign value[VALUE_SIZE-1-i] = value_i[VALUE_WIDTH*(i+1)-1:VALUE_WIDTH*i];
    end
    // -- node_info
    for (i = 0; i < NODE_INFO_SIZE; i = i + 1) begin
      assign node_info[NODE_INFO_SIZE-1-i] = node_info_i[NODE_INFO_WIDTH*(i+1)-1:NODE_INFO_WIDTH*i];
    end
  endgenerate

  //* ========== output assignment =========
  assign sched_ready_o = sched_ready;
  // -- flatten 3d array to 1d array outputs
  generate
    // -- row_col_idx
    for (a = 0; a < NUM_OF_ROWS; a = a + 1) begin
      for (b = 0; b < NUM_OF_COLS; b = b + 1) begin
        for (c = 0; c < COL_IDX_WIDTH; c = c + 1) begin
          assign row_col_idx_o[a*NUM_OF_COLS*COL_IDX_WIDTH+b*COL_IDX_WIDTH+c] = row_col_idx[NUM_OF_ROWS-1-a][NUM_OF_COLS-1-b][COL_IDX_WIDTH-1-c];
        end
      end
    end
    // -- row_value
    for (a = 0; a < NUM_OF_ROWS; a = a + 1) begin
      for (b = 0; b < NUM_OF_COLS; b = b + 1) begin
        for (c = 0; c < VALUE_WIDTH; c = c + 1) begin
          assign row_value_o[a*NUM_OF_COLS*VALUE_WIDTH+b*VALUE_WIDTH+c] = row_value[NUM_OF_ROWS-1-a][NUM_OF_COLS-1-b][VALUE_WIDTH-1-c];
        end
      end
    end
    // -- row_info
    for (a = 0; a < NUM_OF_ROWS; a = a + 1) begin
      for (b = 0; b < ROW_INFO_WIDTH; b = b + 1) begin
        assign row_info_o[a*ROW_INFO_WIDTH+b] = row_info[NUM_OF_ROWS-1-a][ROW_INFO_WIDTH-1-b];
      end
    end
  endgenerate

  //* =========== extract rows =============
  generate
    for (row_counter = 0; row_counter < NUM_OF_ROWS; row_counter = row_counter + 1) begin
      for (col_counter = 0; col_counter < NUM_OF_COLS; col_counter = col_counter + 1) begin
        assign row_col_idx[row_counter][col_counter]  = (col_counter < node_info[row_counter][(NODE_INFO_WIDTH-INDEX_WIDTH-1):1])
                                                      ? col_counter[node_info[row_counter][(NODE_INFO_WIDTH-1):(NODE_INFO_WIDTH-INDEX_WIDTH)] + col_counter]
                                                      : 0;
        assign row_value[row_counter][col_counter]    = (col_counter < node_info[row_counter][(NODE_INFO_WIDTH-INDEX_WIDTH-1):1])
                                                      ? value[node_info[row_counter][(NODE_INFO_WIDTH-1):(NODE_INFO_WIDTH-INDEX_WIDTH)] + col_counter]
                                                      : 0;
      end
      assign row_info[row_counter] = node_info[row_counter][(NODE_INFO_WIDTH-INDEX_WIDTH-1):0];
    end
  endgenerate

  //* ============ sched_ready ============
  assign sched_ready = sched_valid;
  always @(posedge clk) begin
    if (!rst_n) begin
      sched_ready_reg <= 0;
    end else begin
      sched_ready_reg <= sched_ready;
    end
  end
endmodule
