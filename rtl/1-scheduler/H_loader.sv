module H_loader #(
  //* ========== parameter ===========
  parameter DATA_WIDTH        = 8,
  parameter NUM_OF_COLS       = 5,
  parameter NUM_OF_ROWS       = 5,
  parameter COL_INDEX_SIZE    = 8,
  parameter VALUE_SIZE        = 8,
  parameter NODE_INFO_SIZE    = 5,

  //* ========= localparams ==========
  // -- inputs
  // -- -- col_idx
  parameter COL_IDX_WIDTH     = $clog2(NUM_OF_COLS),
  // -- -- value
  parameter VALUE_WIDTH       = DATA_WIDTH,
  // -- -- node_info = [idx, row_len, flag]
  parameter INDEX_WIDTH       = $clog2(COL_INDEX_SIZE),
  parameter ROW_LEN_WIDTH     = $clog2(NUM_OF_COLS),
  parameter NODE_INFO_WIDTH   = INDEX_WIDTH + ROW_LEN_WIDTH + 1,
  // -- outputs
  // -- -- row_info = [row_len, flag]
  parameter ROW_INFO_WIDTH    = ROW_LEN_WIDTH + 1
)(
  input   clk,
  input   rst_n,

  input                           sched_valid_i                                         ,
  input   [COL_IDX_WIDTH-1:0]     col_idx_i       [0:COL_INDEX_SIZE-1]                  ,
  input   [VALUE_WIDTH-1:0]       value_i         [0:VALUE_SIZE-1]                      ,
  input   [NODE_INFO_WIDTH-1:0]   node_info_i     [0:NODE_INFO_SIZE-1]                  ,

  output                          sched_ready_o                                         ,
  output  [COL_IDX_WIDTH-1:0]     row_col_idx_o   [0:NUM_OF_ROWS-1] [0:NUM_OF_COLS-1]   ,
  output  [VALUE_WIDTH-1:0]       row_value_o     [0:NUM_OF_ROWS-1] [0:NUM_OF_COLS-1]   ,
  output  [ROW_INFO_WIDTH-1:0]    row_info_o      [0:NUM_OF_ROWS-1]
);
  //* ========== wire declaration ===========
  // -- input
  wire                            sched_valid                                             ;
  wire  [COL_IDX_WIDTH-1:0]       col_idx           [0:COL_INDEX_SIZE-1]                  ;
  wire  [VALUE_WIDTH-1:0]         value             [0:VALUE_SIZE-1]                      ;
  wire  [NODE_INFO_WIDTH-1:0]     node_info         [0:NODE_INFO_SIZE-1]                  ;
  // -- output
  wire                            sched_ready                                             ;
  wire  [COL_IDX_WIDTH-1:0]       row_col_idx       [0:NUM_OF_ROWS-1] [0:NUM_OF_COLS-1]   ;
  wire  [VALUE_WIDTH-1:0]         row_value         [0:NUM_OF_ROWS-1] [0:NUM_OF_COLS-1]   ;
  wire  [ROW_INFO_WIDTH-1:0]      row_info          [0:NUM_OF_ROWS-1]                     ;

  //* =========== reg declaration ===========
  reg                             sched_ready_reg                                         ;

  //* ========= internal declaration ========
  genvar i;
  genvar a, b, c;
  genvar row_counter, col_counter;

  //* ========== input assignment ===========
  assign col_idx   = col_idx_i;
  assign value     = value_i;
  assign node_info = node_info_i;

  //* ========== output assignment =========
  assign sched_ready_o = sched_ready_reg;

  always @(posedge clk) begin
    col_idx_o   <= col_idx;
    value_o     <= value;
    node_info_o <= node_info;
  end

  //* =========== extract rows =============
  generate
    for (row_counter = 0; row_counter < NUM_OF_ROWS; row_counter = row_counter + 1) begin
      for (col_counter = 0; col_counter < NUM_OF_COLS; col_counter = col_counter + 1) begin
        assign row_col_idx[row_counter][col_counter]  = (col_counter < node_info[row_counter][(NODE_INFO_WIDTH-INDEX_WIDTH-1):1])
                                                      ? col_idx[node_info[row_counter][(NODE_INFO_WIDTH-1):(NODE_INFO_WIDTH-INDEX_WIDTH)] + col_counter]
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
