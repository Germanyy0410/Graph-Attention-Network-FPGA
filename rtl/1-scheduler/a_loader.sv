module a_loader #(
  parameter DATA_WIDTH        = 8,
  parameter BRAM_ADDR_WIDTH   = 32,
  parameter A_SIZE            = 32
)(
  input clk,
  input rst_n,

  input                             a_valid_i                     ,
  output                            a_ready_o                     ,

  input   [DATA_WIDTH-1:0]          a_BRAM_dout                   ,
  output                            a_BRAM_enb                    ,
  output  [BRAM_ADDR_WIDTH-1:0]     a_BRAM_addrb                  ,

  output  [DATA_WIDTH-1:0]          a_o             [0:A_SIZE-1]
);
  //* ========== wire declaration ===========
  wire  [BRAM_ADDR_WIDTH-1:0]   a_addr                      ;
  wire  [DATA_WIDTH-1:0]        a           [0:A_SIZE-1]    ;
  wire                          rd_en                       ;
  //* =======================================


  //* =========== reg declaration ===========
  reg   [BRAM_ADDR_WIDTH-1:0]   a_addr_reg                  ;
  reg   [DATA_WIDTH-1:0]        a_reg       [0:A_SIZE-1]    ;
  reg                           rd_en_q1                    ;
  reg                           rd_en_q2                    ;
  //* =======================================

  genvar i;

  //* ========= internal assignment =========
  assign rd_en = (a_valid_i && (a_addr_reg < A_SIZE + 1));
  //* =======================================


  //* ========== output assignment ==========
  assign a_BRAM_addrb = a_addr_reg;
  assign a_BRAM_enb   = rd_en ? 1'b1 : 1'b0;
  assign a_ready_o    = (a_addr_reg == A_SIZE + 2) ? 1'b1 : 1'b0;
  generate
    for (i = 0; i < 31; i = i + 1) begin
      assign a_o[i] = a_reg[i];
    end
  endgenerate
  //* =======================================


  //* ================ addr =================
  assign a_addr = (a_valid_i) ? (a_addr_reg + 1) : a_addr_reg;

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
  generate
    for (i = 0; i < A_SIZE; i = i + 1) begin
      assign a[i] = (rd_en_q2 && (i == a_addr_reg - 2)) ? a_BRAM_dout : a_reg[i];
    end
  endgenerate

  generate
    for (i = 0; i < A_SIZE; i = i + 1) begin
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