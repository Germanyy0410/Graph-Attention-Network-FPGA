module a_loader #(
  parameter DATA_WIDTH        = 8,
  parameter A_ADDR_W          = 32,
  parameter A_DEPTH           = 32,
  parameter INDEX_WIDTH       = $clog2(A_DEPTH)
)(
  input clk,
  input rst_n,

  input                             a_valid_i                     ,
  output                            a_ready_o                     ,

  input   [DATA_WIDTH-1:0]          a_BRAM_dout                   ,
  output                            a_BRAM_enb                    ,
  output  [A_ADDR_W-1:0]            a_BRAM_addrb                  ,

  output  [DATA_WIDTH-1:0]          a_o             [0:A_DEPTH-1]
);
  //* ========== wire declaration ===========
  wire  [A_ADDR_W-1:0]          a_addr                      ;
  wire  [DATA_WIDTH-1:0]        a           [0:A_DEPTH-1]   ;
  wire                          rd_en                       ;
  wire  [INDEX_WIDTH-1:0]       idx                         ;
  //* =======================================


  //* =========== reg declaration ===========
  reg   [A_ADDR_W-1:0]          a_addr_reg                  ;
  reg   [DATA_WIDTH-1:0]        a_reg       [0:A_DEPTH-1]   ;
  reg                           rd_en_q1                    ;
  reg                           rd_en_q2                    ;
  reg   [INDEX_WIDTH-1:0]       idx_reg                     ;
  //* =======================================

  genvar i;

  //* ========= internal assignment =========
  assign rd_en = (a_valid_i && (a_addr_reg < A_DEPTH + 1));
  //* =======================================


  //* ========== output assignment ==========
  assign a_BRAM_addrb = a_addr_reg;
  assign a_BRAM_enb   = rd_en ? 1'b1 : 1'b0;
  assign a_ready_o    = (a_addr_reg == A_DEPTH + 1) ? 1'b1 : 1'b0;
  generate
    for (i = 0; i < 32; i = i + 1) begin
      assign a_o[i] = a_reg[i];
    end
  endgenerate
  //* =======================================


  //* ================ addr =================
  assign a_addr = (a_valid_i && a_addr_reg < A_DEPTH - 1) ? (a_addr_reg + 1) : a_addr_reg;

  always @(posedge clk) begin
    if (!rst_n) begin
      a_addr_reg <= 0;
    end else begin
      a_addr_reg <= a_addr;
    end
  end
  //* =======================================


  always @(posedge clk) begin
    rd_en_q1 <= rd_en;
    rd_en_q2 <= rd_en_q1;
  end


  //* ================= a ===================

  assign idx = (rd_en_q1 && (idx_reg < A_DEPTH - 1)) ? (idx_reg + 1) : idx_reg;

  generate
    for (i = 0; i < A_DEPTH; i = i + 1) begin
      assign a[i] = (i == idx_reg) ? a_BRAM_dout : a_reg[i];
    end
  endgenerate

  always @(posedge clk) begin
    if (!rst_n) begin
      idx_reg <= 0;
    end else begin
      idx_reg <= idx;
    end
  end

  generate
    for (i = 0; i < A_DEPTH; i = i + 1) begin
      always @(posedge clk) begin
        if (!rst_n) begin
          a_reg[i] <= 0;
        end else begin
          a_reg[i] <= a[i];
        end
      end
    end
  endgenerate
  //* =======================================
endmodule